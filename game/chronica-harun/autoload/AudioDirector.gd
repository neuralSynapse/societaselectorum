extends Node

signal event_played(event_id: StringName, position: Vector3, spatial: bool)

const SAMPLE_RATE := 22050
const EVENT_SPECS := {
    "footsteps": {"path":"res://audio/ambience/footsteps_stone.ogg", "frequency":92.0, "duration":0.08, "gain":0.18, "noise":0.72},
    "dodge": {"path":"res://audio/combat/player_dodge.ogg", "frequency":180.0, "duration":0.11, "gain":0.22, "noise":0.44},
    "perfect_dodge": {"path":"res://audio/combat/perfect_dodge.ogg", "frequency":620.0, "duration":0.14, "gain":0.25, "noise":0.08},
    "player_hit": {"path":"res://audio/combat/player_hit.ogg", "frequency":116.0, "duration":0.16, "gain":0.32, "noise":0.58},
    "player_primary": {"path":"res://audio/combat/player_primary.ogg", "frequency":340.0, "duration":0.10, "gain":0.24, "noise":0.20},
    "player_power": {"path":"res://audio/combat/player_power.ogg", "frequency":210.0, "duration":0.24, "gain":0.28, "noise":0.24},
    "kinesis": {"path":"res://audio/combat/kinesis.ogg", "frequency":285.0, "duration":0.18, "gain":0.24, "noise":0.30},
    "instrumenta": {"path":"res://audio/combat/instrumenta.ogg", "frequency":245.0, "duration":0.22, "gain":0.26, "noise":0.18},
    "tarot_activate": {"path":"res://audio/combat/tarot_activate.ogg", "frequency":420.0, "duration":0.20, "gain":0.22, "noise":0.10},
    "enemy_windup": {"path":"res://audio/entities/enemy_windup.ogg", "frequency":128.0, "duration":0.20, "gain":0.23, "noise":0.34},
    "enemy_shot": {"path":"res://audio/entities/enemy_shot.ogg", "frequency":196.0, "duration":0.12, "gain":0.25, "noise":0.30},
    "projectile_impact": {"path":"res://audio/combat/projectile_impact.ogg", "frequency":108.0, "duration":0.14, "gain":0.28, "noise":0.62},
    "enemy_hit": {"path":"res://audio/entities/enemy_hit.ogg", "frequency":154.0, "duration":0.11, "gain":0.24, "noise":0.52},
    "enemy_death": {"path":"res://audio/entities/enemy_death.ogg", "frequency":84.0, "duration":0.24, "gain":0.27, "noise":0.48},
    "boss_windup": {"path":"res://audio/entities/boss_windup.ogg", "frequency":74.0, "duration":0.28, "gain":0.30, "noise":0.24},
    "boss_attack": {"path":"res://audio/entities/boss_attack.ogg", "frequency":132.0, "duration":0.18, "gain":0.32, "noise":0.38},
    "boss_phase": {"path":"res://audio/combat/boss_phase.ogg", "frequency":66.0, "duration":0.34, "gain":0.33, "noise":0.20},
    "boss_death": {"path":"res://audio/entities/boss_death.ogg", "frequency":54.0, "duration":0.42, "gain":0.34, "noise":0.42},
    "secret_break": {"path":"res://audio/ambience/secret_break.ogg", "frequency":98.0, "duration":0.22, "gain":0.28, "noise":0.66},
    "special_room_activate": {"path":"res://audio/ambience/special_room_activate.ogg", "frequency":232.0, "duration":0.24, "gain":0.24, "noise":0.16},
    "pickup": {"path":"res://audio/ui/pickup.ogg", "frequency":510.0, "duration":0.12, "gain":0.18, "noise":0.08},
    "power_reveal": {"path":"res://audio/combat/power_reveal.ogg", "frequency":310.0, "duration":0.18, "gain":0.22, "noise":0.14}
}

