#!/usr/bin/env python3
"""Exercise release security rejection paths using the decoded audited manifest."""
import copy
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / 'tools'))
from android_release_policy import A, CERTIFICATE_SHA256, verify_certificate, verify_manifest, require

class ReleasePolicyTests(unittest.TestCase):
    def setUp(self):
        self.root = ET.parse(Path(__file__).with_name('android_release_manifest.xml')).getroot()
    def test_existing_release(self):
        verify_certificate(CERTIFICATE_SHA256)
        result = verify_manifest(self.root)
        self.assertEqual(result['permissions'], [])
        self.assertEqual(result['target_sdk'], 36)
    def test_reject_other_production_certificate(self):
        with self.assertRaises(ValueError): verify_certificate('0' * 64)
    def test_reject_permission(self):
        ET.SubElement(self.root, 'uses-permission', {A+'name':'android.permission.INTERNET'})
        with self.assertRaises(ValueError): verify_manifest(self.root)
    def test_reject_debug_flags_and_backup(self):
        for flag in ['debuggable','testOnly','allowBackup','requestLegacyExternalStorage']:
            root = copy.deepcopy(self.root)
            root.find('application').set(A+flag, 'true')
            with self.subTest(flag=flag), self.assertRaises(ValueError): verify_manifest(root)
    def test_reject_exposed_provider(self):
        self.root.find('application/provider').set(A+'exported','true')
        with self.assertRaises(ValueError): verify_manifest(self.root)
    def test_reject_unprotected_receiver(self):
        self.root.find('application/receiver').attrib.pop(A+'permission')
        with self.assertRaises(ValueError): verify_manifest(self.root)
    def test_reject_injected_service(self):
        ET.SubElement(self.root.find('application'), 'service', {A+'name':'unexpected.Service', A+'exported':'true'})
        with self.assertRaises(ValueError): verify_manifest(self.root)
    def test_reject_identity_or_sdk_change(self):
        root = copy.deepcopy(self.root);root.set('package','other.game')
        with self.assertRaises(ValueError): verify_manifest(root)
        self.root.find('uses-sdk').set(A+'targetSdkVersion','23')
        with self.assertRaises(ValueError): verify_manifest(self.root)
    def test_checks_survive_python_optimization(self):
        with self.assertRaises(ValueError): require(False, 'must fail')

if __name__ == '__main__': unittest.main()
