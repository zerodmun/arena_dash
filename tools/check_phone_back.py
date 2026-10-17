#!/usr/bin/env python3
"""Manual QA helper: inject one Android input, then capture its visible outcome."""
import subprocess,sys,time
from pathlib import Path
out=Path(__file__).resolve().parent.parent/'qa/back-navigation'
out.mkdir(parents=True,exist_ok=True)
name,*action=sys.argv[1:]
if action==['double-swipe']:
    time.sleep(2.1)
    # Reveal Android's transient bars before delivering two actual Back gestures.
    subprocess.run(['adb','shell','input','swipe','2338','540','1850','540','180'],check=True)
    time.sleep(.25)
    subprocess.run(['adb','shell','input','swipe','2338','540','1850','540','180'],check=True)
    time.sleep(.15)
    with (out/(name+'-warning.png')).open('wb') as f:subprocess.run(['adb','exec-out','screencap','-p'],stdout=f,check=True)
    subprocess.run(['adb','shell','input','swipe','2338','540','1850','540','180'],check=True)
    action=[]
if action: subprocess.run(['adb','shell','input',*action],check=True)
time.sleep(.65)
with (out/(name+'.png')).open('wb') as f:subprocess.run(['adb','exec-out','screencap','-p'],stdout=f,check=True)
print(name,subprocess.run(['adb','shell','pidof','com.example.arenadash'],capture_output=True,text=True).stdout.strip())
