"""Regenerate the bundled SC font subset after changing game copy (fontTools required)."""
import pathlib
import sys
from fontTools import subset

root = pathlib.Path(__file__).resolve().parents[2]
text = ''.join(p.read_text() for p in (root / 'godot/scripts').glob('*.gd'))
text += ''.join(chr(n) for n in range(32, 127))
options = subset.Options()
options.font_number = 2  # Noto Sans CJK SC in the official regional TTC collection.
font = subset.load_font(sys.argv[1], options)
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
subset.save_font(font, str(root / 'godot/assets/flow-font.otf'), options)
