extends RefCounted
## Stable, connected labyrinths, with three spread-out beacons and optional motes.
const TILE := 4.0
const DIRS := [Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
const TITLES := ["初光庭院", "回声回廊", "星眠深境"]
const SUBTITLES := ["循着微光，找到归途", "转角之后，灯火仍在", "让沉睡的遗迹再次亮起"]
var grid: Array = []
var width := 11
var start := Vector2i(1,9)
var goal := Vector2i.ZERO
var beacons: Array[Vector2i] = []
var motes: Array[Vector2i] = []
var seen: Dictionary = {}
var chapter := 0
func build(index: int) -> void:
	chapter = clampi(index,0,2)
	var n := 5 + chapter
	width = n*2+1
	start = Vector2i(1,width-2)
	grid.clear(); beacons.clear(); motes.clear(); seen.clear()
	for z in width:
		var row: Array = []
		for x in width: row.append(1)
		grid.append(row)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8063 + chapter*179
	var stack: Array[Vector2i] = [start]
	grid[start.y][start.x] = 0
	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var choices: Array[Vector2i] = []
		for d in DIRS:
			var t: Vector2i = c+d*2
			if t.x>0 and t.y>0 and t.x<width-1 and t.y<width-1 and grid[t.y][t.x]==1: choices.append(t)
		if choices.is_empty(): stack.pop_back()
		else:
			var target := choices[rng.randi_range(0,choices.size()-1)]
			var mid: Vector2i = (c+target)/2
			grid[mid.y][mid.x]=0; grid[target.y][target.x]=0
			stack.append(target)
	# An arrival courtyard gives the camera and player breathing room.
	for z in range(width-4,width-1):
		for x in range(1,4): grid[z][x]=0
	# A few loops allow choice and prevent every wrong turn being a long backtrack.
	for k in range(2+chapter*2):
		for attempt in 100:
			var c := Vector2i(rng.randi_range(2,width-3),rng.randi_range(2,width-3))
			if grid[c.y][c.x]==1 and ((walkable(c+Vector2i.LEFT) and walkable(c+Vector2i.RIGHT)) or (walkable(c+Vector2i.UP) and walkable(c+Vector2i.DOWN))):
				grid[c.y][c.x]=0;break
	var dist := distances(start)
	goal = start
	for c in dist:
		if dist[c] > dist[goal]: goal=c
	var used: Array[Vector2i] = [start,goal]
	for i in 3:
		var best := start
		var score := -1.0
		for c in dist:
			if c in used or dist[c]<5:continue
			var nearest := 999
			for u in used: nearest=mini(nearest,path(c,u).size())
			var s := float(nearest) + (2.0 if neighbors(c).size()==1 else 0.0)
			if s>score: score=s;best=c
		beacons.append(best);used.append(best)
	# First beacon is always near enough to teach the interact verb.
	beacons.sort_custom(func(a,b):return dist[a]<dist[b])
	var candidates: Array = dist.keys()
	for i in candidates.size():
		var j := rng.randi_range(i,candidates.size()-1)
		var tmp = candidates[i];candidates[i]=candidates[j];candidates[j]=tmp
	for c in candidates:
		if c not in used and dist[c]>2:
			motes.append(c)
			if motes.size()>=12:break
	reveal(start)
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
