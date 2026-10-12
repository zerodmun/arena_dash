#!/usr/bin/env python3
"""Actual Android multi-pointer QA in a separate package; never uses player save."""
import json,subprocess,time,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'qa/home-premium-qa'
ADB=str(Path.home()/'Library/Android/sdk/platform-tools/adb')
PKG='com.example.arenadash.review'
def adb(*args,**kw):return subprocess.run([ADB,*args],check=True,**kw)
for weapon in (sys.argv[1:] or ['plasma_lance','nova_burst']):
    config=OUT/'combat-config.json'
    config.write_text(json.dumps({'gameplay':True,'ship':'vortex','weapon':weapon,'map':'cyber'}))
    adb('shell','am','force-stop',PKG)
    adb('push',str(config),'/data/local/tmp/arena_review_combat.json',stdout=subprocess.DEVNULL)
    adb('shell','run-as',PKG,'cp','/data/local/tmp/arena_review_combat.json','files/movement_fire_qa.json')
    log_path=OUT/(weapon+'-logcat.txt')
    with log_path.open('w') as log:
        logger=subprocess.Popen([ADB,'logcat','-T','1'],stdout=log,stderr=log)
        recorder=None
        try:
            adb('shell','am','start','-n',PKG+'/com.godot.game.GodotAppLauncher',stdout=subprocess.DEVNULL)
            deadline=time.monotonic()+45
            time.sleep(2)
            startup_text=''
            pid=adb('shell','pidof',PKG,capture_output=True,text=True).stdout.strip()
            while 'AUTO_GAMEPLAY_STARTED' not in startup_text:
                startup_text=adb('logcat','-d','--pid='+pid,'-s','godot',capture_output=True,text=True).stdout
                if time.monotonic()>deadline:raise RuntimeError('QA gameplay did not start')
                time.sleep(.3)
            remote='/sdcard/arena-review-'+weapon+'.mp4'
            recorder=subprocess.Popen([ADB,'shell','screenrecord','--time-limit','24',remote])
            command=[ADB,'shell','am','instrument','-w','-e','jx','281','-e','jy','886','-e','fx','2130','-e','fy','884','-e','radius','100','-e','mode','matrix','-e','case_seconds','2','com.arenadash.qa/.TouchRunner']
            runner=subprocess.Popen(command,stdout=(OUT/(weapon+'-input.txt')).open('w'),stderr=subprocess.STDOUT)
            time.sleep(1.3)
            with (OUT/(weapon+'-stationary.png')).open('wb') as image:adb('exec-out','screencap','-p',stdout=image)
            time.sleep(8)
            with (OUT/(weapon+'-moving.png')).open('wb') as image:adb('exec-out','screencap','-p',stdout=image)
            runner.wait(timeout=30)
            result=(OUT/(weapon+'-input.txt')).read_text()
            if 'INSTRUMENTATION_CODE: -1' not in result:raise RuntimeError(result)
            recorder.wait(timeout=30)
            adb('pull',remote,str(OUT/(weapon+'.mp4')),stdout=subprocess.DEVNULL)
            log.write(adb('logcat','-d','--pid='+pid,'-s','godot','ArenaDashQA',capture_output=True,text=True).stdout)
            print(weapon+': multi-pointer matrix complete',flush=True)
        finally:
            if recorder and recorder.poll() is None:recorder.terminate()
            logger.terminate();logger.wait()
adb('shell','am','force-stop',PKG)
adb('shell','run-as',PKG,'rm','files/movement_fire_qa.json')
