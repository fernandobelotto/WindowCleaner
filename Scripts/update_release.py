#!/usr/bin/env python3
"""Sign exact release bytes and build a private, immutable per-release appcast."""
import base64
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

NS = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ET.register_namespace('sparkle', NS)


def sign_archive(archive, info, binary):
    """Sparkle's format is an exported seed, never printed or stored in the repository."""
    private_key = os.environ.get('SPARKLE_PRIVATE_KEY')
    if not private_key:
        raise ValueError('SPARKLE_PRIVATE_KEY is required for a signed release')
    result = subprocess.run([str(binary), '--ed-key-file', '-', str(archive)], input=private_key,
                            capture_output=True, text=True, check=True)
    match = re.fullmatch(r'\s*sparkle:edSignature="([A-Za-z0-9+/=]+)" length="([0-9]+)"\s*', result.stdout)
    if not match or int(match[2]) != Path(archive).stat().st_size:
        raise ValueError('Sparkle signing output does not match archive length')
    signature = match[1]
    verify_archive(archive, signature, info['SUPublicEDKey'])
    return {'enclosure': Path(archive).name, 'length': int(match[2]), 'edSignature': signature}


def verify_archive(archive, signature, public_key):
    key = base64.b64decode(public_key, validate=True)
    sig = base64.b64decode(signature, validate=True)
    if len(key) != 32 or len(sig) != 64:
        raise ValueError('Invalid updater public key or archive signature')
    with tempfile.TemporaryDirectory(prefix='verify-update-') as temporary:
        root = Path(temporary)
        (root / 'public.der').write_bytes(bytes.fromhex('302a300506032b6570032100') + key)
        (root / 'signature').write_bytes(sig)
        result = subprocess.run(['openssl', 'pkeyutl', '-verify', '-pubin', '-keyform', 'DER',
                                 '-inkey', str(root / 'public.der'), '-rawin', '-in', str(archive),
                                 '-sigfile', str(root / 'signature')], capture_output=True)
        if result.returncode:
            raise ValueError('Update archive signature does not verify against the application public key')


def appcast(release, repository, asset, notes, minimum='15.0'):
    signature = release.get('sparkle', {})
    if (not isinstance(asset.get('id'), int) or asset['id'] < 1
            or asset.get('name') != signature.get('enclosure')
            or asset.get('size') != signature.get('length')
            or not isinstance(asset.get('size'), int) or asset['size'] <= 0
            or len(base64.b64decode(signature.get('edSignature', ''), validate=True)) != 64
            or not re.fullmatch(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)', release['version'])
            or not re.fullmatch(r'[1-9][0-9]*(\.[0-9]+){0,2}', str(release['build']))):
        raise ValueError('Update release signature or immutable asset metadata is invalid')
    rss = ET.Element('rss', {'version': '2.0'})
    channel = ET.SubElement(rss, 'channel')
    ET.SubElement(channel, 'title').text = repository.rsplit('/', 1)[-1] + ' Updates'
    item = ET.SubElement(channel, 'item')
    ET.SubElement(item, 'title').text = release['version']
    ET.SubElement(item, '{' + NS + '}version').text = str(release['build'])
    ET.SubElement(item, '{' + NS + '}shortVersionString').text = release['version']
    ET.SubElement(item, '{' + NS + '}minimumSystemVersion').text = minimum
    # Inline text avoids authenticated release note loads or HTML execution.
    ET.SubElement(item, 'description', {'{' + NS + '}format': 'plain-text'}).text = notes
    ET.SubElement(item, 'enclosure', {'url': f'https://api.github.com/repos/{repository}/releases/assets/{asset["id"]}?filename={asset["name"]}',
                                     'length': str(asset['size']), 'type': 'application/octet-stream',
                                     '{' + NS + '}edSignature': signature['edSignature']})
    ET.indent(rss)
    return ET.tostring(rss, encoding='utf-8', xml_declaration=True) + b'\n'


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', required=True)
    parser.add_argument('--info', required=True)
    parser.add_argument('--manifest', required=True)
    parser.add_argument('--sign-update', required=True)
    args = parser.parse_args()
    manifest = Path(args.manifest)
    release = json.loads(manifest.read_text())
    release['sparkle'] = sign_archive(Path(args.archive), plistlib.loads(Path(args.info).read_bytes()), Path(args.sign_update))
    manifest.write_text(json.dumps(release, indent=2) + '\n')


def verify_update(manifest, archive, info):
    evidence = json.loads(Path(manifest).read_text())
    signature = evidence.get('sparkle', {})
    if signature.get('enclosure') != Path(archive).name or signature.get('length') != Path(archive).stat().st_size:
        raise ValueError('Signed update provenance does not match the release archive')
    verify_archive(archive, signature.get('edSignature', ''), plistlib.loads(Path(info).read_bytes())['SUPublicEDKey'])
    return evidence


def publish_appcast(run, repository, tag, manifest, archive, info, notes, minimum):
    evidence = verify_update(manifest, archive, info)
    if 'build' not in evidence:
        evidence['build'] = evidence['build_number']
    draft = json.loads(run('gh', 'api', f'repos/{repository}/releases/tags/{tag}'))
    if not draft.get('draft') or draft.get('prerelease'):
        raise ValueError('Update metadata may only be added to a stable unpublished draft')
    assets = [asset for asset in draft['assets'] if asset['name'] == Path(archive).name]
    if len(assets) != 1:
        raise ValueError('The immutable update archive asset is missing or duplicated')
    feed = Path(manifest).parent / 'appcast.xml'
    feed.write_bytes(appcast(evidence, repository, assets[0], notes, minimum))
    run('gh', 'release', 'upload', tag, str(feed), '--repo', repository)
    with tempfile.TemporaryDirectory(prefix='verify-update-feed-') as temporary:
        run('gh', 'release', 'download', tag, '--repo', repository, '--pattern', 'appcast.xml', '--dir', temporary)
        if (Path(temporary) / 'appcast.xml').read_bytes() != feed.read_bytes():
            raise ValueError('Uploaded update metadata differs from the verified release')
