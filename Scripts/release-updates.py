#!/usr/bin/env python3
"""Prepare universal notarized updates; publish only on an explicitly approved main run."""

import argparse, base64, hashlib, json, os, plistlib, re, secrets, subprocess, sys, tempfile
from pathlib import Path
from update_release import sign_archive, verify_update, publish_appcast

ROOT = Path(__file__).resolve().parents[1]
CONFIG = json.loads((ROOT / "Scripts/update-config.json").read_text())
REPOSITORY = CONFIG["repository"]


class ReleaseError(Exception):
    pass


def run(*args):
    result = subprocess.run(
        list(map(str, args)), cwd=ROOT, capture_output=True, text=True
    )
    if result.returncode:
        raise ReleaseError(
            Path(str(args[0])).name + " failed; private output was suppressed"
        )
    return result.stdout.strip()


def candidate(version, build, checkout, main):
    if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version):
        raise ReleaseError("A stable semantic version is required")
    if not re.fullmatch(r"[1-9][0-9]*", str(build)):
        raise ReleaseError("A positive build number is required")
    if not re.fullmatch(r"[a-f0-9]{40}", checkout) or checkout != main:
        raise ReleaseError("Only the exact current main commit can prepare a release")


def verify_artifacts(manifest, info, archive):
    app = plistlib.loads(Path(info).read_bytes())
    if (
        manifest["version"] != app["CFBundleShortVersionString"]
        or str(manifest["build"]) != str(app["CFBundleVersion"])
        or app["CFBundleIdentifier"] != CONFIG["bundle"]
    ):
        raise ReleaseError(
            "Release version/build/app identity disagrees with built app"
        )
    if (
        manifest.get("repository") != REPOSITORY
        or manifest.get("notarized") is not True
    ):
        raise ReleaseError("Only a notarized artifact for this repository can publish")
    expected = CONFIG["asset"] + "-" + manifest["version"] + "-universal.zip"
    if (
        archive.name != expected
        or manifest["sha256"] != hashlib.sha256(archive.read_bytes()).hexdigest()
    ):
        raise ReleaseError("Archive filename or checksum mismatch")
    verify_update(ROOT / "dist/release.json", archive, info)


def publish(manifest, archive, info):
    version = manifest["version"]
    tag = "v" + version
    candidate(
        version,
        manifest["build"],
        manifest["commit"],
        run("gh", "api", f"repos/{REPOSITORY}/commits/main", "--jq", ".sha"),
    )
    verify_artifacts(manifest, info, archive)
    existing = json.loads(run("gh", "api", f"repos/{REPOSITORY}/releases?per_page=100"))
    if any(r["tag_name"] == tag for r in existing):
        raise ReleaseError(
            "Release already exists; never overwrite a published or draft artifact"
        )
    refs = json.loads(
        run("gh", "api", f"repos/{REPOSITORY}/git/matching-refs/tags/{tag}")
    )
    if any(ref["ref"] == "refs/tags/" + tag for ref in refs):
        raise ReleaseError("Release tag already exists; never retarget source history")
    current = tuple(map(int, version.split(".")))
    for release in existing:
        if release.get("draft") or release.get("prerelease"):
            continue
        prior = release.get("tag_name", "")[1:]
        if (
            re.fullmatch(r"\d+\.\d+\.\d+", prior)
            and tuple(map(int, prior.split("."))) >= current
        ):
            raise ReleaseError("Stable release version must increase")
        marker = [a for a in release["assets"] if a["name"] == "release.json"]
        if marker:
            data = json.loads(
                run(
                    "gh",
                    "api",
                    f'repos/{REPOSITORY}/releases/assets/{marker[0]["id"]}',
                    "-H",
                    "Accept: application/octet-stream",
                )
            )
            if int(data.get("build", 0)) >= int(manifest["build"]):
                raise ReleaseError("Updater build number must increase")
    checksums = ROOT / "dist/SHA256SUMS"
    run(
        "gh",
        "release",
        "create",
        tag,
        "--repo",
        REPOSITORY,
        "--target",
        manifest["commit"],
        "--draft",
        "--title",
        CONFIG["asset"] + " " + version,
        "--notes",
        "Signed and notarized macOS update.",
        archive,
        checksums,
    )
    publish_appcast(
        run,
        REPOSITORY,
        tag,
        ROOT / "dist/release.json",
        archive,
        info,
        "Signed and notarized macOS update.",
        "15.6",
    )
    # Complete release marker is uploaded last, while the release is still a draft.
    run(
        "gh", "release", "upload", tag, ROOT / "dist/release.json", "--repo", REPOSITORY
    )
    with tempfile.TemporaryDirectory(prefix="verify-published-update-") as d:
        run("gh", "release", "download", tag, "--repo", REPOSITORY, "--dir", d)
        for path in [
            archive,
            checksums,
            ROOT / "dist/appcast.xml",
            ROOT / "dist/release.json",
        ]:
            if (Path(d) / path.name).read_bytes() != path.read_bytes():
                raise ReleaseError(
                    "Uploaded release bytes did not match verified artifacts"
                )
    candidate(
        version,
        manifest["build"],
        manifest["commit"],
        run("gh", "api", f"repos/{REPOSITORY}/commits/main", "--jq", ".sha"),
    )
    run("gh", "release", "edit", tag, "--repo", REPOSITORY, "--draft=false")


