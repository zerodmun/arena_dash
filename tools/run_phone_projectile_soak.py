#!/usr/bin/env python3
"""310-second physical multitouch regression in the separate Arena Dash QA app."""
import json,subprocess,time,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/(sys.argv[1] if len(sys.argv)>1 else 'qa/projectile-rebuild-qa/soak');OUT.mkdir(parents=True,exist_ok=True)
ADB=str(Path.home()/'Library/Android/sdk/platform-tools/adb')
PKG='com.example.arenadash.review'
def adb(*args,**kw):return subprocess.run([ADB,*args],check=True,**kw)
config=OUT/'config.json';config.write_text(json.dumps({'gameplay':True,'ship':'tempest','weapon':'quantum_spread','map':'cyber','projectile_trace':True,'projectile_markers':False,'equipment_cycle':True,'equipment_interval':3.0}))
adb('shell','am','force-stop',PKG)
adb('push',str(config),'/data/local/tmp/arena_projectile_soak.json',stdout=subprocess.DEVNULL)
adb('shell','run-as',PKG,'cp','/data/local/tmp/arena_projectile_soak.json','files/movement_fire_qa.json')
log_file=OUT/'logcat.txt'
with log_file.open('w') as log:
 logger=subprocess.Popen([ADB,'logcat','-T','1'],stdout=log,stderr=log)
 runner=None;record=None
 try:
  adb('shell','am','start','-n',PKG+'/com.godot.game.GodotAppLauncher',stdout=subprocess.DEVNULL)
  time.sleep(2)
  pid=adb('shell','pidof',PKG,capture_output=True,text=True).stdout.strip()
  deadline=time.monotonic()+45
  while True:
   startup=adb('logcat','-d','--pid='+pid,'-s','godot',capture_output=True,text=True).stdout
   if 'AUTO_GAMEPLAY_STARTED' in startup:break
   if time.monotonic()>deadline:raise RuntimeError('No diagnostic startup')
   time.sleep(.5)
  # Run instrumentation on the phone, detached from the USB shell lifetime.
  touch_remote='/data/local/tmp/arena-projectile-multitouch.txt'
  adb('shell','nohup am instrument -w -e seconds 310 -e jx 281 -e jy 886 -e fx 2130 -e fy 884 -e radius 100 com.arenadash.qa/.TouchRunner > '+touch_remote+' 2>&1 < /dev/null &')
  start=time.monotonic();segment=1
  adb('shell','nohup screenrecord --time-limit 180 /sdcard/arena-projectile-soak-1.mp4 > /data/local/tmp/arena-soak-record-1.txt 2>&1 < /dev/null &')
  snapshots=[]
  for sample in range(11):
   until=start+sample*30
   while time.monotonic()<until:time.sleep(min(1,until-time.monotonic()))
   current=adb('shell','pidof',PKG,capture_output=True,text=True).stdout.strip()
   if current!=pid:raise RuntimeError('Game process exited/restarted')
   if sample==6:
    segment=2
    adb('shell','nohup screenrecord --time-limit 140 /sdcard/arena-projectile-soak-2.mp4 > /data/local/tmp/arena-soak-record-2.txt 2>&1 < /dev/null &')
   with (OUT/('frame-%03d.png'%(sample*30))).open('wb') as shot:adb('exec-out','screencap','-p',stdout=shot)
   snapshots.append({'elapsed':round(time.monotonic()-start,2),'pid':current})
   log.write(adb('logcat','-d','--pid='+pid,'-s','godot',capture_output=True,text=True).stdout);log.flush()
   print('PROJECTILE_SOAK elapsed='+str(round(time.monotonic()-start))+' pid='+pid,flush=True)
  while time.monotonic()-start<325:time.sleep(1)
  result=adb('shell','cat',touch_remote,capture_output=True,text=True).stdout
  (OUT/'multitouch.txt').write_text(result)
  if 'INSTRUMENTATION_CODE: -1' not in result:raise RuntimeError(result)
  for segment in [1,2]:adb('pull','/sdcard/arena-projectile-soak-'+str(segment)+'.mp4',str(OUT/('gameplay-'+str(segment)+'.mp4')),stdout=subprocess.DEVNULL)
  with (OUT/'projectile-trace.jsonl').open('wb') as trace:adb('exec-out','run-as',PKG,'cat','files/projectile_trace.jsonl',stdout=trace)
  log.write(adb('logcat','-d','--pid='+pid,'-s','godot','ArenaDashQA',capture_output=True,text=True).stdout)
  (OUT/'run.json').write_text(json.dumps({'elapsed_seconds':time.monotonic()-start,'snapshots':snapshots,'pid':pid,'input_success':True},indent=2))
  print('PROJECTILE_SOAK_COMPLETE',flush=True)
 finally:
  if runner and runner.poll() is None:runner.terminate()
  if record and record.poll() is None:record.terminate()
  logger.terminate();logger.wait()
adb('shell','am','force-stop',PKG)
adb('shell','run-as',PKG,'rm','files/movement_fire_qa.json')
