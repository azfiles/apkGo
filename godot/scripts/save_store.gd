extends RefCounted

var path: String = "user://flow-v2.json"
var unlocked: int = 0
var records: Dictionary = {}
var active: Dictionary = {}
var sound: bool = true
var haptics: bool = true

func load_data() -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("version") != 1:
		return
	var value = parsed.get("unlocked", 0)
	if value is float or value is int:
		unlocked = clampi(int(value), 0, 8)
	if parsed.get("records") is Dictionary:
		for key in parsed.records:
			var record = parsed.records[key]
			if record is Dictionary and str(key).is_valid_int() and int(key) in range(9):
				var time = record.get("time", -1)
				var stars = record.get("stars", 0)
				if (time is float or time is int) and (stars is float or stars is int):
					if is_finite(float(time)) and time >= 0 and stars >= 1 and stars <= 3:
						records[str(key)] = {"time": float(time), "stars": int(stars)}
	if parsed.get("active") is Dictionary:
		active = parsed.active
	sound = parsed.get("sound", true) == true
	haptics = parsed.get("haptics", true) == true

func save() -> Error:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version": 1, "unlocked": unlocked, "records": records,
		"active": active, "sound": sound, "haptics": haptics}))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)

func complete(level: int, elapsed: float, stars: int) -> void:
	var old: Dictionary = records.get(str(level), {})
	records[str(level)] = {"time": minf(elapsed, old.get("time", INF)),
		"stars": maxi(stars, old.get("stars", 0))}
	unlocked = maxi(unlocked, mini(8, level + 1))
	active = {}
	save()
