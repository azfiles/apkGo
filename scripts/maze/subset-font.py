"""Subset local Noto Sans CJK SC for the Chinese game UI (fontTools required)."""
from pathlib import Path
import sys
from fontTools import subset

root = Path(__file__).resolve().parents[2] / 'maze-godot'
text = ''.join(p.read_text() for p in (root / 'scripts').glob('*.gd'))
text += (root / 'assets/levels.json').read_text()
text += ''.join(chr(i) for i in range(32, 127)) + '→←↑↓↗Ⅱ♪✧✓★☆'
for kind, source in [('font', 'Regular'), ('bold', 'Bold')]:
    options = subset.Options()
    options.font_number = 2
    source_path = Path(sys.argv[1] if len(sys.argv) > 1 else '/usr/share/fonts/opentype/noto') / f'NotoSansCJK-{source}.ttc'
    font = subset.load_font(str(source_path), options)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    subset.save_font(font, str(root / f'assets/garden-{kind}.otf'), options)
