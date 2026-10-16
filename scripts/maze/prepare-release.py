"""Collect the tested builds, source, screenshots and evidence for GitHub Release."""
from pathlib import Path
import hashlib
import shutil
import tarfile
import zipfile

root = Path(__file__).resolve().parents[2]
build = root / 'build/maze'
release = build / 'release'
release.mkdir(parents=True, exist_ok=True)
names = [
    'Pipi-Maze-Garden-0.1.0.apk',
    'Pipi-Maze-Garden-0.1.0-source.zip',
    'Pipi-Maze-Garden-0.1.0-linux.zip',
    'README.txt',
]
for name in names:
    source = build / 'output' / name
    if name.endswith('.zip'):
        with zipfile.ZipFile(source) as archive:
            assert archive.testzip() is None, f'Corrupt archive: {name}'
    shutil.copyfile(source, release / name)

for name in ['01-home.png', '02-play.png']:
    source = build / 'screenshots' / name
    if not source.exists():
        source = root / 'docs/maze/screenshots' / name
    shutil.copyfile(source, release / name)
    names.append(name)

reports = ['model-report.txt', 'scene-report.txt', 'desktop-report.txt',
           'capture-report.txt', 'apk-report.txt',
           'export-Android-report.txt', 'export-Linux-report.txt']
for name, prefix in [('model-report.txt', 'MODEL:'), ('scene-report.txt', 'SCENE:'), ('desktop-report.txt', 'DESKTOP:')]:
    lines = (build / name).read_text().splitlines()
    assert any(line.startswith(prefix) and line.endswith('checks, 0 failures') for line in lines), name
    assert not any('FAIL:' in line or 'SCRIPT ERROR' in line for line in lines), name

with tarfile.open(release / 'verification.tar.gz', 'w:gz') as archive:
    for name in reports:
        archive.add(build / name, arcname='reports/' + name)
    archive.add(root / 'docs/maze/VERIFICATION.md', arcname='VERIFICATION.md')
    screenshots = build / 'screenshots'
    if not screenshots.exists():
        screenshots = root / 'docs/maze/screenshots'
    archive.add(screenshots, arcname='screenshots')
    if (build / 'desktop-smoke/runtime-report.txt').exists():
        archive.add(build / 'desktop-smoke/runtime-report.txt', arcname='reports/desktop-runtime-report.txt')
    for path in sorted((build / 'desktop-smoke').glob('*.png')):
        archive.add(path, arcname='desktop-screenshots/' + path.name)
names.append('verification.tar.gz')

with (release / 'SHA256SUMS.txt').open('w') as report:
    for name in sorted(names):
        sha = hashlib.sha256()
        with (release / name).open('rb') as file:
            for chunk in iter(lambda: file.read(1024 * 1024), b''):
                sha.update(chunk)
        report.write(f'{sha.hexdigest()}  {name}\n')
        print(name, (release / name).stat().st_size)
