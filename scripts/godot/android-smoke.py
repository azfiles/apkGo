"""Exercise the actual release APK with real Android touch events on a disposable emulator."""
import pathlib
import io
import re
import subprocess
import sys
import time
from PIL import Image
from image_checks import validate_frame

PACKAGE = 'com.alex.schulteflow.godot'
OUT = pathlib.Path('build/godot')
SHOTS = OUT / 'screenshots'
SHOTS.mkdir(parents=True, exist_ok=True)
checks = []
current_pid = ''
marker_offset = 0


def adb(*args, **kwargs):
    return subprocess.check_output(['adb', *args], **kwargs)


def check(value, message):
    if not value:
        raise AssertionError(message)
    checks.append(message)
    print('PASS: ' + message, flush=True)


def markers():
    log = adb('logcat', '-d', '--pid=' + current_pid, '-s', 'godot:V', '*:S').decode(errors='replace')
    return re.findall(r'FLOW_SCREEN (\w+)', log)


def checkpoint():
    global marker_offset
    marker_offset = len(markers())


def screen(name):
    global marker_offset
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        states = markers()
        if name in states[marker_offset:]:
            marker_offset = len(states)
            check(True, 'screen ' + name)
            return
        time.sleep(.5)
    raise AssertionError('Missing screen ' + name + '; observed states: ' + str(states))


def tap(x, y, expected):
    checkpoint()
    adb('shell', 'input', 'tap', str(x), str(y))
    screen(expected)


def shot(name):
    deadline = time.monotonic() + 20
    while True:
        data = adb('exec-out', 'screencap', '-p')
        (SHOTS / (name + '.png')).write_bytes(data)
        if name == 'failure':
            return
        if validate_frame(Image.open(io.BytesIO(data)), name):
            check(True, 'rendered ' + name + ' screenshot')
            return
        if time.monotonic() >= deadline:
            raise AssertionError('Missing rendered game pixels in ' + name)
        time.sleep(.5)


def launch():
    global current_pid, marker_offset
    marker_offset = 0
    output = adb('shell', 'am', 'start', '-W', '-n', PACKAGE + '/com.godot.game.GodotAppLauncher').decode()
    check('Status: ok' in output, 'Android launches release activity')
    current_pid = adb('shell', 'pidof', PACKAGE).decode().strip().split()[0]
    screen('home')


try:
    adb('logcat', '-c')
    # Destructive only to this package on the dedicated CI emulator.
    adb('shell', 'wm', 'size', '720x1280')
    adb('shell', 'wm', 'density', '240')
    adb('shell', 'settings', 'put', 'secure', 'immersive_mode_confirmations', 'confirmed')
    adb('shell', 'input', 'keyevent', '82')
    check('Success' in adb('install', '-r', 'build/godot/output/Schulte-Flow-Godot-2.0.0.apk').decode(), 'install release APK')
    adb('shell', 'pm', 'clear', PACKAGE)
    launch()
    shot('home')
    tap(360, 527, 'play')
    time.sleep(2)
    shot('play')
    tap(220, 1090, 'pause')
    shot('pause')
    tap(360, 715, 'play')
    tap(580, 1090, 'restart')
    tap(360, 820, 'play')
    tap(580, 1090, 'restart')
    tap(360, 710, 'play')
    # Android background event must hide the board and save before process death.
    checkpoint()
    adb('shell', 'input', 'keyevent', '3')
    screen('pause')
    adb('shell', 'am', 'force-stop', PACKAGE)
    launch()
    tap(360, 527, 'pause')
    shot('restored')
    tap(360, 715, 'play')
    check(bool(adb('shell', 'pidof', PACKAGE).strip()), 'release process remains alive')
    complete_log = adb('logcat', '-d').decode(errors='replace')
    check(not any(marker in complete_log for marker in ('SCRIPT ERROR:', 'FATAL EXCEPTION', 'Fatal signal')), 'no script error or crash in tested session')
    check(not re.search(r'\bE godot\s*: ERROR:', complete_log), 'no Godot renderer or engine errors')
    print('ANDROID: %d checks, 0 failures' % len(checks), flush=True)
except Exception:
    shot('failure')
    diagnostic = adb('logcat', '-d').decode(errors='replace')
    relevant = [line for line in diagnostic.splitlines() if any(term in line for term in
        ('godot', 'Godot', 'AndroidRuntime', 'FATAL', 'Fatal', 'ANR', 'EGL', 'GLES', 'OpenGL', current_pid))]
    print('\n'.join(relevant[-180:]), file=sys.stderr)
    raise
finally:
    (OUT / 'logcat.txt').write_bytes(adb('logcat', '-d'))
