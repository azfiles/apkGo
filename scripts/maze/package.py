"""Package the standalone project and Linux build; refresh artifact hashes."""
from pathlib import Path
import hashlib
import zipfile

root = Path(__file__).resolve().parents[2]
out = root / 'build/maze/output'
out.mkdir(parents=True, exist_ok=True)
notice = '''Pipi Maze · 花园捉迷藏 0.1.0

Android: 安装 Pipi-Maze-Garden-0.1.0.apk，Android 7.0+ / OpenGL ES 3.0。
Linux: 解压后运行 ./Pipi-Maze-Garden.x86_64，必要时 chmod +x。
Godot 工程: 用 Godot 4.6.3 打开 maze-godot/project.godot，按 F5。

点击浅色路面可寻路；WASD / 方向键 / 方向盘移动。
H 提示；Esc / P 暂停。到达小考拉即可完成，三枚自然印记为可选探索。
游戏离线运行，探索记录保存在本机。

角色原图复用自 azfiles/pipi-maze，版权归原权利人。
非官方个人兴趣原型；完整出处与许可见工程 ASSET_SOURCES.md 和 assets/。
Android 包完成签名与包内容检查，尚未经过 Android 真机体验验证。
'''
(out / 'README.txt').write_text(notice)
source_name = 'Pipi-Maze-Garden-0.1.0-source.zip'
source_prefix = 'Pipi-Maze-Garden-0.1.0/'
with zipfile.ZipFile(out / source_name, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    archive.writestr(source_prefix + 'README.txt', notice)
    for directory in ['maze-godot', 'scripts/maze', 'docs/maze']:
        for path in sorted((root / directory).rglob('*')):
            if not path.is_file() or '.godot' in path.parts or '__pycache__' in path.parts:
                continue
            archive.write(path, source_prefix + str(path.relative_to(root)))
    for filename in ['signing/demo-signing.p12.base64', '.github/workflows/maze-godot.yml']:
        archive.write(root / filename, source_prefix + filename)
linux_name = 'Pipi-Maze-Garden-0.1.0-linux.zip'
with zipfile.ZipFile(out / linux_name, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    archive.write(out / 'Pipi-Maze-Garden.x86_64', 'Pipi-Maze-Garden/Pipi-Maze-Garden.x86_64')
    archive.writestr('Pipi-Maze-Garden/README.txt', notice)
    for filename in ['CREDITS.txt', 'FONT-LICENSE.txt', 'LATIN-FONT-LICENSE.txt', 'GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
        archive.write(root / 'maze-godot/assets' / filename, 'Pipi-Maze-Garden/licenses/' + filename)
names = ['Pipi-Maze-Garden-0.1.0.apk', 'Pipi-Maze-Garden.x86_64', source_name, linux_name]
with (out / 'SHA256SUMS.txt').open('w') as report:
    for name in names:
        sha = hashlib.sha256()
        with (out / name).open('rb') as file:
            for chunk in iter(lambda: file.read(1024 * 1024), b''):
                sha.update(chunk)
        digest = sha.hexdigest()
        report.write(f'{digest}  {name}\n')
        print(name, (out / name).stat().st_size, digest)
