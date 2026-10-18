"""Smoke test the signed release APK with actual Android input and captured frames."""
import io,os,subprocess,time,re
from pathlib import Path
from PIL import Image,ImageChops,ImageStat
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/maze3d/android';OUT.mkdir(parents=True,exist_ok=True)
ADB=os.environ.get('ADB','adb');PACKAGE='com.alex.pipimaze.ruins'
checks=[];offset=0

def adb(*args,timeout=90):return subprocess.check_output([ADB,*args],timeout=timeout,stderr=subprocess.STDOUT)
def check(ok,label):
    assert ok,label
    checks.append(label);print('PASS: '+label,flush=True)
def logs():return adb('logcat','-d','-s','godot:V','AndroidRuntime:E','*:S').decode(errors='replace')
def checkpoint():
    global offset
    offset=len(re.findall(r'PIPI_PAGE (\w+)',logs()))
def process_id():
    try:return adb('shell','pidof',PACKAGE).strip()
    except subprocess.CalledProcessError:return b''
def launch(label,cold=False):
    previous=process_id()
    if cold:
        adb('shell','am','force-stop',PACKAGE)
        until=time.monotonic()+15
        while process_id() and time.monotonic()<until:time.sleep(.25)
        check(not process_id(),'previous Android process fully stopped')
    checkpoint()
    # Use the same explicit MAIN/LAUNCHER intent and task flags as the launcher.
    # Capture am's result: a successful adb command alone does not mean Android
    # actually accepted an activity launch after a background/force-stop cycle.
    result=adb('shell','am','start','-W','-a','android.intent.action.MAIN',
               '-c','android.intent.category.LAUNCHER','-f','0x10200000',
               '-n',PACKAGE+'/com.godot.game.GodotAppLauncher').decode(errors='replace')
    with (OUT/'launches.txt').open('a') as report:report.write(label+'\n'+result+'\n')
    print(result,flush=True)
    check('Status: ok' in result and 'Error:' not in result,label)
    page('home')
    current=process_id()
    check(bool(current) and (not cold or current!=previous),'fresh Android process' if cold else 'Android process started')
def page(expected,timeout=120):
    global offset
    until=time.monotonic()+timeout
    while time.monotonic()<until:
        states=re.findall(r'PIPI_PAGE (\w+)',logs())
        if expected in states[offset:]:
            offset=len(states);check(True,'Android UI state '+expected);return
        time.sleep(1)
    raise AssertionError('State missing: '+expected+'; last states: '+str(states[-10:]))
def tap(x,y,expected=None):
    checkpoint();adb('shell','input','tap',str(x),str(y))
    if expected:page(expected)
def shot(name):
    until=time.monotonic()+90
    while time.monotonic()<until:
        time.sleep(2)
        data=adb('exec-out','screencap','-p');p=OUT/(name+'.png');p.write_bytes(data)
        im=Image.open(io.BytesIO(data)).convert('RGB')
        colors=im.resize((160,90)).getcolors(20000)
        if im.size==(1280,720) and colors and len(colors)>300:
            check(True,'landscape rendered 3D frame '+name)
            return im
    raise AssertionError('Missing 1280x720 rendered game frame: '+name)

def run():
    adb('wait-for-device');check(adb('shell','getprop','sys.boot_completed').strip()==b'1','Android boot complete')
    adb('shell','wm','size','720x1280');adb('shell','wm','density','240')
    adb('shell','settings','put','secure','immersive_mode_confirmations','confirmed')
    adb('shell','settings','put','system','accelerometer_rotation','0')
    adb('shell','input','keyevent','82')
    apk=ROOT/'build/maze3d/output/Pipi-Maze-Ruins-0.4.0.apk'
    check(b'Success' in adb('install','--no-incremental','-r',str(apk),timeout=180),'install signed APK')
    adb('shell','pm','clear',PACKAGE);adb('logcat','-c');checkpoint()
    launch('release activity starts');shot('01-home')
    tap(1130,425);shot('01a-expression')
    adb('shell','input','swipe','800','290','1000','320','600');shot('01b-character-side')
    tap(1130,480) # Restore front view after inspecting the new model.
    tap(207,513,'play');initial=shot('02-play')
    adb('shell','input','swipe','155','565','155','465','1800')
    moved=shot('03-moved')
    diff=ImageStat.Stat(ImageChops.difference(initial.crop((260,180,960,560)),moved.crop((260,180,960,560)))).mean
    check(sum(diff)>15,'touch joystick moves rendered camera and character')
    adb('shell','input','swipe','790','340','1000','370','600');shot('04-orbit')
    tap(1052,612) # hint
    tap(1182,170,'map');shot('05-map')
    tap(1120,63,'play')
    tap(1224,46,'pause');shot('06-pause')
    tap(745,335,'pause') # low quality toggle
    tap(625,263,'play')
    checkpoint();adb('shell','input','keyevent','4');page('pause')
    tap(625,263,'play')
    checkpoint();adb('shell','input','keyevent','3');page('pause')
    launch('release cold restart after background',cold=True)
    tap(207,513,'play');shot('07-restored')
    check(bool(adb('shell','pidof',PACKAGE).strip()),'release process remains alive')
    captured=logs()
    check(not any(term in captured for term in ['SCRIPT ERROR','FATAL EXCEPTION','Fatal signal','ERROR:']),'no Godot/Android errors or crashes')
    print('ANDROID: %d checks, 0 failures'%len(checks),flush=True)
try:run()
finally:
    (OUT/'logcat.txt').write_text(logs())
    (OUT/'system-logcat.txt').write_bytes(adb('logcat','-d','-v','threadtime'))
    (OUT/'activities.txt').write_bytes(adb('shell','dumpsys','activity','activities'))
    (OUT/'last-frame.png').write_bytes(adb('exec-out','screencap','-p'))
