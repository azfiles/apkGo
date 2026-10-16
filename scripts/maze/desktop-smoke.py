"""Exercise the exported executable using real X11 events; run under Xvfb.

Requires Pillow, libX11 and libXtst. No game test hooks are used.
"""
import ctypes as c
import os
from pathlib import Path
import subprocess
import shutil
import time
from PIL import ImageGrab

root = Path(__file__).resolve().parents[2]
out = root / 'build/maze/desktop-smoke'
out.mkdir(parents=True, exist_ok=True)
display_name = os.environ.get('DISPLAY', ':91')
x = c.CDLL('libX11.so.6')
xt = c.CDLL('libXtst.so.6')
ptr, ulong = c.c_void_p, c.c_ulong
x.XOpenDisplay.argtypes = [c.c_char_p]
x.XOpenDisplay.restype = ptr
x.XDefaultRootWindow.argtypes = [ptr]
x.XDefaultRootWindow.restype = ulong
x.XQueryTree.argtypes = [ptr, ulong, c.POINTER(ulong), c.POINTER(ulong), c.POINTER(c.POINTER(ulong)), c.POINTER(c.c_uint)]
x.XFetchName.argtypes = [ptr, ulong, c.POINTER(c.c_char_p)]
x.XFree.argtypes = [ptr]
x.XSetInputFocus.argtypes = [ptr, ulong, c.c_int, ulong]
x.XRaiseWindow.argtypes = [ptr, ulong]
x.XFlush.argtypes = [ptr]
x.XStringToKeysym.argtypes = [c.c_char_p]
x.XStringToKeysym.restype = ulong
x.XKeysymToKeycode.argtypes = [ptr, ulong]
x.XKeysymToKeycode.restype = c.c_uint
xt.XTestFakeMotionEvent.argtypes = [ptr, c.c_int, c.c_int, c.c_int, ulong]
xt.XTestFakeButtonEvent.argtypes = [ptr, c.c_uint, c.c_int, ulong]
xt.XTestFakeKeyEvent.argtypes = [ptr, c.c_uint, c.c_int, ulong]
display = x.XOpenDisplay(display_name.encode())
if not display:
    raise RuntimeError('Start Xvfb and set DISPLAY before running this smoke test')


def window():
    rr, parent, children, count = ulong(), ulong(), c.POINTER(ulong)(), c.c_uint()
    x.XQueryTree(display, x.XDefaultRootWindow(display), c.byref(rr), c.byref(parent), c.byref(children), c.byref(count))
    result = None
    for i in range(count.value):
        title = c.c_char_p()
        if x.XFetchName(display, children[i], c.byref(title)) and title.value:
            if b'Pipi Maze' in title.value:
                result = children[i]
            x.XFree(title)
    if children:
        x.XFree(children)
    return result


def click(px, py):
    xt.XTestFakeMotionEvent(display, 0, px, py, 0)
    xt.XTestFakeButtonEvent(display, 1, 1, 0)
    x.XFlush(display)
    time.sleep(.1)
    xt.XTestFakeButtonEvent(display, 1, 0, 0)
    x.XFlush(display)
    time.sleep(.35)


def key(name):
    x.XSetInputFocus(display, target, 2, 0)
    code = x.XKeysymToKeycode(display, x.XStringToKeysym(name.encode()))
    xt.XTestFakeKeyEvent(display, code, 1, 0)
    x.XFlush(display)
    time.sleep(.1)
    xt.XTestFakeKeyEvent(display, code, 0, 0)
    x.XFlush(display)
    time.sleep(.35)


def capture(name=None):
    result = ImageGrab.grab(xdisplay=display_name)
    if name:
        result.save(out / f'{name}.png')
    return result


def corner(image):
    return sum(image.getpixel((20, 20))[:3])


def wait_for(predicate, message, timeout=10):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        image = capture()
        if predicate(image):
            return image
        time.sleep(.15)
    raise AssertionError(message)


env = os.environ.copy()
shutil.rmtree(out / 'userdata', ignore_errors=True)
env['XDG_DATA_HOME'] = str(out / 'userdata')
env['LIBGL_ALWAYS_SOFTWARE'] = '1'
checks = 0
with (out / 'runtime-report.txt').open('w') as log:
    process = subprocess.Popen([str(root / 'build/maze/output/Pipi-Maze-Garden.x86_64'), '--audio-driver', 'Dummy', '--position', '0,0'], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        target = None
        for _ in range(60):
            target = window()
            if target:
                break
            assert process.poll() is None, 'exported game exited during startup'
            time.sleep(.2)
        assert target, 'exported game window did not appear'
        checks += 1
        x.XRaiseWindow(display, target)
        x.XSetInputFocus(display, target, 2, 0)
        x.XFlush(display)
        wait_for(lambda im: corner(im) > 650 and sum(im.getpixel((60, 645))[:3]) < 400, 'home controls rendered')
        home = capture('01-home')
        baseline = corner(home)
        assert baseline > 650, 'home background rendered'
        checks += 1
        click(183, 650)
        wait_for(lambda im: sum(im.getpixel((1115, 470))[:3]) > baseline + 10, 'start displayed direction controls')
        key('Escape')
        wait_for(lambda im: corner(im) < baseline * .8, 'pause overlay rendered')
        paused = capture('02-paused')
        assert corner(paused) < baseline * .8, 'Escape opened the blocking pause overlay'
        checks += 1
        click(640, 518)
        wait_for(lambda im: corner(im) > baseline * .9, 'resume closed overlay')
        assert corner(capture()) > baseline * .9, 'resume button closed the overlay'
        checks += 1
        key('h')
        capture('03-play')
        click(816, 573)  # First garden goal: projected center of the far end tile.
        print('DESKTOP: launched export, exercised pause/resume, walking to koala...', flush=True)
        for _ in range(60):
            time.sleep(.4)
            if corner(capture()) < baseline * .8:
                break
        time.sleep(.6)
        result = capture('04-complete')
        assert corner(result) < baseline * .8, 'actual click navigation reached the result overlay'
        assert sum(result.getpixel((400, 200))[:3]) > 650, 'result card rendered'
        checks += 2
        click(640, 518)
        time.sleep(.5)
        assert corner(capture('05-next-garden')) > baseline * .9, 'next chapter button opened another garden'
        checks += 1
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
log_text = (out / 'runtime-report.txt').read_text()
assert 'SCRIPT ERROR' not in log_text and 'ERROR:' not in log_text, log_text
checks += 1
print(f'DESKTOP: {checks} checks, 0 failures')
