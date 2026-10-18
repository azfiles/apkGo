"""Author the fourth chapter as plain JSON; no Godot/Blender dependency.

Run from any directory: python3 scripts/maze3d/starbridge_level.py
Existing chapters are hand-editable snapshots and are never regenerated here.
"""
import json
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIZE = 19
rng = random.Random(94031)
grid = [["#"] * SIZE for _ in range(SIZE)]
directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]
start = (1, 17)
stack = [start]
grid[17][1] = "."
while stack:
    x, z = stack[-1]
    choices = [(x + dx * 2, z + dz * 2, dx, dz) for dx, dz in directions
               if 0 < x + dx * 2 < 18 and 0 < z + dz * 2 < 18
               and grid[z + dz * 2][x + dx * 2] == "#"]
    if not choices:
        stack.pop()
        continue
    nx, nz, dx, dz = rng.choice(choices)
    grid[z + dz][x + dx] = grid[nz][nx] = "."
    stack.append((nx, nz))

# Five courts connected by two promenades and three bridges across a real canal.
for x0, z0, x1, z1 in [(1, 15, 3, 17), (2, 1, 5, 3), (13, 1, 15, 3),
                        (13, 7, 17, 11), (13, 15, 15, 17)]:
    for z in range(z0, z1 + 1):
        for x in range(x0, x1 + 1):
            grid[z][x] = "."
for z in range(1, 18):
    grid[z][7] = grid[z][11] = "."
    for x in (8, 9, 10):
        grid[z][x] = "=" if z in (3, 9, 15) else "~"
grid[9][15] = "~"  # Fountain island, with a walkable ring on all four sides.
grid[2][17] = "#"  # A terminal approach keeps the portal's columns off the route.
beacons = [(3, 2), (15, 8), (15, 16)]
goal = (17, 1)


def neighbors(cell):
    x, z = cell
    return [(x + dx, z + dz) for dx, dz in directions
            if 0 <= x + dx < SIZE and 0 <= z + dz < SIZE
            and grid[z + dz][x + dx] in ".="]


def reachable(origin):
    result = {origin: True}
    queue = deque([origin])
    while queue:
        for cell in neighbors(queue.popleft()):
            if cell not in result:
                result[cell] = True
                queue.append(cell)
    return result


connected = reachable(start)
assert len(connected) == sum(c in ".=" for row in grid for c in row)
reserved = {start, goal, *beacons}
motes = [(9, 15), (9, 9), (9, 3), (3, 16), (4, 2), (14, 2), (14, 8),
         (16, 10), (14, 16)]
candidates = [c for c in connected if c not in reserved and c not in motes]
rng.shuffle(candidates)
for cell in candidates:
    if len(motes) >= 18:
        break
    if grid[cell[1]][cell[0]] == ".":
        motes.append(cell)
reserved.update(motes)
challenges = []
for cell in sorted(connected, key=lambda c: (c[1], c[0])):
    if cell in reserved or grid[cell[1]][cell[0]] == "=":
        continue
    adjacent = neighbors(cell)
    if len(adjacent) != 2:
        continue
    if tuple(adjacent[0][i] + adjacent[1][i] for i in (0, 1)) != tuple(v * 2 for v in cell):
        continue
    if any(abs(cell[0] - h["cell"][0]) + abs(cell[1] - h["cell"][1]) < 3 for h in challenges):
        continue
    axis = [1, 0] if (cell[0] + 1, cell[1]) in adjacent else [0, 1]
    challenges.append({"cell": list(cell), "axis": axis,
                       "kind": "hurdle" if len(challenges) % 2 == 0 else "gap",
                       "height": .75, "span": 1.4})
    if len(challenges) == 9:
        break
assert len(challenges) == 9

scenery = []


def place(asset, x, z, height=0, rotation=0, scale=1, collisions=True):
    scenery.append({"asset": asset, "position": [(x - SIZE // 2) * 4, height, (z - SIZE // 2) * 4],
                    "rotation_y": rotation, "scale": scale, "collisions": collisions})


for z in (3, 9, 15):
    for x in (8, 10):
        place("ruins_arch", x, z, rotation=90)
for z in (6, 12):
    place("aqueduct", 9, z, scale=1.5)
place("garden_fountain", 15, 9, height=-.05)
place("garden_pavilion", 3, 2)
place("garden_pavilion", 14, 16)
for z in (5, 7, 11, 13, 17):
    place("flower_planter", 7.36, z, rotation=90)
    place("flower_planter", 10.64, z, rotation=90)
for x, z in [(1, 13), (5, 5), (13, 5), (17, 13), (5, 17), (17, 5)]:
    if grid[z][x] == "#":
        place("ruins_column", x, z, height=2.2, collisions=False)
for x, z in [(6.65, 3), (11.35, 3), (6.65, 9), (11.35, 9), (6.65, 15), (11.35, 15)]:
    # Offset lamps sit outside the centerline used by movement and hints.
    place("lantern", x, z + .34, collisions=False)

data = {"version": 1, "id": "starbridge_garden", "title": "星桥水庭",
        "subtitle": "穿过星桥，让水庭重焕光彩", "difficulty": "探索 · 水庭",
        "seed": 94031, "tile_size": 4.0, "grid": ["".join(row) for row in grid],
        "start": list(start), "goal": list(goal), "beacons": [list(c) for c in beacons],
        "motes": [list(c) for c in motes], "elevated_motes": [0, 1, 2, 5, 7],
        "challenges": challenges, "scenery": scenery,
        "bridge_rotation_y": 90,
        "environment": {"background": "b8dce7", "fog": "c1e0df", "water": "66bdcb"},
        "regions": [{"name": "迎光花庭", "bounds": [1, 10, 7, 17], "floor": "e4dfc1"},
                    {"name": "星桥水道", "bounds": [7, 1, 11, 17], "floor": "d6e4d6"},
                    {"name": "回响拱廊", "bounds": [1, 1, 6, 9], "floor": "d5e4ca"},
                    {"name": "喷泉中庭", "bounds": [12, 1, 17, 11], "floor": "e6dfc7"},
                    {"name": "归星凉亭", "bounds": [12, 12, 17, 17], "floor": "dae0c6"}]}
target = ROOT / "maze3d/levels/starbridge_garden.json"
target.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
print(f"Authored {target.name}: {len(connected)} passages, {len(motes)} stars, "
      f"{len(challenges)} challenges, {len(scenery)} scenery placements")
