extends RefCounted

var path := "user://garden-progress.json"
var sound := true
var records: Dictionary = {}
var active: Dictionary = {}

func load_data() -> void:
	if not FileAccess.file_exists(path): return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return
	var data = parser.data
	if not data is Dictionary or data.get("version") != 1: return
	sound = data.get("sound", true) == true
	if data.get("records") is Dictionary:
		for key in data.records:
			var value = data.records[key]
			if key in ["0", "1", "2"] and (value is float or value is int) and value >= 0 and value <= 3:
				records[key] = int(value)
	if data.get("active") is Dictionary: active = data.active

func save_data() -> void:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"version": 1, "sound": sound, "records": records, "active": active}))
	file.close()
	DirAccess.rename_absolute(path + ".tmp", path)

func finish(index: int, found: int) -> void:
	records[str(index)] = maxi(int(records.get(str(index), 0)), found)
	active.erase(str(index))
	save_data()
