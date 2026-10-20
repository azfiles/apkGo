"""Adapt actual Sunland meshes into the existing editable module pipeline.

blender -b --python scripts/maze3d/sunland_models.py -- /path/to/Sunland
Only sunland_library.blend, sunland_*.glb and their catalog entries are written.
The source commit and upstream object names are recorded on each editable root.
"""
import json
import sys
import subprocess
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
UPSTREAM = Path(sys.argv[sys.argv.index("--") + 1])
COMMIT = "243b4e2cf0c7b77225c38e28aa2a1b73a07de044"
actual_commit = subprocess.check_output(["git", "-C", str(UPSTREAM), "rev-parse", "HEAD"], text=True).strip()
if actual_commit != COMMIT:
    raise ValueError(f"Expected Sunland {COMMIT}, got {actual_commit}; checkout the documented source first")
OUT = ROOT / "maze3d/assets/models"
bpy.ops.wm.read_factory_settings(use_empty=True)
specs = {
    "sunland_dock": ("Landmark_kayak_dock", 1.0),
    "sunland_camp": ("Landmark_lake_camp", .45),
    "sunland_pavilion": ("Landmark_wujie_pavilion", .36),
    "sunland_willow": ("Kit_willow_LOD1", .7),
    "sunland_redwood": ("Kit_metasequoia_LOD1", .65),
    "sunland_bench": ("Kit_bench", 1.0),
    "sunland_reeds": ("Kit_reed", 1.0),
}
with bpy.data.libraries.load(str(UPSTREAM / "assets/sunland/sunland.blend")) as (src, dst):
    dst.objects = [name for name, scale in specs.values()]
objects = {o.name: o for o in dst.objects}
roots = []
catalog_path = ROOT / "maze3d/assets/model_catalog.json"
catalog = json.loads(catalog_path.read_text())


def begin(id):
    root = bpy.data.objects.new(id, None)
    bpy.context.collection.objects.link(root)
    root["source_repository"] = "https://github.com/azfiles/Sunland"
    root["source_commit"] = COMMIT
    roots.append(root)
    return root


def flat_material(original):
    name = "Sunland_" + original.name
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name)
    # Flat colors fit the game's existing cutaway shader and avoid embedded
    # kilometer-scale PBR maps. Preserve each upstream material separately.
    color = tuple(min(1, c * 1.12 + .035) for c in original.diffuse_color[:3])
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = mat.diffuse_color
    shader.inputs["Roughness"].default_value = .8
    return mat


def split_materials(original, root, scale):
    # Split multi-material source meshes so the runtime cutaway/batching path
    # keeps the red rails, white canopy, colored kayaks and canvas distinct.
    mesh = original.data
    for index, material in enumerate(mesh.materials):
        polys = [p for p in mesh.polygons if p.material_index == index]
        if not polys:
            continue
        used = sorted({v for p in polys for v in p.vertices})
        remap = {v: i for i, v in enumerate(used)}
        data = bpy.data.meshes.new(root.name + "_" + material.name)
        data.from_pydata([mesh.vertices[v].co * scale for v in used], [],
                         [[remap[v] for v in p.vertices] for p in polys])
        data.materials.append(flat_material(material))
        data.update()
        obj = bpy.data.objects.new(data.name, data)
        bpy.context.collection.objects.link(obj)
        obj.parent = root
    root["upstream_object"] = original.name
    root["adaptation_scale"] = scale


for id, (name, scale) in specs.items():
    split_materials(objects[name], begin(id), scale)

# Matching four-meter walking surfaces use the upstream timber palette.
timber = bpy.data.materials["Sunland_timber"]
leaf = bpy.data.materials["Sunland_leaf_sage"]


def cube(root, name, position, size, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.parent = root
    obj.data.materials.append(mat)
    return obj


for id in ["sunland_boardwalk", "sunland_bridge"]:
    root = begin(id)
    for i in range(16):
        cube(root, "Plank", (0, -1.875 + i * .25, -.09), (4, .235, .18), timber)
    if id == "sunland_bridge":
        rail = bpy.data.materials["Sunland_terracotta"]
        for side in [-1, 1]:
            for y in [-1.8, 0, 1.8]:
                cube(root, "RedPost", (side * 1.85, y, .48), (.09, .09, .96), rail)
            cube(root, "RedRail", (side * 1.85, 0, .94), (.09, 4, .09), rail)

root = begin("sunland_hedge")
cube(root, "HedgeBase", (0, 0, .22), (4, 4, .44), timber)
cube(root, "Hedge", (0, 0, 1.35), (4, 4, 2.26), leaf)

root = begin("sunland_island")
for name, radius, depth, height, mat in [
        ("ShoreBank", 8, 3.2, -1.6, timber),
        ("GrassyTop", 7.8, .10, -.025, leaf)]:
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=radius+.6 if name=="ShoreBank" else radius,
                                    radius2=radius, depth=depth, location=(0, 0, height))
    obj = bpy.context.object
    obj.name = name
    obj.scale.y = .875
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.parent = root
    obj.data.materials.append(mat)

colliders = {
    "sunland_boardwalk": [{"size": [4, .18, 4], "position": [0, -.09, 0]}],
    "sunland_bridge": [{"size": [4, .18, 4], "position": [0, -.09, 0]}] +
        [{"size": [.12, 1, 4], "position": [s * 1.85, .5, 0]} for s in [-1, 1]],
    "sunland_hedge": [{"size": [4, 2.48, 4], "position": [0, 1.24, 0]}],
    "sunland_camp": [{"size": [9.8, 5.3, 9.8], "position": [0, 2.65, 0]}],
    "sunland_pavilion": [{"size": [13.68, 2.7, 5.76], "position": [0, 1.35, 0]}],
    "sunland_bench": [{"size": [1.85, 1.1, .85], "position": [0, .55, -.12]}],
    "sunland_island": [{"size": [13.8, 3.2, 11.8], "position": [0, -1.6, 0]}],
}
for i, root in enumerate(roots):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [root, *root.children_recursive]:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / (root.name + ".glb")),
                              export_format="GLB", use_selection=True,
                              export_yup=True, export_apply=True)
    catalog["assets"][root.name] = {
        "path": "res://assets/models/" + root.name + ".glb",
        "source": "model-source/maze3d/sunland_library.blend",
        "source_root": root.name, "colliders": colliders.get(root.name, []),
    }
    root.location = (i % 4 * 24, i // 4 * 24, 0)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "model-source/maze3d/sunland_library.blend"))
catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
print("SUNLAND: exported", len(roots), "editable modules from", COMMIT)
