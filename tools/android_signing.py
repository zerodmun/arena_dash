#!/usr/bin/env python3
"""Manage Arena Dash's local signing metadata and macOS Keychain credential.

Secrets pass through stdin or child environments, never argv or stdout.
Initialization is an explicit maintenance operation, never a build fallback.
"""
import hashlib
import json
import os
from pathlib import Path
import secrets
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
STORE = Path.home() / 'Library/Application Support/Arena Dash/signing'
CONFIG = STORE / 'release.json'
SERVICE = 'Arena Dash Android production signing'
ACCOUNT = 'com.example.arenadash.release'
VARS = ('GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER',
        'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')


def fail(message):
    raise SystemExit('Release signing blocked: ' + message)


def keychain_password(service, account):
    result = subprocess.run(['/usr/bin/security', 'find-generic-password', '-s', service,
                             '-a', account, '-w'], capture_output=True)
    if result.returncode:
        fail('macOS Keychain credential is unavailable or access was denied. Approve Keychain access if prompted; the signing identity has not been replaced.')
    value = result.stdout.rstrip(b'\r\n').decode('utf-8')
    if not value:
        fail('Keychain returned an empty signing credential.')
    return value


def private_json(path, value):
    with path.open('x', encoding='utf-8') as handle:
        os.chmod(path, 0o600)
        json.dump(value, handle, indent=2)
        handle.write('\n')


def initialize():
    # The caller must first audit existing identities/distribution. Never overwrite.
    os.umask(0o077)
    STORE.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(STORE, 0o700)
    keystore = STORE / 'arena_dash_release.p12'
    if CONFIG.exists() or keystore.exists():
        fail('a local signing identity already exists; reuse or recover it.')
    existing = subprocess.run(['/usr/bin/security', 'find-generic-password', '-s', SERVICE,
                               '-a', ACCOUNT], capture_output=True)
    if existing.returncode == 0:
        fail('the production Keychain item already exists; recover it instead of generating another key.')
    if existing.returncode != 44:
        fail('Keychain could not be inspected safely; no key was generated.')
    password = secrets.token_hex(48)  # 384 bits of random entropy.
    # Interactive security input keeps the password out of process arguments.
    parts = ['add-generic-password', '-s', SERVICE, '-a', ACCOUNT, '-l', SERVICE,
             '-j', 'Arena Dash release PKCS12 keystore and private-key password',
             '-T', '/usr/bin/security', '-w', password]
    result = subprocess.run(['/usr/bin/security', '-i'], input=(' '.join(map(shlex.quote, parts))+'\n').encode(),
                            capture_output=True)
    if result.returncode or keychain_password(SERVICE, ACCOUNT) != password:
        fail('the credential could not be stored and verified in Keychain; no key was generated.')
    env = dict(os.environ, GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=password)
    java_home = env.get('JAVA_HOME', '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home')
    keytool = str(Path(java_home) / 'bin/keytool')
    alias = 'arena-dash-release'
    result = subprocess.run([keytool, '-genkeypair', '-storetype', 'PKCS12', '-keystore', str(keystore),
                             '-alias', alias, '-keyalg', 'RSA', '-keysize', '3072', '-sigalg', 'SHA256withRSA',
                             '-validity', '10000', '-dname', 'CN=Arena Dash, O=TenTen Digital Indonesia, C=ID',
                             '-storepass:env', VARS[2], '-keypass:env', VARS[2]], env=env, capture_output=True)
    if result.returncode:
        fail('key generation failed. The reserved Keychain credential is retained for recovery; no replacement will be generated automatically.')
    os.chmod(keystore, 0o600)
    cert = subprocess.run([keytool, '-exportcert', '-keystore', str(keystore), '-alias', alias,
                           '-storepass:env', VARS[2]], env=env, capture_output=True)
    if cert.returncode:
        fail('new key certificate could not be verified; preserve the key and Keychain record.')
    metadata = dict(schema=1, package='com.example.arenadash', keystore=str(keystore), alias=alias,
                    keychain_service=SERVICE, keychain_account=ACCOUNT,
                    certificate_sha256=hashlib.sha256(cert.stdout).hexdigest())
    private_json(CONFIG, metadata)
    (STORE / 'RECOVERY.md').write_text('''# Arena Dash signing recovery\n\nKeep this signing directory in an encrypted offline backup. Its PKCS12 file contains the irreplaceable private signing key; release.json identifies the certificate and alias but contains no password.\n\nThe randomly generated store/private-key password is stored in the macOS login Keychain as **Arena Dash Android production signing**, account **com.example.arenadash.release**. Preserve this login Keychain using an encrypted Mac backup. For independent recovery, open Keychain Access, authenticate to reveal this one record, and save it in your encrypted password manager or encrypted offline backup. Never paste it into chat or source code.\n\nRecovery needs BOTH the PKCS12 file and its Keychain/password-manager credential. Losing either prevents signing future updates. Copying just this directory does not back up the password. Never regenerate or overwrite this identity.\n''')
    os.chmod(STORE / 'RECOVERY.md', 0o600)
    print('Production signing identity created and credential verified in macOS Keychain.')
    print('Private signing directory: ' + str(STORE))
    print('Certificate SHA-256: ' + metadata['certificate_sha256'])


def build(arguments):
    if not CONFIG.is_file():
        fail('local production configuration is missing. No automatic key generation or debug fallback is permitted.')
    config = json.loads(CONFIG.read_text())
    if config.get('schema') != 1 or config.get('package') != 'com.example.arenadash':
        fail('unexpected local signing metadata.')
    key = Path(config['keystore'])
    if not key.is_file():
        fail('the configured production keystore is missing; restore it instead of generating another identity.')
    if key.stat().st_mode & 0o077 or CONFIG.stat().st_mode & 0o077:
        fail('signing files must be accessible only to their owner.')
    password = keychain_password(config['keychain_service'], config['keychain_account'])
    env = dict(os.environ)
    env.update(dict(zip(VARS, [str(key), config['alias'], password])))
    env['ARENA_ANDROID_EXPECTED_CERT_SHA256'] = config['certificate_sha256']
    os.execve('/bin/bash', ['bash', str(ROOT / 'build_apk.sh'), *arguments], env)


if __name__ == '__main__':
    if sys.platform != 'darwin':
        fail('automatic credential retrieval requires macOS Keychain; explicit CI environment variables remain supported.')
    if len(sys.argv) > 1 and sys.argv[1] == 'init-new':
        initialize()
    elif len(sys.argv) > 1 and sys.argv[1] == 'build':
        build(sys.argv[2:])
    else:
        fail('use build or explicit audited init-new maintenance operation.')
