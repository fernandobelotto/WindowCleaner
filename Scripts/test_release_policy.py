import importlib.util, unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "release", Path(__file__).with_name("release-updates.py")
)
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class PolicyTests(unittest.TestCase):
    def test_only_exact_main_commit_may_release(self):
        release.candidate("1.2.3", "2", "a" * 40, "a" * 40)
        with self.assertRaises(release.ReleaseError):
            release.candidate("1.2.3", "2", "a" * 40, "b" * 40)

    def test_drafts_prereleases_and_bad_builds_cannot_be_stamped(self):
        for version in ["v1.2.3", "1.2.3-beta.1", "../1.2.3", "1.2", "01.2.3"]:
            with self.assertRaises(release.ReleaseError):
                release.candidate(version, "2", "a" * 40, "a" * 40)
        for build in ["0", "-1", "2.3", "2;echo bad"]:
            with self.assertRaises(release.ReleaseError):
                release.candidate("1.2.3", build, "a" * 40, "a" * 40)

    def test_metadata_only_wrong_app_and_tampered_bytes_never_publish(self):
        import tempfile, plistlib

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / (release.CONFIG["asset"] + "-1.2.3-universal.zip")
            archive.write_bytes(b"final bytes")
            info = root / "Info.plist"
            manifest = {
                "version": "1.2.3",
                "build": "2",
                "repository": release.REPOSITORY,
                "notarized": True,
                "sha256": "0" * 64,
            }
            info.write_bytes(
                plistlib.dumps(
                    {
                        "CFBundleShortVersionString": "1.2.3",
                        "CFBundleVersion": "2",
                        "CFBundleIdentifier": "wrong.app",
                    }
                )
            )
            with self.assertRaises(release.ReleaseError):
                release.verify_artifacts(manifest, info, archive)
            info.write_bytes(
                plistlib.dumps(
                    {
                        "CFBundleShortVersionString": "1.2.3",
                        "CFBundleVersion": "2",
                        "CFBundleIdentifier": release.CONFIG["bundle"],
                    }
                )
            )
            with self.assertRaises(release.ReleaseError):
                release.verify_artifacts(manifest, info, archive)
            manifest["notarized"] = False
            with self.assertRaises(release.ReleaseError):
                release.verify_artifacts(manifest, info, archive)


if __name__ == "__main__":
    unittest.main()
