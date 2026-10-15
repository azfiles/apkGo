"""Exercise the actual release APK with real Android touch events on a disposable emulator."""
import pathlib
import subprocess
import time

PACKAGE = 'com.alex.schulteflow.godot'
OUT = pathlib.Path('build/godot')
SHOTS = OUT / 'screenshots'
SHOTS.mkdir(parents=True, exist_ok=True)
checks = []
log_segments = []


def adb(*args, **kwargs):
    return subprocess.check_output(['adb', *args], **kwargs)


def check(value, message):
    if not value:
        raise AssertionError(message)
    checks.append(message)
    print('PASS: ' + message, flush=True)


def screen(name):
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        log = adb('logcat', '-d', '-s', 'godot:V', '*:S').decode(errors='replace')
        if 'FLOW_SCREEN ' + name in log:
            check(True, 'screen ' + name)
            return
        time.sleep(.5)
    raise AssertionError('Missing screen ' + name + '\n' + log[-5000:])


def tap(x, y, expected):
    clear_logs()
    adb('shell', 'input', 'tap', str(x), str(y))
    screen(expected)


def shot(name):
    (SHOTS / (name + '.png')).write_bytes(adb('exec-out', 'screencap', '-p'))


def launch():
    clear_logs()
    output = adb('shell', 'am', 'start', '-W', '-n', PACKAGE + '/com.godot.game.GodotAppLauncher').decode()
    check('Status: ok' in output, 'Android launches release activity')
    screen('home')


def clear_logs():
    log_segments.append(adb('logcat', '-d').decode(errors='replace'))
    adb('logcat', '-c')


try:
    adb('logcat', '-c')
    # Destructive only to this package on the dedicated CI emulator.
    adb('shell', 'wm', 'size', '720x1280')
    adb('shell', 'wm', 'density', '240')
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
    clear_logs()
    adb('shell', 'input', 'keyevent', '3')
    screen('pause')
    adb('shell', 'am', 'force-stop', PACKAGE)
    launch()
    tap(360, 527, 'pause')
    shot('restored')
    tap(360, 715, 'play')
    check(bool(adb('shell', 'pidof', PACKAGE).strip()), 'release process remains alive')
    clear_logs()
    complete_log = '\n'.join(log_segments)
    check(not any(marker in complete_log for marker in ('SCRIPT ERROR:', 'FATAL EXCEPTION', 'Fatal signal')), 'no script error or crash in tested session')
    print('ANDROID: %d checks, 0 failures' % len(checks), flush=True)
finally:
    log_segments.append(adb('logcat', '-d').decode(errors='replace'))
    (OUT / 'logcat.txt').write_text('\n'.join(log_segments))
