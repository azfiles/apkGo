extends RefCounted
## Authored topology and objectives come from JSON; this class only queries them.
const TILE := 4.0
const DIRS := [Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
const Levels = preload("res://scripts/level_data.gd")
var grid: Array = []
var width := 11
var start := Vector2i(1,9)
var goal := Vector2i.ZERO
var beacons: Array[Vector2i] = []
var motes: Array[Vector2i] = []
var seen: Dictionary = {}
var chapter := 0
var challenges: Array[Dictionary] = []
var elevated_motes: Array[int] = []
var definition: Dictionary = {}

func build(index: int) -> bool:
	var data := Levels.load_chapter(index)
	if data.is_empty(): return false
	definition = data
	chapter = clampi(index, 0, Levels.count()-1)
	width = data.grid.size()
	start = Vector2i(data.start[0], data.start[1])
	goal = Vector2i(data.goal[0], data.goal[1])
	grid.clear(); beacons.clear(); motes.clear(); seen.clear(); challenges.clear(); elevated_motes.clear()
	for source in data.grid:
		var row: Array = []
		for symbol in source: row.append(0 if symbol in [".", "="] else (2 if symbol == "~" else 1))
		grid.append(row)
	for c in data.beacons: beacons.append(Vector2i(c[0], c[1]))
	for c in data.motes: motes.append(Vector2i(c[0], c[1]))
	for source in data.challenges:
		var challenge: Dictionary = source.duplicate(true)
		challenge.cell = Vector2i(source.cell[0], source.cell[1])
		challenge.axis = Vector2i(source.axis[0], source.axis[1])
		challenges.append(challenge)
	for index_value in data.elevated_motes: elevated_motes.append(int(index_value))
	reveal(start)
	return true

func region_at(c: Vector2i) -> Dictionary:
	for region in definition.get("regions", []):
		var b: Array = region.bounds
		if c.x >= b[0] and c.y >= b[1] and c.x <= b[2] and c.y <= b[3]: return region
	return {}

func surface(c: Vector2i) -> String:
	return definition.grid[c.y][c.x]

func challenge_at(c: Vector2i) -> Dictionary:
	for challenge in challenges:
		if challenge.cell==c:return challenge
	return {}

func safe_cell(c: Vector2i) -> bool:
	return walkable(c) and challenge_at(c).is_empty()

func mote_height(index: int) -> float:
	return 2.05 if index in elevated_motes else .85

func walkable(c: Vector2i) -> bool:
	return c.x>=0 and c.y>=0 and c.x<width and c.y<width and grid[c.y][c.x]==0
func neighbors(c: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i]=[]
	for d in DIRS:
		if walkable(c+d):result.append(c+d)
	return result
func distances(from: Vector2i) -> Dictionary:
	var result := {from:0}
	var queue: Array[Vector2i]=[from]
	var i:=0
	while i<queue.size():
		var c:=queue[i];i+=1
		for t in neighbors(c):
			if not result.has(t):result[t]=result[c]+1;queue.append(t)
	return result
func path(from: Vector2i,to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i]=[]
	if not walkable(from) or not walkable(to):return result
	var queue: Array[Vector2i]=[from]
	var prev := {from:from}
	var i:=0
	while i<queue.size() and not prev.has(to):
		var c:=queue[i];i+=1
		for t in neighbors(c):
			if not prev.has(t):prev[t]=c;queue.append(t)
	if not prev.has(to):return result
	var c:=to
	while c!=from:result.push_front(c);c=prev[c]
	return result
func world(c: Vector2i) -> Vector3:
	return Vector3((c.x-width/2)*TILE,0,(c.y-width/2)*TILE)
func cell(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x/TILE)+width/2,roundi(p.z/TILE)+width/2)
func reveal(c: Vector2i) -> void:
	for z in range(c.y-2,c.y+3):
		for x in range(c.x-2,c.x+3):
			if x>=0 and z>=0 and x<width and z<width:seen[Vector2i(x,z)]=true
