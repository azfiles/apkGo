extends Node
## Small synthesized chimes; no network or external music dependencies.

var enabled := true
var voices: Array[AudioStreamPlayer] = []
var samples: Dictionary = {}
var cursor := 0

func _ready() -> void:
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -15
		add_child(voice)
		voices.append(voice)

func play_note(note: int = 0) -> void:
	if not enabled or voices.is_empty(): return
	if not samples.has(note):
		var rate := 22050
		var duration := 0.42
		var frequency := 440.0 * pow(2.0, float(note + 3) / 12.0)
		var bytes := PackedByteArray()
		bytes.resize(int(rate * duration) * 2)
		for i in range(int(rate * duration)):
			var t := float(i) / rate
			var envelope := minf(t * 100, 1.0) * exp(-t * 11) * (1.0 - t / duration)
			var value := (sin(TAU * frequency * t) + 0.28 * sin(TAU * frequency * 2.0 * t)) * envelope * 17000
			bytes.encode_s16(i * 2, int(value))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.data = bytes
		samples[note] = stream
	var voice := voices[cursor % voices.size()]
	cursor += 1
	voice.stream = samples[note]
	voice.play()

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	samples.clear()