var streams: Dictionary = {}
var statuses: Dictionary = {}
var pool: Array[AudioStreamPlayer3D] = []
var ui_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
    for key in EVENT_SPECS:
        _resolve_event(String(key))
    for _i in range(16):
        var player := AudioStreamPlayer3D.new()
        player.max_distance = 30.0
        player.unit_size = 2.0
        add_child(player)
        pool.append(player)
    for _i in range(6):
        var player := AudioStreamPlayer.new()
        add_child(player)
        ui_pool.append(player)

func event_ids() -> Array:
    return EVENT_SPECS.keys()

func has_event(event_id: StringName) -> bool:
    var key := String(event_id)
    if not streams.has(key) and EVENT_SPECS.has(key):
        _resolve_event(key)
    return streams.has(key)

func event_status(event_id: StringName) -> String:
    var key := String(event_id)
    if not statuses.has(key) and EVENT_SPECS.has(key):
        _resolve_event(key)
    return String(statuses.get(key, "missing"))

func play_3d(event_id: StringName, position: Vector3) -> bool:
    var key := String(event_id)
    if not has_event(event_id):
        return false
    var player := _available_3d_player()
    if player == null:
        return false
    player.global_position = position
    player.stream = streams[key] as AudioStream
    player.pitch_scale = randf_range(0.97, 1.03)
    player.play()
    event_played.emit(event_id, position, true)
    return true

func play_ui(event_id: StringName) -> bool:
    var key := String(event_id)
    if not has_event(event_id):
        return false
    var player := _available_ui_player()
    if player == null:
        return false
    player.stream = streams[key] as AudioStream
    player.pitch_scale = 1.0
    player.play()
    event_played.emit(event_id, Vector3.ZERO, false)
    return true

func _resolve_event(key: String) -> void:
    if streams.has(key) or not EVENT_SPECS.has(key):
        return
    var spec: Dictionary = EVENT_SPECS[key]
    var path := String(spec.get("path", ""))
    if not path.is_empty() and ResourceLoader.exists(path):
        var resource = load(path)
        if resource is AudioStream:
            streams[key] = resource
            statuses[key] = "candidate"
            return
    streams[key] = _synthesize_placeholder(spec)
    statuses[key] = "placeholder"

func _synthesize_placeholder(spec: Dictionary) -> AudioStreamWAV:
    var duration := maxf(0.04, float(spec.get("duration", 0.12)))
    var frequency := maxf(32.0, float(spec.get("frequency", 180.0)))
    var gain := clampf(float(spec.get("gain", 0.22)), 0.02, 0.42)
    var noise_mix := clampf(float(spec.get("noise", 0.25)), 0.0, 0.85)
    var frames := maxi(1, int(duration * SAMPLE_RATE))
    var data := PackedByteArray()
    data.resize(frames * 2)
    for i in range(frames):
        var t := float(i) / float(SAMPLE_RATE)
        var progress := float(i) / float(frames)
        var attack := minf(1.0, progress / 0.08)
        var release := pow(maxf(0.0, 1.0 - progress), 1.7)
        var envelope := attack * release
        var fundamental := sin(TAU * frequency * t)
        var overtone := sin(TAU * frequency * 1.997 * t) * 0.28
        var pseudo_noise := sin(TAU * frequency * 3.71 * t + sin(t * 173.0) * 2.1)
        var sample_value := ((fundamental + overtone) * (1.0 - noise_mix) + pseudo_noise * noise_mix) * envelope * gain
        var sample_i := clampi(int(sample_value * 32767.0), -32768, 32767)
        data.encode_s16(i * 2, sample_i)
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = SAMPLE_RATE
    wav.stereo = false
    wav.data = data
    return wav

func _available_3d_player() -> AudioStreamPlayer3D:
    for player in pool:
        if not player.playing:
            return player
    return pool[0] if not pool.is_empty() else null

func _available_ui_player() -> AudioStreamPlayer:
    for player in ui_pool:
        if not player.playing:
            return player
    return ui_pool[0] if not ui_pool.is_empty() else null
