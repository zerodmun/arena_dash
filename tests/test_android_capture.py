"""Capture-tool tests with synthetic ADB/time, not Android stability evidence."""
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('capture', Path(__file__).parents[1] / 'tools/capture_android_stability.py')
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)

class CaptureTests(unittest.TestCase):
    def scenario(self, kind):
        clock = [0]
        commands = []
        def run(cmd, **kwargs):
            commands.append(cmd)
            code, out, err = 0, '', ''
            if 'devices' in cmd: out = 'List of devices attached\nFAKE device\n'
            elif 'pidof' in cmd:
                out = '111' if clock[0] < 10 or kind == 'survival' else '222' if kind == 'restart' else ''
                if kind == 'connection' and clock[0] >= 10: err = 'device offline'
            return subprocess.CompletedProcess(cmd, code, out, err)
        class Process:
            def __init__(self, cmd, stdout, stderr):
                commands.append(cmd)
                stdout.write('SYNTHETIC CAPTURE TOOL FIXTURE; NOT DEVICE EVIDENCE\n')
            def poll(self): return 1 if kind == 'logfail' and clock[0] >= 10 else None
            def terminate(self): pass
            def wait(self, **kwargs): return 0
        def sleep(duration): clock[0] += duration
        with tempfile.TemporaryDirectory() as directory:
            with patch('sys.argv', ['capture', '--output', directory]), patch.object(capture.shutil, 'which', return_value='fake-adb'), patch.object(capture.subprocess, 'run', side_effect=run), patch.object(capture.subprocess, 'Popen', Process), patch.object(capture.time, 'monotonic', side_effect=lambda: clock[0]), patch.object(capture.time, 'sleep', side_effect=sleep):
                result = capture.main()
            data = json.loads((Path(directory) / 'session.json').read_text())
            self.assertFalse(data['gameplay_verified'])
            logs = next(cmd for cmd in commands if 'logcat' in cmd)
            self.assertIn('crash', logs)
            self.assertIn('events', logs)
            self.assertIn('am_kill:I', logs)
            return result, data
    def test_survival_is_not_gameplay_verification(self):
        result, data = self.scenario('survival')
        self.assertEqual(result, 0)
        self.assertTrue(data['completed_duration'])
        self.assertEqual(data['stopped_reason'], 'duration_reached')
    def test_process_exit(self):
        result, data = self.scenario('exit')
        self.assertEqual(result, 1)
        self.assertEqual(data['stopped_reason'], 'process_exit')
    def test_restart(self):
        result, data = self.scenario('restart')
        self.assertEqual(result, 1)
        self.assertEqual(data['stopped_reason'], 'process_restarted')
    def test_connection_loss(self):
        result, data = self.scenario('connection')
        self.assertEqual(result, 1)
        self.assertEqual(data['stopped_reason'], 'adb_connection_error')
    def test_logcat_failure(self):
        result, data = self.scenario('logfail')
        self.assertEqual(result, 1)
        self.assertEqual(data['stopped_reason'], 'logcat_capture_failed')

if __name__ == '__main__': unittest.main()
