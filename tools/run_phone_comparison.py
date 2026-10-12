#!/usr/bin/env python3
"""Short coordinate-based physical UI comparison; does not certify a soak."""
import argparse,json,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('apk',type=Path);p.add_argument('--output',type=Path,required=True);p.add_argument('--attempts',type=int,default=3);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
adb=str(Path.home()/'Library/Android/sdk/platform-tools/adb');cmd=[adb,'-s','13ff9514'];package='com.example.arenadash'
def run(*args):return subprocess.run(cmd+list(args),capture_output=True,timeout=40)
def tap(x,y):run('shell','input','tap',str(x),str(y));time.sleep(2)
def screenshot(name):(a.output/(name+'.png')).write_bytes(run('exec-out','screencap','-p').stdout)
run('shell','am','force-stop','com.arenadash.qa');run('shell','am','force-stop',package)
r=run('install','--no-incremental','-r',str(a.apk));(a.output/'install.txt').write_bytes(r.stdout+r.stderr);assert r.returncode==0
run('logcat','-c');log=(a.output/'logcat.txt').open('wb');capture=subprocess.Popen(cmd+['logcat','-b','main','-b','system','-b','crash','-b','events','-v','threadtime','godot:V','ArenaDashQA:V','AndroidRuntime:E','DEBUG:V','libc:V','ActivityManager:I','ActivityTaskManager:I','*:E'],stdout=log,stderr=log)
records=[];started=time.monotonic()
try:
 for attempt in range(a.attempts):
  run('shell','am','force-stop',package);run('shell','monkey','-p',package,'-c','android.intent.category.LAUNCHER','1');time.sleep(6);screenshot('home-'+str(attempt))
  tap(1800,500);screenshot('hangar-'+str(attempt));tap(2080,835);screenshot('mission-'+str(attempt))
  pid=run('shell','pidof',package).stdout.decode().strip();print('MISSION attempt='+str(attempt)+' pid='+pid,flush=True)
  out=(a.output/('touch-'+str(attempt)+'.txt')).open('wb');helper=subprocess.Popen(cmd+['shell','am','instrument','-w','-e','seconds','20','-e','jx','280','-e','jy','885','-e','fx','2130','-e','fy','885','com.arenadash.qa/.TouchRunner'],stdout=out,stderr=out)
  for second in range(0,25,5):
   time.sleep(5);current=run('shell','pidof',package).stdout.decode().strip();records.append({'attempt':attempt,'second':second+5,'pid':current});screenshot('play-'+str(attempt)+'-'+str(second+5))
   if not current or current!=pid:break
  helper.wait(timeout=15);out.close()
  if not current or current!=pid:break
finally:
 capture.terminate();capture.wait(timeout=5);log.close();(a.output/'exit-info.txt').write_bytes(run('shell','dumpsys','activity','exit-info',package).stdout)
 text=(a.output/'logcat.txt').read_text(errors='replace');faults=[line for line in text.splitlines() if any(t in line for t in ['Fatal signal','FATAL EXCEPTION','ANR in com.example.arenadash','SCRIPT ERROR:'])]
 result={'apk':str(a.apk),'elapsed_seconds':round(time.monotonic()-started,2),'process_samples':records,'fault_markers':faults,'capture_exit_code':capture.returncode};(a.output/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result),flush=True)
