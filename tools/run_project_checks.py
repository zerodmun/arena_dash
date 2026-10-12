#!/usr/bin/env python3
"""Run existing headless scene tests; keep desktop saves and logs in qa/."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('suites', nargs='*', help='Test scene names; default: all tests/*.tscn')
    parser.add_argument('--timeout', type=int, default=240)
    args = parser.parse_args()
    scenes = [ROOT / 'tests' / (s + '.tscn') for s in args.suites] if args.suites else sorted((ROOT / 'tests').glob('*.tscn'))
    if any(not s.is_file() or s.parent != ROOT / 'tests' for s in scenes):
        parser.error('Use existing test scene names without paths or extensions')
    output = ROOT / 'qa' / 'checks'
    output.mkdir(parents=True, exist_ok=True)
    for name in ['splash-qa', 'equipment-qa', 'hangar-layout-qa']:
        (ROOT / 'qa' / name).mkdir(parents=True, exist_ok=True)
    results = []
    for scene in scenes:
        start = time.monotonic()
        cmd = [os.environ.get('GODOT_BIN', 'godot'), '--headless', '--path', str(ROOT),
               '--log-file', str(output / (scene.stem + '.engine.log'))]
        if scene.stem == 'performance_soak':
            cmd += ['--fixed-fps', '60']
        cmd.append(str(scene))
        try:
            run = subprocess.run(cmd, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=args.timeout)
            log, code = run.stdout, run.returncode
        except subprocess.TimeoutExpired as error:
            log, code = error.stdout or b'', 'timeout'
        (output / (scene.stem + '.log')).write_bytes(log)
        result = {'suite': scene.stem, 'exit': code, 'seconds': round(time.monotonic() - start, 2)}
        results.append(result)
        (output / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
        print(json.dumps(result), flush=True)
    return 1 if any(r['exit'] != 0 for r in results) else 0

if __name__ == '__main__':
    raise SystemExit(main())
