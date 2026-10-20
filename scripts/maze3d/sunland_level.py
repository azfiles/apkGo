"""Author a compact Sunland lakeside chapter using the existing level contract."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIZE = 25
grid = [["#" if x in (0, 24) or z in (0, 24) else "~"
         for x in range(SIZE)] for z in range(SIZE)]


def line(a, b, surface="."):
    x, z = a
    dx = (b[0] > x) - (b[0] < x)
    dz = (b[1] > z) - (b[1] < z)
    assert not (dx and dz)
    while True:
        grid[z][x] = surface
        if (x, z) == b:
            break
        x += dx
        z += dz


# An asymmetric shore loop, a cross-lake boardwalk and three destination courts.
shore = [(3, 21), (3, 15), (5, 15), (5, 9), (3, 9), (3, 3),
         (9, 3), (9, 5), (15, 5), (15, 3), (21, 3), (21, 9),
         (19, 9), (19, 17), (21, 17), (21, 21), (3, 21)]
for a, b in zip(shore, shore[1:]):
    line(a, b)

def inside_shore(x, z):
    inside = False
    for (ax, az), (bx, bz) in zip(shore, shore[1:]):
        if (az > z) != (bz > z) and x < (bx-ax)*(z-az)/(bz-az)+ax:
            inside = not inside
    return inside


# Raised grassy banks outside the loop make a defined shoreline. The water
# openings inside the loop retain the existing fall-and-rescue behavior.
for z in range(1, 24):
    for x in range(1, 24):
        if grid[z][x] == "~" and not inside_shore(x, z):
            grid[z][x] = "#"
line((6, 12), (18, 12), "=")
for bounds in [(1, 19, 5, 23), (1, 1, 5, 4), (19, 19, 23, 23)]:
    x0, z0, x1, z1 = bounds
    for z in range(z0, z1 + 1):
        for x in range(x0, x1 + 1):
            grid[z][x] = "."
# The portal has a terminal approach, with no side routes through its columns.
line((21, 21), (23, 21))
grid[20][23] = grid[22][23] = "#"
start, goal = (1, 22), (23, 21)
beacons = [(3, 2), (21, 4), (21, 20)]
motes = [(3, 20), (4, 23), (2, 19), (3, 16), (5, 14), (5, 10),
         (3, 8), (2, 3), (4, 1), (7, 3), (10, 5), (14, 5),
         (16, 3), (20, 3), (21, 8), (19, 10), (19, 14), (19, 17),
         (21, 19), (22, 23), (17, 21), (10, 21), (9, 12), (15, 12)]
hazards = [((3, 18), (0, 1)), ((5, 13), (0, 1)), ((3, 6), (0, 1)),
           ((6, 3), (1, 0)), ((12, 5), (1, 0)), ((18, 3), (1, 0)),
           ((21, 6), (0, 1)), ((19, 16), (0, 1)), ((19, 21), (1, 0)),
           ((13, 21), (1, 0)), ((7, 21), (1, 0))]
scenery = []


def place(asset, x, z, y=0, rotation=0, scale=1, collisions=True):
    scenery.append({"asset": asset, "position": [(x-12)*4, y, (z-12)*4],
                    "rotation_y": rotation, "scale": scale, "collisions": collisions})


# Actual upstream landmarks are arranged beside the playable route. The dock
# is scenery in the lake; the red-railed crossing supplies the playable deck.
place("sunland_dock", 12, 15.6, y=-1.55, collisions=False)
place("sunland_island", 6.8, 6.8, y=2.48)
place("sunland_camp", 6.8, 6.8, y=2.48)
place("sunland_pavilion", 17.4, 1.05, y=2.48)
for x, z, rot in [(3, 23.45, 0), (3, .55, 0), (21.5, 23.45, 0)]:
    place("sunland_bench", x, z, rotation=rot)
for x, z in [(1, 6), (1, 11), (1, 16), (7, 8), (9, 8), (11, 2),
             (17, 7), (23, 6), (23, 11), (23, 16), (7, 23), (12, 23), (17, 23)]:
    if grid[z][x] == "~":
        # Small inaccessible vegetation islands sit clear of the crossing.
        place("sunland_island", x, z, y=2.48, scale=.38)
    place("sunland_willow" if z % 2 else "sunland_redwood", x, z, y=2.48, collisions=False)
for x, z in [(6.4, 10.5), (6.4, 14), (9, 15), (14, 17), (17.6, 13.8),
             (17.6, 10), (10, 6.5), (13, 6.5), (4.4, 17)]:
    place("sunland_reeds", x, z, y=-1.05, scale=1.4, collisions=False)
for x, z in [(5, 11.6), (19, 12.4), (3.35, 15), (21.35, 17)]:
    place("lantern", x, z, collisions=False)
data = {"version": 1, "id": "sunland_lake", "title": "森兰寻光",
        "subtitle": "沿着湖湾栈道，点亮森兰的三盏灯", "difficulty": "漫游 · 湖湾",
        "seed": 106019, "tile_size": 4.0, "grid": ["".join(r) for r in grid],
        "start": start, "goal": goal, "beacons": beacons, "motes": motes,
        "elevated_motes": [4, 9, 13, 16, 22, 23],
        "challenges": [{"cell": c, "axis": a, "kind": "hurdle" if i % 2 == 0 else "gap",
                        "height": .75, "span": 1.4} for i, (c, a) in enumerate(hazards)],
        "scenery": scenery, "bridge_rotation_y": 90,
        "surface_assets": {"floor": "sunland_boardwalk", "bridge": "sunland_bridge", "wall": "sunland_hedge"},
        "environment": {"background": "b5dfe8", "fog": "c6e6df", "water": "54adba"},
        "regions": [{"name": "迎风林岸", "bounds": [1, 15, 9, 23], "floor": "cbb68b"},
                    {"name": "湖畔营地", "bounds": [1, 1, 10, 14], "floor": "d3bd91"},
                    {"name": "无界展亭", "bounds": [11, 1, 23, 9], "floor": "dbc7a0"},
                    {"name": "红栏星桥", "bounds": [6, 10, 18, 14], "floor": "d3bd91"},
                    {"name": "东岸归途", "bounds": [10, 10, 23, 23], "floor": "cbb68b"}]}
(ROOT / "maze3d/levels/sunland_lake.json").write_text(json.dumps(data, ensure_ascii=False, indent=2)+"\n")
index_path = ROOT / "maze3d/levels/index.json"
index = json.loads(index_path.read_text())
entry = {key: data[key] for key in ["id", "title", "subtitle", "difficulty"]}
entry["path"] = "res://levels/sunland_lake.json"
index["chapters"] = [e for e in index["chapters"] if e["id"] != data["id"]] + [entry]
index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2)+"\n")
print("SUNLAND: 24 stars, 11 jumps,", len(scenery), "scenery placements")
