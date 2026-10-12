#!/usr/bin/env python3
"""Phone-local Android multi-pointer matrix; isolated QA package only."""
import json,subprocess,time,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/(sys.argv[1] if len(sys.argv)>1 else 'qa/projectile-rebuild-qa/matrix')
OUT.mkdir(parents=True,exist_ok=True)
MAP=sys.argv[2] if len(sys.argv)>2 else 'cyber'
ADB=str(Path.home()/'Library/Android/sdk/platform-tools/adb');PKG='com.example.arenadash.review'
def adb(*args,**kw):return subprocess.run([ADB,*args],check=True,**kw)
for weapon in ['ion','plasma','twin_laser','quantum_spread','plasma_lance','nova_burst']:
 config=OUT/'config.json';config.write_text(json.dumps({'gameplay':True,'ship':'tempest','weapon':weapon,'map':MAP,'projectile_trace':True,'projectile_markers':False}))
 adb('shell','am','force-stop',PKG)
 adb('push',str(config),'/data/local/tmp/arena_matrix_config.json',stdout=subprocess.DEVNULL)
 adb('shell','run-as',PKG,'cp','/data/local/tmp/arena_matrix_config.json','files/movement_fire_qa.json')
 adb('shell','am','start','-n',PKG+'/com.godot.game.GodotAppLauncher',stdout=subprocess.DEVNULL)
 time.sleep(3)
 pid=adb('shell','pidof',PKG,capture_output=True,text=True).stdout.strip()
 deadline=time.monotonic()+45
 while 'AUTO_GAMEPLAY_STARTED' not in adb('logcat','-d','--pid='+pid,'-s','godot',capture_output=True,text=True).stdout:
  if time.monotonic()>deadline:raise RuntimeError('No gameplay startup')
  time.sleep(.5)
 remote='/sdcard/arena-rebuild-'+weapon+'.mp4';result_path='/data/local/tmp/arena-matrix-'+weapon+'.txt'
 adb('shell','nohup screenrecord --time-limit 24 '+remote+' > /data/local/tmp/arena-matrix-video.txt 2>&1 < /dev/null &')
 adb('shell','nohup am instrument -w -e jx 281 -e jy 886 -e fx 2130 -e fy 884 -e radius 100 -e mode matrix -e case_seconds 2 com.arenadash.qa/.TouchRunner > '+result_path+' 2>&1 < /dev/null &')
 start=time.monotonic();time.sleep(1.3)
 with (OUT/(weapon+'-stationary.png')).open('wb') as shot:adb('exec-out','screencap','-p',stdout=shot)
 time.sleep(8)
 with (OUT/(weapon+'-moving.png')).open('wb') as shot:adb('exec-out','screencap','-p',stdout=shot)
 while time.monotonic()-start<25:time.sleep(.5)
 result=adb('shell','cat',result_path,capture_output=True,text=True).stdout
 (OUT/(weapon+'-input.txt')).write_text(result)
 if 'INSTRUMENTATION_CODE: -1' not in result:raise RuntimeError(result)
 adb('pull',remote,str(OUT/(weapon+'.mp4')),stdout=subprocess.DEVNULL)
 with (OUT/(weapon+'-trace.jsonl')).open('wb') as trace:adb('exec-out','run-as',PKG,'cat','files/projectile_trace.jsonl',stdout=trace)
 (OUT/(weapon+'-logcat.txt')).write_text(adb('logcat','-d','--pid='+pid,'-s','godot','ArenaDashQA',capture_output=True,text=True).stdout)
 print(weapon+': device-local multitouch complete',flush=True)
adb('shell','am','force-stop',PKG)
adb('shell','run-as',PKG,'rm','files/movement_fire_qa.json')
