extends Node

signal feedback_emitted(event_id: StringName, position: Vector3)

const MAX_EMISSION := 0.55
const TELEGRAPH_MAX_EMISSION := 0.08
const EFFECTS := {
    "player_primary": {"color":Color(0.72,0.43,0.12), "size":0.20, "end_scale":1.0, "duration":0.10, "emission":0.24, "shape":"sphere", "travel":2.4},
    "player_power": {"color":Color(0.52,0.08,0.05), "size":0.34, "end_scale":2.8, "duration":0.22, "emission":0.30, "shape":"sphere"},
    "player_dodge": {"color":Color(0.31,0.13,0.55), "size":0.22, "end_scale":2.5, "duration":0.16, "emission":0.20, "shape":"disc"},
    "perfect_dodge": {"color":Color(0.95,0.57,0.12), "size":0.30, "end_scale":3.4, "duration":0.20, "emission":0.44, "shape":"disc"},
    "power_reveal": {"color":Color(0.91,0.39,0.08), "size":0.42, "end_scale":3.0, "duration":0.36, "emission":0.48, "shape":"disc"},
    "kinesis": {"color":Color(0.63,0.37,0.10), "size":0.27, "end_scale":2.5, "duration":0.17, "emission":0.22, "shape":"sphere"},
    "instrumenta": {"color":Color(0.74,0.46,0.14), "size":0.32, "end_scale":2.6, "duration":0.20, "emission":0.26, "shape":"disc"},
    "tarot_activate": {"color":Color(0.78,0.52,0.18), "size":0.30, "end_scale":2.4, "duration":0.22, "emission":0.24, "shape":"disc"},
    "player_hit": {"color":Color(0.48,0.04,0.03), "size":0.24, "end_scale":2.2, "duration":0.13, "emission":0.12, "shape":"sphere"},
    "enemy_windup": {"color":Color(0.38,0.035,0.025), "size":0.30, "end_scale":2.0, "duration":0.20, "emission":0.06, "shape":"sphere"},
    "enemy_telegraph": {"color":Color(0.42,0.025,0.018), "size":0.72, "end_scale":1.45, "duration":0.26, "emission":0.03, "shape":"disc"},
    "enemy_projectile": {"color":Color(0.68,0.31,0.07), "size":0.18, "end_scale":1.8, "duration":0.10, "emission":0.22, "shape":"sphere"},
    "projectile_travel": {"color":Color(0.62,0.32,0.08), "size":0.09, "end_scale":1.0, "duration":0.12, "emission":0.18, "shape":"sphere"},
    "projectile_impact": {"color":Color(0.76,0.38,0.08), "size":0.24, "end_scale":2.9, "duration":0.15, "emission":0.34, "shape":"sphere"},
    "enemy_hit": {"color":Color(0.52,0.05,0.025), "size":0.22, "end_scale":2.2, "duration":0.11, "emission":0.13, "shape":"sphere"},
    "enemy_death": {"color":Color(0.31,0.025,0.018), "size":0.38, "end_scale":3.0, "duration":0.28, "emission":0.10, "shape":"disc"},
    "boss_windup": {"color":Color(0.48,0.035,0.02), "size":0.62, "end_scale":2.2, "duration":0.28, "emission":0.06, "shape":"sphere"},
    "boss_attack": {"color":Color(0.70,0.26,0.05), "size":0.50, "end_scale":2.8, "duration":0.18, "emission":0.30, "shape":"sphere"},
    "boss_phase": {"color":Color(0.72,0.44,0.11), "size":0.82, "end_scale":3.2, "duration":0.42, "emission":0.38, "shape":"disc"},
    "boss_death": {"color":Color(0.56,0.07,0.025), "size":0.94, "end_scale":3.8, "duration":0.58, "emission":0.34, "shape":"disc"},
    "pickup": {"color":Color(0.78,0.54,0.20), "size":0.22, "end_scale":2.5, "duration":0.18, "emission":0.22, "shape":"sphere"},
    "secret_rupture": {"color":Color(0.50,0.04,0.025), "size":0.48, "end_scale":3.2, "duration":0.30, "emission":0.18, "shape":"disc"},
    "special_room_activate": {"color":Color(0.62,0.38,0.10), "size":0.56, "end_scale":2.7, "duration":0.30, "emission":0.18, "shape":"disc"}
}

var _player: PlayerController
var _primary_ready_at := 0

func _ready() -> void:
    AudioDirector.event_played.connect(_on_audio_event)
    RogueliteContentService.effect_requested.connect(_on_content_effect)
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_scan_existing")

func has_effect(event_id: StringName) -> bool:
    return EFFECTS.has(String(event_id))

func effect_emission(event_id: StringName) -> float:
    var key := String(event_id)
    if not EFFECTS.has(key):
        return 0.0
    var cap := TELEGRAPH_MAX_EMISSION if key.contains("telegraph") else MAX_EMISSION
    return minf(cap, float((EFFECTS[key] as Dictionary).get("emission", 0.0)))

