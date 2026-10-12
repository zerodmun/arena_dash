#!/usr/bin/env python3
"""Fail before publication if an Android export differs from its intended identity."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent

def command(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--mode', choices=['debug', 'release'], required=True)
    parser.add_argument('--expected-cert', default='')
    parser.add_argument('--report', required=True, type=Path)
    args = parser.parse_args()
    preset = (ROOT / 'export_presets.cfg').read_text().split('[preset.1]')[0]
    package = re.search(r'package/unique_name="([^"]+)"', preset)[1]
    version = re.search(r'version/code=(\d+)', preset)[1]
    # aapt badging rejects a template's typed feature attribute; use decoded XML
    # for authoritative manifest validation and retain aapt's raw tree as evidence.
    manifest = command('apkanalyzer', 'manifest', 'print', str(args.apk))
    aapt_tree = command('aapt', 'dump', 'xmltree', str(args.apk), 'AndroidManifest.xml')
    root = ET.fromstring(manifest)
    android = '{http://schemas.android.com/apk/res/android}'
    app = root.find('application')
    assert (root.get('package'), root.get(android+'versionCode')) == (package, version), 'Unexpected package or version'
    assert not root.get('split'), 'Split APK cannot be published as standalone'
    assert app.get(android+'isSplitRequired', 'false') != 'true', 'Split dependency'
    debuggable = app.get(android+'debuggable', 'false') == 'true'
    if args.mode == 'release':
        assert not debuggable, 'Release is debuggable'
        assert app.get(android+'testOnly', 'false') != 'true', 'Release is test-only'
        assert args.expected_cert, 'Production certificate identity is required'
    signature = command('apksigner', 'verify', '--verbose', '--print-certs', str(args.apk))
    certificate = re.search(r'certificate SHA-256 digest: ([0-9a-f]+)', signature)[1]
    if args.expected_cert:
        assert certificate == args.expected_cert.lower(), 'APK is signed by a different key'
        assert 'CN=Android Debug' not in signature, 'Debug signing is forbidden for release'
    template = ROOT / 'templates' / ('android_' + args.mode + '.apk')
    with zipfile.ZipFile(args.apk) as apk, zipfile.ZipFile(template) as stock:
        assert apk.testzip() is None, 'Invalid APK ZIP'
        abis = sorted({n.split('/')[1] for n in apk.namelist() if n.startswith('lib/') and n.endswith('.so')})
        expected_abis = sorted(re.findall(r'architectures/([^=]+)=true', preset))
        assert abis == expected_abis, 'APK architectures differ from export preset'
        binaries = [n for n in apk.namelist() if re.fullmatch(r'classes\d*\.dex', n) or n.endswith('.so') and n.startswith('lib/')]
        assert binaries and all(n in stock.namelist() and apk.read(n) == stock.read(n) for n in binaries), 'Executable differs from exact-version export template'
        icon_resources = [n for n in apk.namelist() if re.fullmatch(r'res/mipmap[^/]*/icon(?:_foreground|_background)?\.(webp|png|xml)', n)]
        assert 'res/mipmap-anydpi-v26/icon.xml' in icon_resources, 'Adaptive launcher missing'
        assert len(icon_resources) >= 16, 'Launcher density resources missing'
        with tempfile.TemporaryDirectory(prefix='arena-icon-check-') as directory:
            for suffix in ['', '_foreground', '_background']:
                name = 'icon' + suffix + '.webp'
                Path(directory, name).write_bytes(apk.read('res/mipmap-xxxhdpi-v4/' + name))
            command(os.environ['ARENA_ICON_NODE_BIN'], str(ROOT / 'tools/render_android_icons.cjs'), '--verify', directory)
    command('zipalign', '-c', '-P', '16', '4', str(args.apk))
    result = dict(package=package, version_code=int(version), mode=args.mode, debuggable=debuggable,
                  standalone=True, architectures=abis, template=str(template.resolve()),
                  executable_template_match=True, signature_verified=True, certificate_sha256=certificate,
                  aligned=True, zip_integrity=True, icon_resources=icon_resources, icon_pixels_verified=True,
                  sha256=hashlib.sha256(args.apk.read_bytes()).hexdigest())
    args.report.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
