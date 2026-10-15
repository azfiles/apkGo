extends SceneTree

const Round = preload("res://scripts/round.gd")
const Levels = preload("res://scripts/levels.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	var round = Round.new()
	check(round.tap(1) == Round.Hit.IGNORED, "ready ignores input")
	for level in range(9):
		var count: int = int(Levels.DATA[level].grid) ** 2
		round.start(level, count)
		round.tick(1.25)
		check(round.tap(2) == Round.Hit.WRONG and round.next == 1, "wrong keeps target")
		check(round.mistakes == 1 and round.elapsed == 1.25, "wrong does not add time")
		round.pause()
		round.tick(5)
		check(round.elapsed == 1.25 and round.tap(1) == Round.Hit.IGNORED, "pause gates timer and input")
		var restored = Round.new()
		check(restored.restore(round.snapshot()) and restored.state == Round.State.PAUSED, "restore paused")
		round.resume()
		for number in range(1, count + 1):
			check(round.tap(number) == (Round.Hit.FINISHED if number == count else Round.Hit.CORRECT), "sequential completion")
			check(round.tap(number) == Round.Hit.IGNORED, "duplicate taps ignored")
		check(round.state == Round.State.COMPLETE, "all levels finish")
		round.tick(99)
		check(round.elapsed == 1.25, "complete freezes time")
	check(Levels.stars(10, 0, 18) == 3, "three stars")
	check(Levels.stars(20, 0, 18) == 2, "slow precise round")
	check(Levels.stars(10, 3, 18) == 1, "completion always awards one star")
	for bad in [{}, {"level": 9}, {"level": 0, "next": 10, "mistakes": 0, "elapsed": 0},
			{"level": 0, "next": 1, "mistakes": -1, "elapsed": 0},
			{"level": 0, "next": 1, "mistakes": 0, "elapsed": -1},
			{"level": "0", "next": 1, "mistakes": 0, "elapsed": 0},
			{"level": 0.5, "next": 1, "mistakes": 0, "elapsed": 0}]:
		check(not round.restore(bad), "corrupt snapshot rejected")
	var store = Store.new()
	store.path = "user://round-test-%d.json" % OS.get_process_id()
	store.complete(0, 20, 2)
	store.complete(0, 22, 3)
	check(store.records["0"].time == 20 and store.records["0"].stars == 3, "independent best time and stars")
	check(store.unlocked == 1, "completion unlocks one next level")
	store.sound = false
	store.save()
	var saved = Store.new()
	saved.path = store.path
	saved.load_data()
	check(saved.unlocked == 1 and not saved.sound and saved.records["0"].stars == 3, "disk persistence")
	DirAccess.remove_absolute(store.path)
	print("MODEL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
