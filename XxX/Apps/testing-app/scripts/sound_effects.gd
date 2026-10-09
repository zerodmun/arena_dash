extends Node
## Procedural retro-arcade sound synthesizer.
## Generates clean 16-bit PCM AudioStreamWAV sounds in-memory at startup.

var shoot_stream: AudioStreamWAV
var explosion_stream: AudioStreamWAV
var pickup_stream: AudioStreamWAV
var hit_stream: AudioStreamWAV

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS := 8
var _next_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_generate_sounds()
	for i in MAX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play_shoot() -> void:
	_play(shoot_stream, -6.0, randf_range(0.95, 1.05))


func play_explosion() -> void:
	_play(explosion_stream, -2.0, randf_range(0.9, 1.1))


func play_pickup() -> void:
	_play(pickup_stream, -4.0, randf_range(0.98, 1.08))


func play_hit() -> void:
	_play(hit_stream, 0.0, 1.0)


func _play(stream: AudioStreamWAV, volume_db: float, pitch: float) -> void:
	if not Game.audio_enabled or stream == null or _players.is_empty():
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % MAX_PLAYERS
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func _generate_sounds() -> void:
	shoot_stream = _create_laser_stream()
	explosion_stream = _create_explosion_stream()
	pickup_stream = _create_pickup_stream()
	hit_stream = _create_hit_stream()


func _create_laser_stream() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.16
	var samples := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in samples:
		var t := float(i) / rate
		var progress := float(i) / samples
		var freq := lerpf(980.0, 160.0, progress * progress)
		var env := 1.0 - progress
		var wave := sin(TAU * freq * t)
		# add square harmonic
		var sample_val := int(clampf((wave * 0.7 + signf(wave) * 0.3) * env * 24000.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream


func _create_explosion_stream() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.35
	var samples := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	var last_noise := 0.0
	for i in samples:
		var t := float(i) / rate
		var progress := float(i) / samples
		var env := pow(1.0 - progress, 2.2)
		var noise := randf_range(-1.0, 1.0)
		# low-pass filter the noise
		last_noise = lerpf(last_noise, noise, 0.35)
		var bass := sin(TAU * (80.0 - progress * 50.0) * t) * 0.6
		var combined := (last_noise * 0.7 + bass) * env
		var sample_val := int(clampf(combined * 28000.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream


func _create_pickup_stream() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.28
	var samples := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in samples:
		var t := float(i) / rate
		var progress := float(i) / samples
		var env := 1.0 - progress
		# Arpeggio: starts at 659 Hz (E5), jumps to 987 Hz (B5) halfway
		var freq := 659.0 if progress < 0.35 else 987.0
		var tone := sin(TAU * freq * t) * 0.75 + sin(TAU * (freq * 2.0) * t) * 0.25
		var sample_val := int(clampf(tone * env * 22000.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream


func _create_hit_stream() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.25
	var samples := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)

	for i in samples:
		var t := float(i) / rate
		var progress := float(i) / samples
		var env := 1.0 - progress
		var freq := lerpf(180.0, 45.0, progress)
		var tone := sin(TAU * freq * t) * 0.8 + randf_range(-0.2, 0.2)
		var sample_val := int(clampf(tone * env * 29000.0, -32768.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream


func _exit_tree() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_players.clear()
	shoot_stream = null
	explosion_stream = null
	pickup_stream = null
	hit_stream = null


func stop_all() -> void:
	for player in _players:
		if is_instance_valid(player): player.stop()
