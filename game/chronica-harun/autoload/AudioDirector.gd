extends Node

const EVENT_PATHS := {
    "footsteps": "res://audio/ambience/footsteps_stone.ogg",
    "dodge": "res://audio/combat/player_dodge.ogg",
    "player_hit": "res://audio/combat/player_hit.ogg",
    "enemy_windup": "res://audio/entities/enemy_windup.ogg",
    "enemy_shot": "res://audio/entities/enemy_shot.ogg",
    "boss_phase": "res://audio/combat/boss_phase.ogg",
    "secret_break": "res://audio/ambience/secret_break.ogg",
    "pickup": "res://audio/ui/pickup.ogg",
    "power_reveal": "res://audio/combat/power_reveal.ogg"
}

const FALLBACK_PROFILE := {
    "footsteps": [92.0, 0.08],
    "dodge": [180.0, 0.09],
    "player_hit": [105.0, 0.12],
    "enemy_windup": [145.0, 0.16],
    "enemy_shot": [240.0, 0.10],
    "boss_phase": [72.0, 0.34],
    "secret_break": [118.0, 0.18],
    "pickup": [420.0, 0.08],
    "power_reveal": [310.0, 0.22]
}

var streams: Dictionary = {}
var pool: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
    for key in EVENT_PATHS:
        var path := String(EVENT_PATHS[key])
        if ResourceLoader.exists(path):
            streams[key] = load(path)
        else:
            var profile: Array = FALLBACK_PROFILE.get(key, [180.0, 0.1])
            streams[key] = _procedural_stream(float(profile[0]), float(profile[1]))
    for _i in range(16):
        var player := AudioStreamPlayer3D.new()
        player.max_distance = 30.0
        player.unit_size = 2.0
        add_child(player)
        pool.append(player)

func play_3d(event_id: StringName, position: Vector3, pitch_multiplier: float = 1.0) -> void:
    var key := String(event_id)
    if not streams.has(key):
        streams[key] = _procedural_stream(180.0, 0.1)
    _play_stream_at(streams[key], position, clampf(pitch_multiplier, 0.6, 1.6))

func play_enemy_family(family: String, cue: StringName, position: Vector3) -> void:
    var event_id := &"enemy_windup" if cue == &"windup" else &"enemy_shot"
    if cue == &"phase":
        event_id = &"boss_phase"
    var family_offset := float(abs(hash(family)) % 37) / 100.0
    var pitch := 0.82 + family_offset
    play_3d(event_id, position, pitch)

func play_ui(event_id: StringName) -> void:
    var key := String(event_id)
    if not streams.has(key):
        streams[key] = _procedural_stream(360.0, 0.08)
    var player := AudioStreamPlayer.new()
    add_child(player)
    player.stream = streams[key]
    player.finished.connect(player.queue_free)
    player.play()

func _play_stream_at(stream: AudioStream, position: Vector3, pitch: float) -> void:
    for player in pool:
        if not player.playing:
            player.global_position = position
            player.stream = stream
            player.pitch_scale = pitch * randf_range(0.985, 1.015)
            player.play()
            return

func _procedural_stream(frequency: float, duration: float) -> AudioStreamWAV:
    var rate := 22050
    var frames := maxi(64, int(rate * duration))
    var bytes := PackedByteArray()
    bytes.resize(frames * 2)
    for i in range(frames):
        var t := float(i) / float(rate)
        var envelope := pow(1.0 - float(i) / float(frames), 2.2)
        var fundamental := sin(TAU * frequency * t)
        var overtone := sin(TAU * frequency * 1.93 * t) * 0.24
        var sample := int(clampf((fundamental + overtone) * envelope * 0.36, -1.0, 1.0) * 32767.0)
        bytes[i * 2] = sample & 0xff
        bytes[i * 2 + 1] = (sample >> 8) & 0xff
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.stereo = false
    wav.data = bytes
    return wav
