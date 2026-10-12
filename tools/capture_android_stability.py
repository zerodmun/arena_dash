#!/usr/bin/env python3
"""Capture a real Android gameplay session; requires one authorized ADB device."""
import argparse, hashlib, json, os, shutil, subprocess, time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial')
    parser.add_argument('--seconds', type=int, default=600)
    parser.add_argument('--apk', type=Path, help='Optionally install this debug APK before capture')
    parser.add_argument('--output', type=Path, default=Path('qa/android-stability'))
    args = parser.parse_args()
    if args.seconds < 600:
        parser.error('Use at least 600 seconds to verify the requested ten-minute session.')
    adb = shutil.which('adb')
    if not adb:
        sdk = os.environ.get('ANDROID_SDK_ROOT', str(Path.home() / 'Library/Android/sdk'))
        candidate = Path(sdk) / 'platform-tools/adb'
        if candidate.is_file():
            adb = str(candidate)
    if not adb:
        parser.error('ADB is unavailable; install Android platform-tools first.')
    discovery = subprocess.run([adb, 'devices'], text=True, capture_output=True, timeout=20)
    if discovery.returncode:
        parser.error('ADB discovery failed: ' + discovery.stderr.strip())
    devices = discovery.stdout.splitlines()[1:]
    ready = [line.split()[0] for line in devices if len(line.split()) >= 2 and line.split()[1] == 'device']
    serial = args.serial or (ready[0] if len(ready) == 1 else None)
    if not serial or serial not in ready:
        parser.error('Connect and authorize one Android device, or specify its --serial.')
    command = [adb, '-s', serial]
    package = 'com.example.arenadash'
    args.output.mkdir(parents=True, exist_ok=True)
    def run(*parts):
        return subprocess.run(command + list(parts), text=True, capture_output=True, timeout=30)
    properties = {}
    for key in ['ro.product.model', 'ro.build.version.release', 'ro.build.version.sdk', 'ro.build.fingerprint', 'ro.product.cpu.abi', 'ro.hardware.egl', 'ro.opengles.version']:
        properties[key] = run('shell', 'getprop', key).stdout.strip()
    (args.output / 'device.json').write_text(json.dumps(properties, indent=2))
    baseline = run('shell', 'dumpsys', 'activity', 'exit-info', package)
    (args.output / 'exit-info-before.txt').write_text(baseline.stdout + baseline.stderr)
    if args.apk:
        (args.output / 'apk.json').write_text(json.dumps({'path': str(args.apk.resolve()), 'sha256': hashlib.sha256(args.apk.read_bytes()).hexdigest()}, indent=2))
    if args.apk:
        result = run('install', '-r', str(args.apk.resolve()))
        if result.returncode:
            parser.error(result.stdout + result.stderr)
    with (args.output / 'logcat.txt').open('w') as log:
        capture = subprocess.Popen(command + ['logcat', '-b', 'main', '-b', 'system', '-b', 'crash', '-b', 'events',
            '-v', 'threadtime', '-T', '1', 'godot:V', 'Godot:V', 'AndroidRuntime:E',
            'DEBUG:V', 'libc:V', 'lmkd:I', 'lowmemorykiller:I', 'ActivityManager:I',
            'ActivityTaskManager:I', 'am_crash:I', 'am_anr:I', 'am_kill:I', 'am_proc_died:I', '*:E'], stdout=log, stderr=log)
        records = []
        completed = False
        stopped_reason = "interrupted"
        initial_pid = ""
        started = time.monotonic()
        try:
            launch = run('shell', 'monkey', '-p', package, '-c', 'android.intent.category.LAUNCHER', '1')
            if launch.returncode:
                parser.error(launch.stdout + launch.stderr)
            print('Recording the diagnostic build for ten minutes. Automated gameplay requires its --stability-auto export flag.', flush=True)
            while time.monotonic() - started < args.seconds:
                elapsed = time.monotonic() - started
                if capture.poll() is not None:
                    stopped_reason = 'logcat_capture_failed'
                    print('Logcat exited; session cannot be verified.', flush=True)
                    break
                status = run('shell', 'pidof', package)
                pid = status.stdout.strip()
                if status.stderr.strip():
                    stopped_reason = 'adb_connection_error'
                    records.append({'elapsed_seconds': round(elapsed, 2), 'adb_error': status.stderr.strip()})
                    break
                if pid and not initial_pid:
                    initial_pid = pid
                elif pid and pid != initial_pid:
                    stopped_reason = 'process_restarted'
                    print('The app process changed; continuous-session verification failed.', flush=True)
                    break
                records.append({'elapsed_seconds': round(elapsed, 2), 'pid': pid})
                if not pid and elapsed > 5:
                    stopped_reason = 'process_exit'
                    print('The app process exited; saving evidence. This does not by itself distinguish a crash from an intentional exit.', flush=True)
                    break
                memory = run('shell', 'dumpsys', 'meminfo', package)
                with (args.output / 'memory.txt').open('a') as out:
                    out.write(f'\nSESSION SECOND {elapsed:.2f}\n{memory.stdout}{memory.stderr}')
                time.sleep(5)
            else:
                completed = True
                stopped_reason = "duration_reached"
        except KeyboardInterrupt:
            print('Capture interrupted; retaining partial evidence.')
        finally:
            capture.terminate()
            try:
                capture.wait(timeout=5)
            except subprocess.TimeoutExpired:
                capture.kill(); capture.wait()
            result = run('shell', 'dumpsys', 'activity', 'exit-info', package)
            (args.output / 'exit-info.txt').write_text(result.stdout + result.stderr)
            (args.output / 'session.json').write_text(json.dumps({'completed_duration': completed,
                'elapsed_seconds': round(time.monotonic() - started, 2), 'stopped_reason': stopped_reason,
                'gameplay_verified': False, 'verification_note': 'Process survival alone is not gameplay verification. Check AUTO_GAMEPLAY_STARTED, PERF game_running/mission_elapsed and crashes before certifying the session.', 'samples': records}, indent=2))
    print(f'Evidence saved to {args.output.resolve()}. Review logs and gameplay before claiming the crash is fixed.')
    return 0 if completed else 1


if __name__ == '__main__':
    raise SystemExit(main())
