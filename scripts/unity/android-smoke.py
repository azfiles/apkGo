#!/usr/bin/env python3
"""Drive the shipped Unity UI on an x86_64 Android emulator; no game-state cheats."""
import json
import base64
import io
import subprocess
import time
from pathlib import Path

APP = 'com.alex.pipimaze.unitypreview'
OUT = Path('build/unity-smoke')
OUT.mkdir(parents=True, exist_ok=True)


def adb(*args, binary=False):
    return subprocess.check_output(['adb', *map(str, args)], text=not binary)


def logs():
    return adb('logcat', '-d', '-v', 'brief', 'Unity:I', 'AndroidRuntime:E', '*:S')


def expect(event, timeout=35):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        text = logs()
        if 'FATAL EXCEPTION' in text or 'NullReferenceException' in text or 'InvalidOperationException' in text:
            raise AssertionError('Runtime exception; see android-log.txt')
        if event in text:
            return
        time.sleep(.4)
    raise AssertionError('Missing runtime event: ' + event)


def tap(x, y):
    adb('shell', 'input', 'tap', x, y)
    time.sleep(.5)


def shot(name):
    from PIL import Image, ImageStat
    path = OUT / (name + '.png')
    deadline = time.monotonic() + 75
    while time.monotonic() < deadline:
        path.write_bytes(adb('exec-out', 'screencap', '-p', binary=True))
        with Image.open(path) as img:
            if img.size == (1280, 720) and sum(ImageStat.Stat(img.convert('RGB')).stddev) > 25:
                print('PASS: rendered landscape frame ' + name, flush=True)
                return
        time.sleep(1)
    raise AssertionError('Missing nonblank 1280x720 Unity frame: ' + name)


def log_preview(path):
    from PIL import Image
    with Image.open(path) as source:
        source.thumbnail((800, 450))
        buffer = io.BytesIO()
        source.convert('RGB').save(buffer, format='PNG')
        print('PIPI_PREVIEW_FRAME:' + path.stem + ':' + base64.b64encode(buffer.getvalue()).decode(), flush=True)


def launch():
    component = adb('shell', 'cmd', 'package', 'resolve-activity', '--brief', '-a',
                    'android.intent.action.MAIN', '-c', 'android.intent.category.LAUNCHER', APP).strip().splitlines()[-1]
    assert component.startswith(APP + '/'), 'Missing Unity launcher activity: ' + component
    result = adb('shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN',
                 '-c', 'android.intent.category.LAUNCHER', '-f', '0x10200000', '-n', component)
    print(result, flush=True)
    assert 'Status: ok' in result and 'Error:' not in result, 'Android rejected Unity launch'


try:
    adb('install', '--no-incremental', '-r', 'build/unity-release/Pipi-Maze-Unity-0.1.0.apk')
    adb('shell', 'wm', 'size', '720x1280')
    adb('shell', 'wm', 'density', '240')
    adb('shell', 'settings', 'put', 'secure', 'immersive_mode_confirmations', 'confirmed')
    adb('shell', 'settings', 'put', 'system', 'accelerometer_rotation', '0')
    adb('shell', 'input', 'keyevent', '82')
    time.sleep(5)
    adb('logcat', '-c')
    launch()
    expect('PIPI_EVENT: WORLD_READY first_light', 90)
    expect('PIPI_EVENT: HOME', 90)
    time.sleep(3)
    shot('01-home')
    tap(250, 558)
    expect('PIPI_EVENT: PLAY')
    time.sleep(3)
    shot('02-first-light')
    tap(1165, 516)
    expect('PIPI_EVENT: JUMP')
    adb('shell', 'input', 'swipe', '143', '583', '143', '515', '4500')
    expect('PIPI_EVENT: MOVED')
    tap(900, 47)
    expect('PIPI_EVENT: HINT')
    tap(1032, 47)
    expect('PIPI_EVENT: MAP')
    shot('03-map-and-route')
    tap(1170, 47)
    expect('PIPI_EVENT: PAUSE')
    shot('04-pause')
    tap(640, 267)
    expect('PIPI_EVENT: RESUME')
    # Inspect each authored chapter using the same chapter buttons as the user.
    for index, chapter in enumerate(('echo_halls', 'sleeping_stars', 'starbridge_garden'), 1):
        tap(1170, 47)
        tap(640, 414)
        tap(260, 83 + 179 + index * 60 + 25)
        expect('PIPI_EVENT: WORLD_READY ' + chapter)
        time.sleep(1)
        tap(250, 558)
        time.sleep(3)
        shot('05-chapter-' + str(index + 1))
    # Process recreation must return to the selected chapter and reload its save.
    time.sleep(5)
    adb('shell', 'am', 'force-stop', APP)
    adb('logcat', '-c')
    launch()
    expect('PIPI_EVENT: WORLD_READY starbridge_garden', 60)
    expect('PIPI_EVENT: HOME')
    time.sleep(2)
    shot('06-relaunch')
    assert 'E/Unity' not in logs() and 'FATAL EXCEPTION' not in logs(), 'Unity runtime logged an error'
    (OUT / 'report.json').write_text(json.dumps(dict(result='PASS', checks=['launch', 'rendered landscape', 'play', 'jump', 'joystick movement', 'hint', 'map', 'pause/resume', 'four authored chapters', 'selected chapter after process recreation', 'no Unity runtime errors'], limitations=['ARM64 physical-device performance', 'full chapter completion', 'Godot save migration', 'multi-touch sprint+jump combination']), indent=2))
    print('PASS: Unity Android launch, visible frames, joystick, jump, hint, map, pause, four chapters and recreation')
finally:
    captured = logs()
    (OUT / 'android-log.txt').write_text(captured)
    print('PIPI_ANDROID_LOG_BEGIN\n' + captured + '\nPIPI_ANDROID_LOG_END', flush=True)
    last = OUT / 'last-frame.png'
    last.write_bytes(adb('exec-out', 'screencap', '-p', binary=True))
    for name in ('01-home', '02-first-light', '05-chapter-4', 'last-frame'):
        frame = OUT / (name + '.png')
        if frame.exists():
            log_preview(frame)
