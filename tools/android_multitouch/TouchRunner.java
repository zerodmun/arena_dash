package com.arenadash.qa;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;
import android.util.Log;

/** Standalone shell-launched test instrumentation; never part of the game APK. */
public final class TouchRunner extends Instrumentation {
 private Bundle args;
 private int events;
 private UiAutomation automation;
 public void onCreate(Bundle arguments) { super.onCreate(arguments); args=arguments; start(); }
 private float number(String key, float fallback) { return Float.parseFloat(args.getString(key, Float.toString(fallback))); }
 private void send(long down, int action, float[] xs, float[] ys) {
  MotionEvent.PointerProperties[] properties=new MotionEvent.PointerProperties[xs.length];
  MotionEvent.PointerCoords[] coordinates=new MotionEvent.PointerCoords[xs.length];
  for(int i=0;i<xs.length;i++) {
   properties[i]=new MotionEvent.PointerProperties(); properties[i].id=i; properties[i].toolType=MotionEvent.TOOL_TYPE_FINGER;
   coordinates[i]=new MotionEvent.PointerCoords(); coordinates[i].x=xs[i]; coordinates[i].y=ys[i]; coordinates[i].pressure=1; coordinates[i].size=0.1f;
  }
  MotionEvent event=MotionEvent.obtain(down,SystemClock.uptimeMillis(),action,xs.length,properties,coordinates,0,0,1,1,0,0,InputDevice.SOURCE_TOUCHSCREEN,0);
  boolean success=automation.injectInputEvent(event,false); event.recycle();
  if(!success) throw new IllegalStateException("Input injection rejected at event "+events);
  events++;
 }
 public void onStart() {
  Bundle result=new Bundle();
  try {
   automation=getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
   float x=number("jx",280), y=number("jy",880), fx=number("fx",2100), fy=number("fy",880), radius=number("radius",75);
   if (args.getString("mode", "soak").equals("matrix")) {
    String[] cases={"stationary_fire","move_only","left_fire","right_fire","up_fire","down_fire","diagonal_fire","rapid_fire"};
    long phaseMillis=(long)(number("case_seconds",5)*1000);
    long testStart=SystemClock.uptimeMillis();
    for(int c=0;c<cases.length;c++) {
     Log.i("ArenaDashQA","CASE_START "+cases[c]);
     long down=SystemClock.uptimeMillis(); boolean firing=c!=1;
     if(c==0) {
      send(down,MotionEvent.ACTION_DOWN,new float[]{fx},new float[]{fy});
      SystemClock.sleep(phaseMillis);
      send(down,MotionEvent.ACTION_UP,new float[]{fx},new float[]{fy});
      Log.i("ArenaDashQA","CASE_END "+cases[c]);SystemClock.sleep(300);continue;
     }
     send(down,MotionEvent.ACTION_DOWN,new float[]{x},new float[]{y});
     if(firing) send(down,MotionEvent.ACTION_POINTER_DOWN | (1<<MotionEvent.ACTION_POINTER_INDEX_SHIFT),new float[]{x,fx},new float[]{y,fy});
     for(int step=0;step<phaseMillis/50;step++) {
      float dx=0,dy=0;
      if(c==1 || c==6) {dx=radius*.707f;dy=-radius*.707f;}
      if(c==2)dx=-radius; if(c==3)dx=radius; if(c==4)dy=-radius; if(c==5)dy=radius;
      if(c==7) {double angle=(step/8)*Math.PI/2;dx=(float)Math.cos(angle)*radius;dy=(float)Math.sin(angle)*radius;}
      send(down,MotionEvent.ACTION_MOVE,firing?new float[]{x+dx,fx}:new float[]{x+dx},firing?new float[]{y+dy,fy}:new float[]{y+dy});
      SystemClock.sleep(50);
     }
     if(firing)send(down,MotionEvent.ACTION_POINTER_UP | (1<<MotionEvent.ACTION_POINTER_INDEX_SHIFT),new float[]{x,fx},new float[]{y,fy});
     send(down,MotionEvent.ACTION_UP,new float[]{x},new float[]{y});
     Log.i("ArenaDashQA","CASE_END "+cases[c]);SystemClock.sleep(300);
    }
    result.putInt("injected_events",events);result.putLong("elapsed_ms",SystemClock.uptimeMillis()-testStart);finish(-1,result);return;
   }
   long duration=(long)(number("seconds",20)*1000), start=SystemClock.uptimeMillis();
   while(SystemClock.uptimeMillis()-start<duration) {
    long down=SystemClock.uptimeMillis();
    send(down,MotionEvent.ACTION_DOWN,new float[]{x},new float[]{y});
    send(down,MotionEvent.ACTION_POINTER_DOWN | (1<<MotionEvent.ACTION_POINTER_INDEX_SHIFT),new float[]{x,fx},new float[]{y,fy});
    for(int step=0;step<120 && SystemClock.uptimeMillis()-start<duration;step++) {
     double angle=((SystemClock.uptimeMillis()-start)/3000.0)*2*Math.PI;
     send(down,MotionEvent.ACTION_MOVE,new float[]{x+(float)Math.cos(angle)*radius,fx},new float[]{y+(float)Math.sin(angle)*radius,fy});
     SystemClock.sleep(50);
    }
    send(down,MotionEvent.ACTION_POINTER_UP | (1<<MotionEvent.ACTION_POINTER_INDEX_SHIFT),new float[]{x,fx},new float[]{y,fy});
    send(down,MotionEvent.ACTION_UP,new float[]{x},new float[]{y});
    Log.i("ArenaDashQA","TOUCH_CYCLE events="+events+" elapsed_ms="+(SystemClock.uptimeMillis()-start));
   }
   result.putInt("injected_events",events); result.putLong("elapsed_ms",SystemClock.uptimeMillis()-start);
   Log.i("ArenaDashQA","TOUCH_COMPLETED events="+events+" elapsed_ms="+(SystemClock.uptimeMillis()-start));
   finish(-1,result);
  } catch(Throwable error) {
   // Release both contacts on failure whenever the automation connection survives.
   if(automation!=null) {
    MotionEvent cancel=MotionEvent.obtain(SystemClock.uptimeMillis(),SystemClock.uptimeMillis(),MotionEvent.ACTION_CANCEL,0,0,0);
    cancel.setSource(InputDevice.SOURCE_TOUCHSCREEN);
    try { automation.injectInputEvent(cancel,false); } catch(Throwable ignored) {}
    cancel.recycle();
   }
   Log.e("ArenaDashQA","Multitouch failed",error); result.putString("error",error.toString()); finish(0,result); }
 }
}
