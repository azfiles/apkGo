extends RefCounted

enum State { READY, RUNNING, PAUSED, COMPLETE }
enum Hit { IGNORED, WRONG, CORRECT, FINISHED }
var state: State = State.READY
var level: int = 0
var count: int = 9
var next: int = 1
var mistakes: int = 0
var elapsed: float = 0.0

func start(index: int, total: int) -> void:
	level = index
	count = total
	next = 1
	mistakes = 0
	elapsed = 0.0
	state = State.RUNNING

func tick(delta: float) -> void:
	if state == State.RUNNING:
		elapsed += maxf(0.0, delta)

func tap(number: int) -> Hit:
	if state != State.RUNNING or number < next or number > count:
		return Hit.IGNORED
	if number != next:
		mistakes += 1
		return Hit.WRONG
	next += 1
	if next > count:
		state = State.COMPLETE
		return Hit.FINISHED
	return Hit.CORRECT

func pause() -> void:
	if state == State.RUNNING:
		state = State.PAUSED

func resume() -> void:
	if state == State.PAUSED:
		state = State.RUNNING

func snapshot() -> Dictionary:
	return {"level": level, "next": next, "mistakes": mistakes, "elapsed": elapsed}

func restore(data: Dictionary) -> bool:
	var lv = data.get("level", -1)
	var n = data.get("next", 0)
	var m = data.get("mistakes", -1)
	var t = data.get("elapsed", -1)
	for value in [lv, n, m, t]:
		if not (value is float or value is int) or not is_finite(float(value)):
			return false
	if lv != int(lv) or n != int(n) or m != int(m) or lv < 0 or lv > 8:
		return false
	var grid: int = 3 + int(lv) / 3
	if n < 1 or n > grid * grid or m < 0 or t < 0:
		return false
	start(int(lv), grid * grid)
	next = int(n)
	mistakes = int(m)
	elapsed = float(t)
	state = State.PAUSED
	return true
