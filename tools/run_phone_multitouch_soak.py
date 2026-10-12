#!/usr/bin/env python3
"""Physical-phone evidence capture using a standalone Android UiAutomation helper."""
import argparse, hashlib, json, struct, subprocess, time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--seconds',type=int,default=610);p.add_argument('--output',type=Path,default=Path('qa/phone-qa/soak'));a=p.parse_args()
adb=str(Path.home()/'Library/Android/sdk/platform-tools/adb');command=[adb,'-s','13ff9514'];package='com.example.arenadash';a.output.mkdir(parents=True,exist_ok=True)
def run(*args):
 r=subprocess.run(command+list(args),capture_output=True,timeout=45);return r
for key in ['ro.product.model','ro.build.version.release','ro.build.version.sdk','ro.product.cpu.abi','ro.hardware.egl','ro.build.fingerprint']:
 with (a.output/'device.txt').open('ab') as f:f.write(key.encode()+b'='+run('shell','getprop',key).stdout)
for apk in ['qa/phone-qa/helper/multitouch-qa.apk','qa/arena_dash_touch_stability.apk']:
 r=run('install','--no-incremental','-r',apk);(a.output/(Path(apk).stem+'-install.txt')).write_bytes(r.stdout+r.stderr)
 if r.returncode:raise RuntimeError(r.stdout+r.stderr)
run('shell','am','force-stop','com.arenadash.qa')
run('shell','am','force-stop',package)
(a.output/'exit-before.txt').write_bytes(run('shell','dumpsys','activity','exit-info',package).stdout)
run('logcat','-c')
log=(a.output/'logcat.txt').open('wb');capture=subprocess.Popen(command+['logcat','-b','main','-b','system','-b','crash','-b','events','-v','threadtime','godot:V','Godot:V','ArenaDashQA:V','AndroidRuntime:E','DEBUG:V','libc:V','ActivityManager:I','ActivityTaskManager:I','am_crash:I','am_anr:I','am_kill:I','am_proc_died:I','*:E'],stdout=log,stderr=log)
helper=None;records=[];pid='';reason='interrupted';start=time.monotonic()
try:
 launch=run('shell','monkey','-p',package,'-c','android.intent.category.LAUNCHER','1');(a.output/'launch.txt').write_bytes(launch.stdout+launch.stderr)
 for _ in range(45):
  if 'AUTO_GAMEPLAY_STARTED' in (a.output/'logcat.txt').read_text(errors='replace'):break
  time.sleep(1)
 else:raise RuntimeError('Auto gameplay did not start')
 shot=run('exec-out','screencap','-p').stdout;(a.output/'start.png').write_bytes(shot)
 width,height=struct.unpack('>II',shot[16:24]);assert width>height,(width,height)
 pid=run('shell','pidof',package).stdout.decode().strip();assert pid
 # Default controls resolve to 12%/91% horizontally and 82% vertically.
 output=(a.output/'multitouch.txt').open('wb')
 helper=subprocess.Popen(command+['shell','am','instrument','-w','-e','seconds',str(a.seconds),'-e','jx',str(width*.12),'-e','jy',str(height*.82),'-e','fx',str(width*.91),'-e','fy',str(height*.82),'-e','radius',str(height*.07),'com.arenadash.qa/.TouchRunner'],stdout=output,stderr=output)
 start=time.monotonic();print('SOAK_STARTED pid='+pid+' screen='+str((width,height)),flush=True)
 while time.monotonic()-start<a.seconds+5:
  elapsed=time.monotonic()-start;status=run('shell','pidof',package);current=status.stdout.decode().strip()
  if status.stderr.strip():
   records.append({'elapsed':round(elapsed,2),'adb_error':status.stderr.decode(errors='replace')});reason='adb_connection_interrupted';break
  records.append({'elapsed':round(elapsed,2),'pid':current})
  if current!=pid:reason='process_exit_or_restart';break
  if capture.poll() is not None:reason='logcat_failed_'+str(capture.returncode);break
  if len(records)%3==1:
   (a.output/('screen-%04d.png'%elapsed)).write_bytes(run('exec-out','screencap','-p').stdout)
   (a.output/('memory-%04d.txt'%elapsed)).write_bytes(run('shell','dumpsys','meminfo',package).stdout)
   print('SOAK elapsed='+str(round(elapsed))+' pid='+current,flush=True)
  time.sleep(10)
 else:reason='duration_reached'
 if helper is not None:helper.wait(timeout=20);output.close()
finally:
 if helper is not None and helper.poll() is None:helper.terminate()
 capture.terminate();capture.wait(timeout=10);log.close()
 (a.output/'exit-after.txt').write_bytes(run('shell','dumpsys','activity','exit-info',package).stdout)
 (a.output/'thermal.txt').write_bytes(run('shell','dumpsys','thermalservice').stdout)
 text=(a.output/'logcat.txt').read_text(errors='replace');metrics=[]
 for line in text.splitlines():
  if ' I godot' in line and 'PERF {' in line:
   try:metrics.append(json.loads(line.split('PERF ',1)[1]))
   except ValueError:pass
 touch=(a.output/'multitouch.txt').read_text(errors='replace') if (a.output/'multitouch.txt').exists() else ''
 active=[m for m in metrics if m.get('game_running') and not m.get('paused')]
 simultaneous=[m for m in active if m.get('controls',{}).get('fire_pressed') and m.get('controls',{}).get('joystick_pressed')]
 faults=[line for line in text.splitlines() if any(term in line for term in ['Fatal signal','FATAL EXCEPTION','ANR in com.example.arenadash','SCRIPT ERROR:'])]
 result={'reason':reason,'elapsed_seconds':round(time.monotonic()-start,2),'initial_pid':pid,'samples':records,'perf_samples':len(metrics),'active_samples':len(active),'simultaneous_input_samples':len(simultaneous),'max_mission_elapsed':max([m.get('mission_elapsed',0) for m in active],default=0),'fault_markers':faults,'helper_result':touch,'apk_sha256':hashlib.sha256(Path('qa/arena_dash_touch_stability.apk').read_bytes()).hexdigest()}
 result['passed']=reason=='duration_reached' and result['max_mission_elapsed']>=600 and len(simultaneous)>90 and not faults and 'INSTRUMENTATION_CODE: -1' in touch
 (a.output/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps({k:v for k,v in result.items() if k!='samples'}),flush=True)
