extends SceneTree
const Maze=preload("res://scripts/maze.gd")
var checks:=0
func check(ok:bool,label:String) -> void:
	if not ok:push_error(label);quit(1)
	assert(ok,label);checks+=1
func _initialize() -> void:
	for chapter in 3:
		var m=Maze.new();m.build(chapter)
		var distances:Dictionary=m.distances(m.start)
		var walkable_count:=0
		for y in m.width:
			for x in m.width:
				var c:=Vector2i(x,y)
				if m.walkable(c):walkable_count+=1;check(m.cell(m.world(c))==c,"world/cell roundtrip")
		check(distances.size()==walkable_count,"all passages connected")
		check(m.beacons.size()==3 and m.motes.size()==12,"objective counts")
		check(m.goal not in m.beacons and m.goal not in m.motes,"distinct exit")
		for target in m.beacons+[m.goal]:
			var path:Array=m.path(m.start,target)
			check(not path.is_empty(),"each beacon and gate reachable")
			var previous:Vector2i=m.start
			for c in path:
				check(m.walkable(c) and (c-previous).length_squared()==1,"hint never crosses a wall")
				previous=c
		var duplicate=Maze.new();duplicate.build(chapter)
		check(duplicate.grid==m.grid and duplicate.beacons==m.beacons,"stable replay")
		print("CHAPTER ",chapter+1,": ",walkable_count," paths, beacons ",m.beacons," exit ",m.goal)
	print("MODEL: ",checks," checks, 0 failures");quit()
