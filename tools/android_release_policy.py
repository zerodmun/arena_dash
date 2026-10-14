#!/usr/bin/env python3
"""Public release identity and offline-app manifest contract. Contains no secrets."""

PACKAGE = 'com.example.arenadash'
CERTIFICATE_SHA256 = '317b9baedaf187bd9e4cf17096fbca1119dac169f063e3090bd9b5bc8e3523af'
A = '{http://schemas.android.com/apk/res/android}'

def require(condition, message):
    # Unlike assert, these release gates remain active with PYTHONOPTIMIZE=1.
    if not condition:
        raise ValueError(message)

def verify_certificate(certificate):
    require(certificate.lower() == CERTIFICATE_SHA256,
            'Production certificate differs from the established Arena Dash identity')

def verify_manifest(root):
    require(root.get('package') == PACKAGE, 'Application ID differs from the established identity')
    sdk = root.find('uses-sdk')
    require(sdk is not None, 'Missing SDK declaration')
    require(sdk.get(A + 'minSdkVersion') == '24', 'Minimum SDK changed; existing device support must be preserved')
    require(int(sdk.get(A + 'targetSdkVersion', '0')) >= 36, 'Target SDK must be at least 36')
    permissions = [n.get(A + 'name') for n in root if n.tag.startswith('uses-permission')]
    require(not permissions, 'Offline release unexpectedly requests Android permissions: ' + str(permissions))
    app = root.find('application')
    require(app is not None, 'Missing application')
    for flag in ['debuggable', 'testOnly', 'allowBackup', 'requestLegacyExternalStorage']:
        require(app.get(A + flag, 'false') == 'false', 'Release enables ' + flag)
    expected = {
        ('activity', 'com.godot.game.GodotApp'): False,
        ('activity-alias', 'com.godot.game.GodotAppLauncher'): True,
        ('activity', 'org.godotengine.godot.utils.ProcessPhoenix'): False,
        ('provider', 'androidx.core.content.FileProvider'): False,
        ('provider', 'androidx.startup.InitializationProvider'): False,
        ('receiver', 'androidx.profileinstaller.ProfileInstallReceiver'): True,
    }
    found = set()
    exported = []
    for node in app:
        if node.tag not in ['activity', 'activity-alias', 'provider', 'receiver', 'service']:
            continue
        key = (node.tag, node.get(A + 'name'))
        require(key in expected and key not in found, 'Unexpected or duplicate Android component: ' + str(key))
        found.add(key)
        require(node.get(A + 'exported') == str(expected[key]).lower(), 'Component exposure changed: ' + str(key))
        if not expected[key]:
            continue
        exported.append(node.get(A + 'name'))
        if node.tag == 'activity-alias':
            require(node.get(A + 'targetActivity') == 'com.godot.game.GodotApp', 'Unexpected launcher target')
            require([n.get(A + 'name') for n in node.findall('intent-filter/action')] == ['android.intent.action.MAIN'], 'Unexpected launcher actions')
            require([n.get(A + 'name') for n in node.findall('intent-filter/category')] == ['android.intent.category.DEFAULT', 'android.intent.category.LAUNCHER'], 'Unexpected launcher categories')
        else:
            require(node.get(A + 'permission') == 'android.permission.DUMP', 'Profile receiver lacks privileged DUMP protection')
    require(found == set(expected), 'Required stock Android components are missing')
    return {'minimum_sdk': 24, 'target_sdk': int(sdk.get(A + 'targetSdkVersion')),
            'permissions': permissions, 'exported_components': exported,
            'backup_allowed': False, 'test_only': False}

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--certificate', required=True)
    args = parser.parse_args()
    try:
        verify_certificate(args.certificate)
    except ValueError as error:
        parser.exit(1, 'Release blocked: ' + str(error) + '\n')
