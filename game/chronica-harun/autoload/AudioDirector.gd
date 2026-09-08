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
var streams: Dictionary = {}
var pool: Array[AudioStreamPlayer3D] = []
var warned: Dictionary = {}

func _ready() -> void:
    for key in EVENT_PATHS:
        var path := String(EVENT_PATHS[key])
        if ResourceLoader.exists(path):
            streams[key] = load(path)
    for _i in range(12):
        var player := AudioStreamPlayer3D.new()
        player.max_distance = 28.0
        player.unit_size = 2.0
        add_child(player)
        pool.append(player)

func play_3d(event_id: StringName, position: Vector3) -> void:
    var key := String(event_id)
    if not streams.has(key):
        if not warned.has(key):
            warned[key] = true
            push_warning("Audio event not installed: %s" % key)
        return
    for player in pool:
        if not player.playing:
            player.global_position = position
            player.stream = streams[key]
            player.pitch_scale = randf_range(0.97, 1.03)
            player.play()
            return

func play_ui(event_id: StringName) -> void:
    var key := String(event_id)
    if not streams.has(key):
        return
    var player := AudioStreamPlayer.new()
    add_child(player)
    player.stream = streams[key]
    player.finished.connect(player.queue_free)
    player.play()
