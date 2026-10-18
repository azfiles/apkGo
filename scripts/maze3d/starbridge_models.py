"""Editable Z-up Blender modules -> Y-up GLB, with stable IDs in model_catalog.json.

blender --background --python scripts/maze3d/starbridge_models.py
Only the eight new modules and starbridge_library.blend are written.
"""
import json
import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "maze3d/assets/models"
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
materials = {}
for name, color, emission in [("Stone", "BCD2C1", 0), ("Cream", "EEE8CC", 0),
                               ("Deep", "739E91", 0), ("Gold", "EBC467", 0),
                               ("Water", "69C8D2", .12), ("Leaf", "86BA83", 0),
                               ("Petal", "EBA99A", 0), ("Light", "FFF0B0", .4)]:
    rgb = [int(color[i:i+2], 16) / 255 for i in (0, 2, 4)]
    rgb = [v / 12.92 if v < .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = .68
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Strength"].default_value = emission
    materials[name] = mat

roots = []
parts = []
root = None


def begin(id):
    global root
    root = bpy.data.objects.new(id, None)
    bpy.context.collection.objects.link(root)
    root["asset_id"] = id
    root["units"] = "meters; Z-up source, Y-up GLB"
    roots.append(root)
    parts.append(root)


def finish(obj, name, material):
    obj.name = name
    obj.parent = root
    obj.data.materials.append(materials[material])
    parts.append(obj)
    return obj


def box(name, pos, size, material="Stone", bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Rounded masonry", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod = obj.modifiers.new("Corner normals", "WEIGHTED_NORMAL")
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj, name, material)


def cylinder(name, pos, radius, depth, material="Stone", top=None, vertices=12):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius,
                                    radius2=radius if top is None else top,
                                    depth=depth, location=pos)
    return finish(bpy.context.object, name, material)


def sphere(name, pos, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=1, location=pos)
    obj = bpy.context.object
    obj.scale = scale
    for face in obj.data.polygons:
        face.use_smooth = True
    return finish(obj, name, material)


def ring(name, pos, radius, thickness, material):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=thickness,
                                    major_segments=24, minor_segments=6, location=pos)
    return finish(bpy.context.object, name, material)


def export():
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.hide_set(False)
        part.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / (root.name + ".glb")),
                              export_format="GLB", use_selection=True,
                              export_yup=True, export_apply=True)
    for part in parts:
        part.hide_set(True)
    parts.clear()


begin("courtyard_tile")
box("TileTop", (0, 0, -.07), (3.96, 3.96, .10), "Cream", .035)
for side in (-1, 1):
    box("Inlay", (side * 1.72, 0, -.012), (.055, 3.40, .012), "Deep", .004)
    box("Inlay", (0, side * 1.72, -.012), (3.40, .055, .012), "Deep", .004)
for x, y in [(-1.7, -1.7), (1.7, -1.7), (-1.7, 1.7), (1.7, 1.7)]:
    box("GoldCorner", (x, y, -.002), (.12, .12, .02), "Gold", .025)
export()

begin("garden_bridge")  # Local Y follows the bridge; Godot rotates around Y.
box("Deck", (0, 0, -.16), (3.98, 3.98, .28), "Deep", .06)
for i in range(7):
    box("DeckStone", (0, -1.71 + i * .57, -.035), (3.74, .54, .05), "Cream", .018)
for side in (-1, 1):
    for y in (-1.77, 0, 1.77):
        box("BridgePost", (side * 1.86, y, .41), (.20, .20, .86), "Stone", .035)
        sphere("PostCap", (side * 1.86, y, .88), (.15, .15, .15), "Gold")
    box("Handrail", (side * 1.86, 0, .65), (.13, 4, .14), "Stone", .035)
    box("LowerRail", (side * 1.86, 0, .27), (.10, 4, .10), "Gold", .018)
    box("Underbeam", (side * 1.35, 0, -.40), (.24, 4, .35), "Stone", .035)
export()

begin("ruins_arch")
for side in (-1, 1):
    box("Plinth", (side * 1.7, 0, .15), (.74, .9, .3), "Deep")
    box("Column", (side * 1.7, 0, 1.65), (.5, .6, 3.0))
    for z in (.55, 2.75):
        box("Band", (side * 1.7, 0, z), (.61, .73, .15), "Gold", .025)
for i in range(11):
    angle = i * math.pi / 10
    obj = box("ArchStone", (math.cos(angle) * 1.7, 0, 2.92 + math.sin(angle) * 1.45),
              (.56, .72, .56), "Cream" if i % 2 else "Stone")
    obj.rotation_euler.y = angle - math.pi / 2
box("Crest", (0, -.02, 4.48), (.45, .78, .48), "Gold").rotation_euler.y = math.pi / 4
export()

