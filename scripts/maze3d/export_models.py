"""Export hand-edited Blender roots using the same asset catalog as the game.

blender --background --python scripts/maze3d/export_models.py -- --asset garden_bridge
Repeat --asset to batch export. The .blend source is opened, never overwritten.
"""
import argparse
import json
import sys
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--asset", action="append", required=True, help="Stable model_catalog.json asset ID")
parser.add_argument("--output-dir", type=Path, default=ROOT / "maze3d/assets/models")
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
catalog = json.loads((ROOT / "maze3d/assets/model_catalog.json").read_text())["assets"]
unknown = set(args.asset) - catalog.keys()
if unknown:
    raise ValueError(f"Unknown asset IDs: {sorted(unknown)}")
args.output_dir.mkdir(parents=True, exist_ok=True)
opened = None
for id in args.asset:
    entry = catalog[id]
    source = ROOT / entry["source"]
    if source != opened:
        bpy.ops.wm.open_mainfile(filepath=str(source))
        opened = source
    root = bpy.data.objects.get(entry["source_root"])
    if root is None:
        raise ValueError(f"{source.name}: missing root {entry['source_root']} for {id}")
    nodes = [root, *root.children_recursive]
    # The source library spaces modules apart for editing. That display offset
    # must never move a runtime asset away from its authored local origin.
    original_position = root.location.copy()
    original_hidden = {node: node.hide_get() for node in nodes}
    root.location = (0, 0, 0)
    bpy.ops.object.select_all(action="DESELECT")
    for node in nodes:
        node.hide_set(False)
        node.select_set(True)
    bpy.context.view_layer.update()
    if id == "brown":
        missing = set(entry["animation_nodes"]) - {node.name for node in nodes}
        if missing:
            raise ValueError(f"Brown animation pivots were renamed: {sorted(missing)}")
    bpy.ops.export_scene.gltf(filepath=str(args.output_dir / Path(entry["path"]).name),
                              export_format="GLB", use_selection=True,
                              export_yup=True, export_apply=True)
    root.location = original_position
    for node, hidden in original_hidden.items():
        node.hide_set(hidden)
    print(f"EXPORTED: {id} from {source.name}:{root.name}")
