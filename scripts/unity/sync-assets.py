#!/usr/bin/env python3
"""Reproduce Unity's import inputs from the current Godot game's authored data."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'unity/Assets/PipiMaze/Resources'


def cell(pair):
    return dict(x=pair[0], y=pair[1])


def sync():
    manifest = {}
    for path in (ROOT / 'maze3d/levels').glob('*.json'):
        if path.stem == 'index':
            continue
        original = json.loads(path.read_text())
        data = dict(original)
        for key in ('start', 'goal'):
            data[key] = cell(data[key])
        for key in ('beacons', 'motes'):
            data[key] = [cell(p) for p in data[key]]
        for item in data['challenges']:
            item['cell'], item['axis'] = cell(item['cell']), cell(item['axis'])
        for item in data['scenery']:
            item['position'] = dict(zip(('x', 'y', 'z'), item['position']))
        output = DEST / 'Levels' / path.name
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
        manifest[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    catalog = json.loads((ROOT / 'maze3d/assets/model_catalog.json').read_text())
    assets = []
    for name, definition in catalog['assets'].items():
        entry = dict(name=name, colliders=[])
        for collider in definition['colliders']:
            entry['colliders'].append({k: dict(zip(('x', 'y', 'z'), v)) for k, v in collider.items()})
        assets.append(entry)
    (DEST / 'catalog.json').write_text(json.dumps(dict(assets=assets), indent=2) + '\n')
    for path in (ROOT / 'maze3d/assets/models').glob('*.glb'):
        target = DEST / 'Models' / (path.stem + '.pglb')
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(path.read_bytes())
        raw = path.read_bytes()
        length = struct.unpack_from('<I', raw, 12)[0]
        metadata = json.loads(raw[20:20+length])
        # Unity JsonUtility uses zero for absent integer fields, regardless of
        # C# initializers. Materialize glTF's sentinel/default values explicitly.
        for node in metadata['nodes']:
            node.setdefault('mesh', -1)
        for mesh in metadata['meshes']:
            for primitive in mesh['primitives']:
                primitive.setdefault('mode', 4)
                primitive.setdefault('indices', -1)
                primitive.setdefault('material', -1)
                for attribute in ('POSITION', 'NORMAL', 'TEXCOORD_0'):
                    primitive['attributes'].setdefault(attribute, -1)
        target.with_suffix('.json').write_text(json.dumps(metadata, separators=(',', ':')) + '\n')
        manifest[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    (DEST / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Synced {len(manifest)} authored level/model inputs; original GLB bytes preserved.')


if __name__ == '__main__':
    sync()
