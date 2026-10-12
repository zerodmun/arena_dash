#!/usr/bin/env python3
"""Opt-in debug device QA. Actual multi-pointer events; keeps production save intact."""
import argparse, json, os, subprocess, time
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument('mode',choices=['matrix','equipment'])
parser.add_argument('--serial',default='13ff9514')
args=parser.parse_args()
root=Path(__file__).resolve().parent.parent
out=root/'qa/movement-fire-qa';out.mkdir(parents=True,exist_ok=True)
base=[str(Path.home()/'Library/Android/sdk/platform-tools/adb'),'-s',args.serial]
def adb(*cmd,**kw):return subprocess.run(base+list(cmd),check=True,**kw)
pkg='com.example.arenadash'
config={'ship':'tempest','weapon':'quantum_spread','map':'cyber','equipment_cycle':args.mode=='equipment'}
config_path=out/'device-config.json';config_path.write_text(json.dumps(config))
adb('shell','am','force-stop','com.arenadash.qa')
adb('shell','am','force-stop',pkg)
adb('push',str(config_path),'/data/local/tmp/arena_movement_qa.json',stdout=subprocess.DEVNULL)
adb('shell','run-as',pkg,'cp','/data/local/tmp/arena_movement_qa.json','files/movement_fire_qa.json')
name='fixed-matrix' if args.mode=='matrix' else 'fixed-equipment'
log_path=out/(name+'-logcat.txt')
with log_path.open('w') as log:
    logger=subprocess.Popen(base+['logcat','-T','1'],stdout=log,stderr=log)
    recorder=None
    try:
        adb('shell','am','start','-n',pkg+'/com.godot.game.GodotAppLauncher',stdout=subprocess.DEVNULL)
        deadline=time.monotonic()+35
        while 'AUTO_GAMEPLAY_STARTED' not in log_path.read_text(errors='replace'):
            if time.monotonic()>deadline:raise RuntimeError('No diagnostic gameplay startup; test not valid')
            time.sleep(.2)
        seconds=48 if args.mode=='matrix' else 164
        remote='/sdcard/arena_'+name+'.mp4'
        recorder=subprocess.Popen(base+['shell','screenrecord','--time-limit',str(seconds),remote])
        command=['shell','am','instrument','-w','-e','jx','281','-e','jy','886','-e','fx','2130','-e','fy','884','-e','radius','100']
        command+=['-e','mode','matrix'] if args.mode=='matrix' else ['-e','seconds','158']
        result=adb(*command,'com.arenadash.qa/.TouchRunner',capture_output=True,text=True)
        (out/(name+'-input.txt')).write_text(result.stdout+result.stderr)
        if 'INSTRUMENTATION_CODE: -1' not in result.stdout:raise RuntimeError('Touch injection did not complete')
        print(result.stdout,flush=True)
        recorder.wait(timeout=seconds+15)
        adb('pull',remote,str(out/(name+'.mp4')),stdout=subprocess.DEVNULL)
        adb('exec-out','screencap','-p',stdout=(out/(name+'-final.png')).open('wb'))
    finally:
        if recorder and recorder.poll() is None:recorder.terminate()
        logger.terminate();logger.wait()