begin("ruins_column")
box("Foot", (0, 0, .15), (1.1, 1.1, .3), "Deep")
cylinder("Base", (0, 0, .40), .48, .28, "Cream")
for i in range(5):
    cylinder("ColumnDrum", (0, 0, .77 + i * .55), .34, .52)
cylinder("Neck", (0, 0, 3.35), .48, .22, "Gold")
box("Capital", (0, 0, 3.60), (1.02, 1.02, .30), "Cream")
sphere("Ivy", (.28, .09, 1.0), (.17, .2, .55), "Leaf")
export()

begin("garden_fountain")
cylinder("Foundation", (0, 0, .10), 1.5, .2, "Deep", vertices=24)
cylinder("Basin", (0, 0, .28), 1.40, .25, "Stone", vertices=24)
cylinder("Water", (0, 0, .43), 1.28, .04, "Water", vertices=32)
ring("Rim", (0, 0, .46), 1.35, .12, "Cream")
cylinder("Stem", (0, 0, 1.0), .18, 1.1, "Cream")
cylinder("UpperBowl", (0, 0, 1.50), .68, .18, "Stone", top=.78, vertices=24)
cylinder("UpperWater", (0, 0, 1.61), .67, .03, "Water", vertices=24)
ring("UpperRim", (0, 0, 1.62), .73, .075, "Gold")
for i in range(6):
    angle = math.tau * i / 6
    cylinder("Waterfall", (.64 * math.cos(angle), .64 * math.sin(angle), 1.02), .035, 1.10, "Water", vertices=6)
sphere("LuminousPearl", (0, 0, 1.97), (.22, .22, .29), "Light")
export()

begin("garden_pavilion")
# Posts lie between tile centerlines; the whole court stays navigable.
for x in (-2.4, 2.4):
    for y in (-2.4, 2.4):
        cylinder("PavilionColumn", (x, y, 1.9), .17, 3.8, "Cream", vertices=10)
        cylinder("PavilionFoot", (x, y, .17), .28, .34, "Deep")
        cylinder("Capital", (x, y, 3.62), .26, .24, "Gold")
cylinder("Eaves", (0, 0, 3.9), 3.95, .20, "Deep", vertices=8)
cylinder("Roof", (0, 0, 4.65), 3.95, 1.35, "Leaf", top=.75, vertices=8)
cylinder("UpperEaves", (0, 0, 5.23), 1.12, .12, "Gold", vertices=8)
cylinder("UpperRoof", (0, 0, 5.50), 1.2, .5, "Deep", top=.18, vertices=8)
sphere("RoofFinial", (0, 0, 5.92), (.14, .14, .30), "Gold")
export()

begin("flower_planter")
box("Planter", (0, 0, .26), (1.7, .8, .52), "Stone", .08)
box("Coping", (0, 0, .55), (1.82, .9, .12), "Cream", .04)
for i in range(5):
    x = -.65 + i * .32
    sphere("Foliage", (x, 0, .72), (.30, .30, .22), "Leaf")
    for j in range(5):
        angle = math.tau * j / 5
        sphere("Petal", (x + math.cos(angle) * .085, math.sin(angle) * .085, .94),
               (.07, .07, .045), "Petal" if i % 2 else "Light")
    sphere("FlowerCenter", (x, 0, .96), (.045, .045, .04), "Gold")
export()

begin("aqueduct")
for side in (-1, 1):
    box("Pier", (side * 3.5, 0, 2.2), (.70, 1, 4.4), "Stone", .07)
    box("PierFoot", (side * 3.5, 0, .15), (1, 1.3, .3), "Deep", .07)
for i in range(15):
    angle = i * math.pi / 14
    obj = box("ArchBlock", (math.cos(angle) * 3.5, 0, 3.8 + math.sin(angle) * 1.9),
              (.65, .95, .64), "Cream" if i % 2 else "Stone")
    obj.rotation_euler.y = angle - math.pi / 2
box("ChannelBase", (0, 0, 6.05), (8, 1.2, .35), "Stone")
box("ChannelWater", (0, 0, 6.25), (8, .70, .04), "Water", .015)
for side in (-1, 1):
    box("Parapet", (0, side * .54, 6.38), (8, .18, .50), "Cream")
    box("GoldCourse", (0, side * .64, 6.14), (8, .035, .09), "Gold", .008)
export()

# Keep clean local origins in GLBs; arrange only the editable source library.
for i, module in enumerate(roots):
    module.location = (i % 4 * 12, i // 4 * 14, 0)
for obj in bpy.context.scene.objects:
    obj.hide_set(False)
bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.scene.unit_settings.scale_length = 1
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "model-source/maze3d/starbridge_library.blend"))
catalog = json.loads((ROOT / "maze3d/assets/model_catalog.json").read_text())
assert all(module.name in catalog["assets"] for module in roots)
print(f"MODELS: {len(roots)} catalogued GLBs and editable starbridge_library.blend exported")