func emit_feedback(event_id: StringName, position: Vector3, direction: Vector3 = Vector3.UP, payload: Dictionary = {}) -> Node3D:
    var key := String(event_id)
    if not EFFECTS.has(key):
        return null
    if DisplayServer.get_name() == "headless":
        feedback_emitted.emit(event_id, position)
        return null
    var spec: Dictionary = EFFECTS[key]
    var root := Node3D.new()
    root.name = "VFX_%s" % key
    root.set_meta("feedback_event", key)
    root.set_meta("payload", payload)
    add_child(root)
    root.global_position = position
    if direction.length_squared() > 0.001:
        root.set_meta("direction", direction.normalized())
    var mesh_instance := MeshInstance3D.new()
    root.add_child(mesh_instance)
    var size := float(spec.get("size", 0.25))
    if String(spec.get("shape", "sphere")) == "disc":
        var mesh := CylinderMesh.new()
        mesh.top_radius = size
        mesh.bottom_radius = size
        mesh.height = maxf(0.018, size * 0.035)
        mesh_instance.mesh = mesh
    else:
        var mesh := SphereMesh.new()
        mesh.radius = size * 0.5
        mesh.height = size
        mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    var color: Color = spec.get("color", Color(0.55, 0.24, 0.05))
    material.albedo_color = color
    material.roughness = 0.58
    var emission := effect_emission(event_id)
    material.emission_enabled = emission > 0.0
    if material.emission_enabled:
        material.emission = color
        material.emission_energy_multiplier = emission
    mesh_instance.material_override = material
    root.scale = Vector3.ONE * 0.45
    var duration := float(spec.get("duration", 0.18))
    var travel := float(spec.get("travel", 0.0))
    var tween := root.create_tween().set_parallel(true)
    tween.tween_property(root, "scale", Vector3.ONE * float(spec.get("end_scale", 2.0)), duration)
    if travel > 0.0 and direction.length_squared() > 0.001:
        tween.tween_property(root, "global_position", position + direction.normalized() * travel, duration)
    tween.chain().tween_callback(Callable(root, "queue_free"))
    feedback_emitted.emit(event_id, position)
    return root

func _scan_existing() -> void:
    var scene := get_tree().current_scene
    if scene:
        _scan_node(scene)

func _scan_node(node: Node) -> void:
    _bind_node(node)
    for child in node.get_children():
        _scan_node(child)

func _on_node_added(node: Node) -> void:
    call_deferred("_bind_node", node)

func _bind_node(node: Node) -> void:
    if not is_instance_valid(node) or node.has_meta("audio_vfx_bound"):
        return
    if node is PlayerController:
        node.set_meta("audio_vfx_bound", true)
        _player = node as PlayerController
        _player.primary_attack_requested.connect(_on_primary_requested.bind(_player))
        _player.power_requested.connect(_on_power_requested.bind(_player))
        _player.kinesis_slot_requested.connect(_on_kinesis_requested.bind(_player))
    elif node is RoomDirector:
        node.set_meta("audio_vfx_bound", true)
        (node as RoomDirector).room_entered.connect(_on_room_entered.bind(node as RoomDirector))

func _on_primary_requested(player: PlayerController) -> void:
    var now := Time.get_ticks_msec()
    if now < _primary_ready_at:
        return
    _primary_ready_at = now + 250
    var origin := _player_feedback_origin(player)
    var direction := -player.global_transform.basis.z
    emit_feedback(&"player_primary", origin, direction)
    AudioDirector.play_3d(&"player_primary", origin)

func _on_power_requested(player: PlayerController) -> void:
    var origin := _player_feedback_origin(player)
    emit_feedback(&"player_power", origin, -player.global_transform.basis.z)
    AudioDirector.play_3d(&"player_power", origin)

func _on_kinesis_requested(_slot: int, player: PlayerController) -> void:
    var origin := _player_feedback_origin(player)
    emit_feedback(&"kinesis", origin, -player.global_transform.basis.z)
    AudioDirector.play_3d(&"kinesis", origin)

func _on_content_effect(_effect_id: StringName, payload: Dictionary) -> void:
    var player := _active_player()
    if player == null:
        return
    var origin := _player_feedback_origin(player)
    if payload.has("card"):
        emit_feedback(&"tarot_activate", origin, Vector3.UP)
        AudioDirector.play_3d(&"tarot_activate", origin)
    elif payload.has("item"):
        emit_feedback(&"instrumenta", origin, Vector3.UP)
        AudioDirector.play_3d(&"instrumenta", origin)

func _on_room_entered(room_id: StringName, director: RoomDirector) -> void:
    if ContentRegistry.get_item("special_rooms", room_id).is_empty():
        return
    var room = director.rooms.get(room_id)
    var position := (_active_player().global_position if _active_player() else Vector3.ZERO)
    if room is Node3D:
        position = (room as Node3D).global_position + Vector3.UP * 0.05
    emit_feedback(&"special_room_activate", position, Vector3.UP, {"room_id":String(room_id)})
    AudioDirector.play_3d(&"special_room_activate", position)

func _on_audio_event(event_id: StringName, position: Vector3, spatial: bool) -> void:
    match String(event_id):
        "enemy_shot": emit_feedback(&"enemy_projectile", position, Vector3.UP)
        "secret_break": emit_feedback(&"secret_rupture", position, Vector3.UP)
        "power_reveal":
            var reveal_position := position if spatial else (_active_player().global_position + Vector3.UP if _active_player() else Vector3.ZERO)
            emit_feedback(&"power_reveal", reveal_position, Vector3.UP)
        "player_hit":
            var hit_position := position if spatial else (_active_player().global_position if _active_player() else Vector3.ZERO)
            emit_feedback(&"player_hit", hit_position, Vector3.UP)

func _active_player() -> PlayerController:
    return _player if is_instance_valid(_player) else null

func _player_feedback_origin(player: PlayerController) -> Vector3:
    var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
    if camera:
        return camera.global_position + (-camera.global_transform.basis.z * 0.72)
    return player.global_position + Vector3.UP * 1.2