def prepare(version, build, publishing):
    if (
        os.environ.get("GITHUB_REF") != "refs/heads/main"
        or os.environ.get("GITHUB_REPOSITORY") != REPOSITORY
    ):
        raise ReleaseError("Run the approved main-branch release workflow")
    sha = run("git", "rev-parse", "HEAD")
    main = run("gh", "api", f"repos/{REPOSITORY}/commits/main", "--jq", ".sha")
    candidate(version, build, sha, main)
    if run("git", "status", "--porcelain", "--untracked-files=no"):
        raise ReleaseError("Release checkout has tracked changes")
    identity = os.environ.get("SIGNING_IDENTITY", "")
    if (
        not identity.startswith("Developer ID Application: ")
        or "(J37G76B69X)" not in identity
    ):
        raise ReleaseError("Expected Developer ID identity is required")
    required = [
        "DEVELOPER_ID_P12_BASE64",
        "DEVELOPER_ID_P12_PASSWORD",
        "NOTARY_PRIVATE_KEY",
        "NOTARY_KEY_ID",
        "NOTARY_ISSUER",
        "SPARKLE_PRIVATE_KEY",
    ]
    if not all(os.environ.get(k) for k in required):
        raise ReleaseError("Required release credentials are missing")
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="sign-update-") as d:
        temporary = Path(d)
        keychain = temporary / "release.keychain-db"
        p12 = temporary / "identity.p12"
        notary = temporary / "AuthKey.p8"
        p12.write_bytes(
            base64.b64decode(os.environ["DEVELOPER_ID_P12_BASE64"], validate=True)
        )
        notary.write_text(os.environ["NOTARY_PRIVATE_KEY"])
        p12.chmod(0o600)
        notary.chmod(0o600)
        password = secrets.token_urlsafe(32)
        try:
            run("security", "create-keychain", "-p", password, keychain)
            run("security", "unlock-keychain", "-p", password, keychain)
            run(
                "security",
                "import",
                p12,
                "-k",
                keychain,
                "-P",
                os.environ["DEVELOPER_ID_P12_PASSWORD"],
                "-T",
                "/usr/bin/codesign",
            )
            run(
                "security",
                "set-key-partition-list",
                "-S",
                "apple-tool:,apple:,codesign:",
                "-s",
                "-k",
                password,
                keychain,
            )
            derived = ROOT / ".release-build"
            print("Building universal direct application…", flush=True)
            run(
                "xcodebuild",
                "-project",
                CONFIG["project"] + ".xcodeproj",
                "-scheme",
                CONFIG["scheme"],
                "-configuration",
                "Release",
                "-destination",
                "generic/platform=macOS",
                "-derivedDataPath",
                derived,
                "ARCHS=arm64 x86_64",
                "ONLY_ACTIVE_ARCH=NO",
                "CODE_SIGNING_ALLOWED=NO",
                "ENABLE_HARDENED_RUNTIME=YES",
                "-skipPackagePluginValidation",
                "MARKETING_VERSION=" + version,
                "CURRENT_PROJECT_VERSION=" + str(build),
                "build",
            )
            app = derived / "Build/Products/Release" / (CONFIG["product"] + ".app")
            info = app / "Contents/Info.plist"
            built = plistlib.loads(info.read_bytes())
            if (
                built["CFBundleIdentifier"] != CONFIG["bundle"]
                or built["CFBundleShortVersionString"] != version
                or str(built["CFBundleVersion"]) != str(build)
            ):
                raise ReleaseError("Built app identity/version mismatch")
            for arch in ["arm64", "x86_64"]:
                run(
                    "lipo",
                    app / "Contents/MacOS" / built["CFBundleExecutable"],
                    "-verify_arch",
                    arch,
                )
            entitlements = plistlib.loads((ROOT / CONFIG["entitlements"]).read_bytes())

            def expanded(value):
                if isinstance(value, str):
                    return value.replace(
                        "$(PRODUCT_BUNDLE_IDENTIFIER)", CONFIG["bundle"]
                    )
                if isinstance(value, list):
                    return [expanded(v) for v in value]
                if isinstance(value, dict):
                    return {k: expanded(v) for k, v in value.items()}
                return value

            entitlement_file = temporary / "entitlements.plist"
            entitlement_file.write_bytes(plistlib.dumps(expanded(entitlements)))
            framework = app / "Contents/Frameworks/Sparkle.framework"
            for path in [
                framework / "Versions/B/XPCServices/Downloader.xpc",
                framework / "Versions/B/XPCServices/InstallerLauncher.xpc",
                framework / "Versions/B/Autoupdate",
                framework / "Versions/B/Updater.app",
                framework,
            ]:
                if not path.exists():
                    raise ReleaseError("Sparkle nested component missing")
                run(
                    "codesign",
                    "--force",
                    "--sign",
                    identity,
                    "--keychain",
                    keychain,
                    "--preserve-metadata=entitlements",
                    "--options",
                    "runtime",
                    "--timestamp",
                    path,
                )
            helpers = app / "Contents/Library/LaunchServices"
            if CONFIG.get("helper"):
                helper = helpers / CONFIG["helper"]
                if not helper.is_file():
                    raise ReleaseError("Privileged helper missing from release bundle")
                for arch in ["arm64", "x86_64"]:
                    run("lipo", helper, "-verify_arch", arch)
                run(
                    "codesign",
                    "--force",
                    "--sign",
                    identity,
                    "--keychain",
                    keychain,
                    "--options",
                    "runtime",
                    "--timestamp",
                    helper,
                )
                run(
                    "codesign",
                    "--verify",
                    "--strict",
                    "-R",
                    built["SMPrivilegedExecutables"][CONFIG["helper"]],
                    helper,
                )
            run(
                "codesign",
                "--force",
                "--sign",
                identity,
                "--keychain",
                keychain,
                "--entitlements",
                entitlement_file,
                "--options",
                "runtime",
                "--timestamp",
                app,
            )
            run("codesign", "--verify", "--deep", "--strict", app)
            if CONFIG.get("helper"):
                authorized = plistlib.loads(
                    (ROOT / "MacFanToolkitHelper/info.plist").read_bytes()
                )["SMAuthorizedClients"]
                if len(authorized) != 1:
                    raise ReleaseError(
                        "Privileged-helper client requirement must be unambiguous"
                    )
                run("codesign", "--verify", "--strict", "-R", authorized[0], app)
            notarization = temporary / "notarization.zip"
            run(
                "ditto",
                "-c",
                "-k",
                "--sequesterRsrc",
                "--keepParent",
                app,
                notarization,
            )
            print("Notarizing and stapling exact application…", flush=True)
            result = json.loads(
                run(
                    "xcrun",
                    "notarytool",
                    "submit",
                    notarization,
                    "--key",
                    notary,
                    "--key-id",
                    os.environ["NOTARY_KEY_ID"],
                    "--issuer",
                    os.environ["NOTARY_ISSUER"],
                    "--wait",
                    "--output-format",
                    "json",
                )
            )
            if result.get("status") != "Accepted":
                raise ReleaseError("Apple did not accept notarization")
            run("xcrun", "stapler", "staple", app)
            run("xcrun", "stapler", "validate", app)
            run("spctl", "--assess", "--type", "execute", app)
            archive = output / (CONFIG["asset"] + "-" + version + "-universal.zip")
            run("ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", app, archive)
            binaries = list(derived.glob("SourcePackages/artifacts/**/bin/sign_update"))
            if len(binaries) != 1:
                raise ReleaseError(
                    "Exactly one resolved Sparkle signing tool is required"
                )
            manifest = {
                "repository": REPOSITORY,
                "version": version,
                "build": str(build),
                "commit": sha,
                "notarized": True,
                "notarizationId": result.get("id"),
                "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
            }
            manifest["sparkle"] = sign_archive(archive, built, binaries[0])
            (output / "release.json").write_text(json.dumps(manifest, indent=2) + "\n")
            (output / "SHA256SUMS").write_text(
                manifest["sha256"] + "  " + archive.name + "\n"
            )
            verify_artifacts(manifest, info, archive)
            if publishing:
                publish(manifest, archive, info)
            print(
                "Verified signed update prepared"
                + (" and published" if publishing else "; publication disabled")
                + "."
            )
        finally:
            try:
                run("security", "delete-keychain", keychain)
            except ReleaseError:
                pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    try:
        prepare(args.version, args.build, args.publish)
    except Exception as error:
        print(
            (
                str(error)
                if isinstance(error, ReleaseError)
                else "Release preparation failed; secret-bearing tool output was suppressed"
            ),
            file=sys.stderr,
        )
        sys.exit(1)
