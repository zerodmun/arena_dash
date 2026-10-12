#!/usr/bin/env python3
"""Read-only APK audit; requires Android SDK apkanalyzer and apksigner on PATH.
A passing structural check does not certify an APK as harmless or clear Play Protect.
"""
import argparse
import hashlib
import json
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

A = '{http://schemas.android.com/apk/res/android}'

def digest(data):
    return hashlib.sha256(data).hexdigest()

def elf_hardening(data):
    if data[:5] != b'\x7fELF\x02' or data[5] != 1:
        return {'inspection': 'unsupported ELF format'}
    phoff = struct.unpack_from('<Q', data, 32)[0]
    phsize, count = struct.unpack_from('<HH', data, 54)
    headers = [struct.unpack_from('<IIQQQQQQ', data, phoff + i * phsize) for i in range(count)]
    stacks = [h for h in headers if h[0] == 0x6474e551]
    bind_now = False
    for h in headers:
        if h[0] == 2:
            for pos in range(h[2], h[2] + h[5], 16):
                tag, value = struct.unpack_from('<QQ', data, pos)
                if tag == 0: break
                bind_now |= tag == 24 or (tag == 30 and bool(value & 8)) or (tag == 0x6ffffffb and bool(value & 1))
    return {'non_executable_stack': bool(stacks) and all(not h[1] & 1 for h in stacks),
            'gnu_relro': any(h[0] == 0x6474e552 for h in headers), 'bind_now': bind_now}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--template', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    manifest = subprocess.check_output(['apkanalyzer', 'manifest', 'print', str(args.apk)], text=True)
    root = ET.fromstring(manifest)
    app = root.find('application')
    permissions = [n.get(A+'name') for n in root if n.tag.startswith('uses-permission')]
    sdk = root.find('uses-sdk')
    with zipfile.ZipFile(args.apk) as apk, zipfile.ZipFile(args.template) as template:
        names = apk.namelist()
        binaries = [n for n in names if re.fullmatch(r'classes\d*\.dex', n) or n.startswith('lib/') and n.endswith('.so')]
        expected = [n for n in template.namelist() if re.fullmatch(r'classes\d*\.dex', n) or n.startswith('lib/arm64-v8a/') and n.endswith('.so')]
        binary_results = {}
        for n in binaries:
            data = apk.read(n)
            binary_results[n] = {'sha256': digest(data), 'bytes': len(data),
                'matches_installed_template': n in template.namelist() and data == template.read(n)}
            if n.endswith('.so'): binary_results[n]['elf'] = elf_hardening(data)
        forbidden = [n for n in names if re.search(r'(^|/)(opencode\.json|export_presets\.cfg|\.env|[^/]+\.(keystore|jks|p12|pfx|pem|key))$', n)]
        versions = {n.rsplit('/',1)[-1][:-8]: apk.read(n).decode().strip() for n in names if n.endswith('.version')}
        sparse_identifiers = []
        for n in names:
            if n.endswith('.sparsepck'):
                pack = apk.read(n)
                sparse_identifiers += [v.decode() for v in (b'opencode.json',b'debug.keystore',b'export_presets.cfg',b'build_apk.sh') if v in pack]
    signature = subprocess.run(['apksigner','verify','--verbose','--print-certs',str(args.apk)], capture_output=True, text=True)
    components = []
    for c in app:
        if c.tag in ('activity','activity-alias','service','receiver','provider'):
            components.append({'type': c.tag, **{k.replace(A,''):v for k,v in c.attrib.items()},
                'intent_actions': [a.get(A+'name') for a in c.findall('intent-filter/action')]})
    result = {'apk': str(args.apk.resolve()), 'apk_sha256':digest(args.apk.read_bytes()),
        'package':root.get('package'), 'version':root.get(A+'versionName'), 'version_code':root.get(A+'versionCode'),
        'sdk':{k.replace(A,''):v for k,v in sdk.attrib.items()}, 'permissions': permissions,
        'application':{k.replace(A,''):v for k,v in app.attrib.items()},
        'profileable':{k.replace(A,''):v for k,v in app.find('profileable').attrib.items()} if app.find('profileable') is not None else {},
        'sparse_pack_development_identifiers':sparse_identifiers, 'components': components,
        'binaries':binary_results, 'missing_template_binaries':sorted(set(expected)-set(binaries)),
        'forbidden_packaged_files':forbidden, 'dependency_version_metadata':versions,
        'signature_verified':signature.returncode == 0, 'signature_report':signature.stdout + signature.stderr,
        'scope':'Static structure and installed-template comparison only; no behavioral malware certification, Play Protect verdict, or complete vulnerability/reachability analysis.'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2)+'\n')
    args.output.with_suffix('.manifest.xml').write_text(manifest)
    print(json.dumps({k:result[k] for k in ('apk_sha256','permissions','forbidden_packaged_files','signature_verified','missing_template_binaries')},indent=2))
    print('All executable entries match installed template:',all(v['matches_installed_template'] for v in binary_results.values()))

if __name__ == '__main__': main()
