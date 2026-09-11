extends Node

signal feedback_emitted(event_id: StringName, position: Vector3)

const MAX_EMISSION := 0.55
const TELEGRAPH_MAX_EMISSION := 0.08
const EFFECTS := {
    "player_primary": {"color":Color(0.95,0.53,0.10), "size":0.16, "start_scale":0.52, "end_scale":0.52, "duration":0.16, "emission":0.34, "shape":"sphere", "travel":5.6},
    "player_power": {"color":Color(0.34,0.055,0.72), "size":0.38, "start_scale":0.62, "end_scale":1.72, "duration":0.28, "emission":0.42, "shape":"disc"},
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
    root.scale = Vector3.ONE * float(spec.get("start_scale", 0.45))
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
        call_deferred("_install_start_floor_tutorial", _player)
    elif node is RoomDirector:
        node.set_meta("audio_vfx_bound", true)
        (node as RoomDirector).room_entered.connect(_on_room_entered.bind(node as RoomDirector))

func _on_primary_requested(player: PlayerController) -> void:
    var now := Time.get_ticks_msec()
    if now < _primary_ready_at:
        return
    _primary_ready_at = now + 250
    var direction := _player_aim_direction(player)
    var origin := _player_primary_origin(player, direction)
    emit_feedback(&"player_primary", origin, direction)
    AudioDirector.play_3d(&"player_primary", origin)

func _on_power_requested(player: PlayerController) -> void:
    var direction := _player_aim_direction(player)
    var origin := _player_power_origin(player)
    emit_feedback(&"player_power", origin, direction)
    AudioDirector.play_3d(&"player_power", origin)

func _on_kinesis_requested(_slot: int, player: PlayerController) -> void:
    var origin := _player_feedback_origin(player)
    emit_feedback(&"kinesis", origin, _player_aim_direction(player))
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

func _player_aim_direction(player: PlayerController) -> Vector3:
    var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
    if camera != null:
        return (-camera.global_transform.basis.z).normalized()
    return (-player.global_transform.basis.z).normalized()

func _player_primary_origin(player: PlayerController, forward: Vector3) -> Vector3:
    var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
    var muzzle := player.get_node_or_null("Head/Camera3D/ViewModelRoot/LeftGauntlet/PrimaryMuzzle") as Node3D
    if camera != null and muzzle != null:
        var camera_to_origin := muzzle.global_position - camera.global_position
        if camera_to_origin.dot(forward) >= 0.30:
            return muzzle.global_position
        return camera.global_position + forward * 0.92 - camera.global_transform.basis.x * 0.28 - camera.global_transform.basis.y * 0.16
    return player.global_position + Vector3.UP * 1.20 + forward * 0.85

func _player_power_origin(player: PlayerController) -> Vector3:
    var orb := player.get_node_or_null("Head/Camera3D/ViewModelRoot/RightGauntlet/RightVoidOrb") as Node3D
    if orb != null:
        return orb.global_position
    return _player_feedback_origin(player)

func _player_feedback_origin(player: PlayerController) -> Vector3:
    var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
    if camera:
        return camera.global_position + _player_aim_direction(player) * 0.82
    return player.global_position + Vector3.UP * 1.2

func _install_start_floor_tutorial(player: PlayerController) -> void:
    if player == null or not is_instance_valid(player):
        return
    if String(GameState.current_stage_id) != "o_olho" or GameState.stage_index != 0:
        return
    var host := player.get_parent() as Node3D
    if host == null or host.get_node_or_null("TutorialFloorGuide") != null:
        return
    var guide := Node3D.new()
    guide.name = "TutorialFloorGuide"
    host.add_child(guide)
    guide.global_position = player.global_position + Vector3(0, -0.13, 0)
    guide.global_rotation.y = player.global_rotation.y
    _add_floor_instruction(guide, Vector3(0, 0.02, -1.35), "PORTAL 0 · CONTROLES", Color(0.86, 0.64, 0.26, 1.0), 3.8)
    _add_floor_instruction(guide, Vector3(0, 0.02, -2.10), "WASD · MOVER", Color(0.78, 0.72, 0.62, 1.0), 2.7)
    _add_floor_instruction(guide, Vector3(-1.75, 0.02, -2.90), "LMB · ATAQUE PRIMÁRIO\nDOURADO · RÁPIDO · SEM CUSTO DE FOCO", Color(0.95, 0.58, 0.16, 1.0), 3.2)
    _add_floor_instruction(guide, Vector3(1.75, 0.02, -2.90), "RMB · PODER INICIÁTICO\nVIOLETA · FORTE · CONSOME FOCO", Color(0.55, 0.28, 0.92, 1.0), 3.2)
    _add_floor_instruction(guide, Vector3(-1.75, 0.02, -3.80), "Q · ESQUIVA", Color(0.78, 0.72, 0.62, 1.0), 2.4)
    _add_floor_instruction(guide, Vector3(0, 0.02, -3.80), "V · CÂMERA", Color(0.78, 0.72, 0.62, 1.0), 2.4)
    _add_floor_instruction(guide, Vector3(1.75, 0.02, -3.80), "ESC · PAUSA", Color(0.78, 0.72, 0.62, 1.0), 2.4)

func _add_floor_instruction(parent: Node3D, local_position: Vector3, text: String, color: Color, width: float) -> void:
    var plaque := MeshInstance3D.new()
    var plaque_mesh := BoxMesh.new()
    plaque_mesh.size = Vector3(width, 0.018, 0.62)
    plaque.mesh = plaque_mesh
    plaque.position = local_position
    var plaque_material := StandardMaterial3D.new()
    plaque_material.albedo_color = Color(0.018, 0.015, 0.012, 0.96)
    plaque_material.metallic = 0.16
    plaque_material.roughness = 0.72
    plaque.material_override = plaque_material
    parent.add_child(plaque)

    var label := Label3D.new()
    label.text = text
    label.position = local_position + Vector3(0, 0.022, 0)
    label.rotation_degrees = Vector3(-90, 0, 0)
    label.font_size = 34
    label.pixel_size = 0.0052
    label.modulate = color
    label.outline_size = 8
    label.outline_modulate = Color(0.01, 0.008, 0.006, 1.0)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    parent.add_child(label)
