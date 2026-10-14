package com.alex.schulteflow.smoke;
import android.app.*;import android.os.*;import android.content.*;import android.view.*;import android.widget.*;import android.graphics.Bitmap;import java.io.*;import java.lang.reflect.*;
public class SmokeInstrumentation extends Instrumentation {
 volatile Activity a;int checks;
 public void onCreate(Bundle b){super.onCreate(b);start();}
 void ui(Runnable r){final Throwable[] failure={null};runOnMainSync(()->{try{r.run();}catch(Throwable t){failure[0]=t;}});waitForIdleSync();if(failure[0]!=null)throw new AssertionError("UI operation",failure[0]);}
 View view(String tag){View v=a.getWindow().getDecorView().findViewWithTag(tag);try{Field f=a.getClass().getDeclaredField("dialog");f.setAccessible(true);Dialog d=(Dialog)f.get(a);if(d!=null&&d.isShowing()){View x=d.getWindow().getDecorView().findViewWithTag(tag);if(x!=null)v=x;}}catch(Exception e){throw new RuntimeException(e);}return v;}
 void check(boolean ok,String m){checks++;if(!ok)throw new AssertionError(m);}
 void waitTag(String tag){long end=SystemClock.uptimeMillis()+6000;while(SystemClock.uptimeMillis()<end){final boolean[] found={false};ui(()->{View v=view(tag);found[0]=v!=null&&v.isShown();});if(found[0])return;SystemClock.sleep(80);}throw new AssertionError("missing "+tag);}
 void click(String tag){waitTag(tag);ui(()->{View v=view(tag);check(v.isEnabled(),tag+" enabled");if(v instanceof CompoundButton){boolean before=((CompoundButton)v).isChecked();v.performClick();check(((CompoundButton)v).isChecked()!=before,tag+" toggled");}else check(v.performClick(),tag+" click");});SystemClock.sleep(80);}
 String value(String tag){final String[] s={""};ui(()->s[0]=((TextView)view(tag)).getText().toString());return s[0];}
 void shot(String name)throws Exception{SystemClock.sleep(250);Bitmap b=getUiAutomation().takeScreenshot();check(b!=null,"screenshot");File dir=getTargetContext().getExternalFilesDir(null);try(FileOutputStream out=new FileOutputStream(new File(dir,name+".png"))){b.compress(Bitmap.CompressFormat.PNG,100,out);}b.recycle();}
 void realTap(String tag){waitTag(tag);final float[] xy=new float[2];ui(()->{View v=view(tag);int[] p=new int[2];v.getLocationOnScreen(p);xy[0]=p[0]+v.getWidth()/2f;xy[1]=p[1]+v.getHeight()/2f;check(v.getWidth()>0&&v.getHeight()>0,"tile measured");});long t=SystemClock.uptimeMillis();MotionEvent down=MotionEvent.obtain(t,t,MotionEvent.ACTION_DOWN,xy[0],xy[1],0),up=MotionEvent.obtain(t,t+60,MotionEvent.ACTION_UP,xy[0],xy[1],0);down.setSource(InputDevice.SOURCE_TOUCHSCREEN);up.setSource(InputDevice.SOURCE_TOUCHSCREEN);check(getUiAutomation().injectInputEvent(down,true),"touch down");check(getUiAutomation().injectInputEvent(up,true),"touch up");down.recycle();up.recycle();waitForIdleSync();SystemClock.sleep(100);}
 public void onStart(){Bundle result=new Bundle();try{
 getTargetContext().getSharedPreferences("schulte_flow",0).edit().clear().commit();Intent launch=new Intent().setClassName("com.alex.schulteflow","com.alex.schulteflow.MainActivity").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);a=startActivitySync(launch);waitTag("start");shot("01-home");
 click("settings");click("sound_toggle");click("haptic_toggle");click("settings_close");check(!getTargetContext().getSharedPreferences("schulte_flow",0).getBoolean("sound",true),"sound preference");
 for(int size=3;size<=5;size++){
 click("mode"+size);click("start");waitTag("pause");check(value("target").equals("01"),"initial target");realTap("tile_2");check(value("target").equals("01"),"wrong tap does not advance");realTap("tile_1");check(value("target").equals("02"),"real touch advances");
 if(size==3){shot("02-playing");click("pause");String frozen=value("timer");SystemClock.sleep(300);check(value("timer").equals(frozen),"pause freezes clock");shot("03-paused");click("restart");click("cancel_restart");click("resume");
 ui(()->a.recreate());SystemClock.sleep(600);waitTag("resume");check(value("target").equals("02"),"recreation preserves progress");click("resume");
 }
 for(int n=2;n<=size*size;n++)click("tile_"+n);waitTag("result_time");check(getTargetContext().getSharedPreferences("schulte_flow",0).getLong("best_"+size,0)>0,"best persisted");shot("result-"+size);click("result_close");
 }
 result.putString("stream","TOTAL "+checks+" UI CHECKS PASS\n");finish(-1,result);
 }catch(Throwable e){StringWriter s=new StringWriter();e.printStackTrace(new PrintWriter(s));result.putString("stream","FAIL "+s);finish(0,result);}}
 @Override public void callActivityOnResume(Activity activity){super.callActivityOnResume(activity);a=activity;}
}
