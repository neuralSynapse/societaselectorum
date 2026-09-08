extends Node3D
class_name CinematicPresentationDirector

signal shot_staged(sequence_id: StringName, shot_id: StringName)
signal transition_started(kind: StringName, tension: float)
signal proxy_asset_used(asset_key: StringName)
signal handoff_ready

@onready var camera_rig: Node3D = $CameraRig
@onready var cinematic_camera: Camera3D = $CameraRig/CinematicCamera
@onready var proxy_root: Node3D = $ProxyRoot
@onready var key_light: DirectionalLight3D = $KeyLight
@onready var fill_light: OmniLight3D = $FillLight

var active := false
var current_sequence_id: StringName = &""
var current_shot_id: StringName = &""
var current_tension := 0.0
var drift_clock := 0.0
var base_rig_position := Vector3.ZERO
var base_rig_rotation := Vector3.ZERO

func _ready() -> void:
    visible = false
    cinematic_camera.current = false
    base_rig_position = camera_rig.position
    base_rig_rotation = camera_rig.rotation
    var bridge := get_parent() as NarrativeRuntimeBridge
    if bridge != null:
        bind_bridge(bridge)

func bind_bridge(bridge: NarrativeRuntimeBridge) -> void:
    if not bridge.cinematic_sequence_started.is_connected(begin_sequence):
        bridge.cinematic_sequence_started.connect(begin_sequence)
    if not bridge.cinematic_sequence_finished.is_connected(end_sequence):
        bridge.cinematic_sequence_finished.connect(end_sequence)
    if not bridge.cinematic_visual.is_connected(stage_payload):
        bridge.cinematic_visual.connect(stage_payload)

func can_take_player_control() -> bool:
    # The current cinematic manifest is entirely proxy_runtime. Until real
    # player-facing cinematic assets exist, the presentation layer must never
    # steal the gameplay camera or disable the world.
    return false

func begin_sequence(sequence_id: StringName, _sequence: Dictionary = {}) -> void:
    current_sequence_id = sequence_id
    if not can_take_player_control():
        active = false
        visible = false
        cinematic_camera.current = false
        _clear_proxies()
        return
    active = true
    visible = true
    cinematic_camera.current = true
    drift_clock = 0.0

func end_sequence(sequence_id: StringName) -> void:
    if sequence_id == &"see_govern_make":
        handoff_ready.emit()

func prepare_gameplay_handoff(target_camera: Camera3D) -> void:
    if not can_take_player_control():
        release_camera()
        handoff_ready.emit()
        return
    _clear_proxies()
    if target_camera == null:
        handoff_ready.emit()
        return
    camera_rig.global_transform = target_camera.global_transform
    cinematic_camera.position = Vector3.ZERO
    cinematic_camera.rotation = Vector3.ZERO
    cinematic_camera.fov = target_camera.fov
    cinematic_camera.current = true
    handoff_ready.emit()

func release_camera() -> void:
    active = false
    cinematic_camera.current = false
    visible = false
    _clear_proxies()

func stage_payload(payload: Dictionary) -> void:
    var sequence_id := StringName(payload.get("sequence_id", current_sequence_id))
    var shot_id := StringName(payload.get("shot_id", ""))
    stage_shot(sequence_id, shot_id, payload)

func stage_shot(sequence_id: StringName, shot_id: StringName, shot: Dictionary) -> void:
    current_sequence_id = sequence_id
    current_shot_id = shot_id
    current_tension = clampf(float(shot.get("tension", 0.0)), 0.0, 1.0)
    if not can_take_player_control():
        _clear_proxies()
        proxy_asset_used.emit(StringName("proxy_runtime:" + String(current_shot_id)))
        return
    if not active:
        begin_sequence(sequence_id)
    begin_transition(StringName(shot.get("transition", "cut")), current_tension)
    _stage_camera(String(shot.get("camera", "")), current_tension)
    _stage_proxy(String(shot.get("shot", shot.get("visual_event", ""))), current_tension)
    _stage_light(current_tension)
    shot_staged.emit(sequence_id, shot_id)

func begin_transition(kind: StringName, tension: float) -> void:
    transition_started.emit(kind, tension)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    match String(kind):
        "hard_reframe", "hard_cut_to_black":
            camera_rig.rotation = base_rig_rotation + Vector3(0.0, 0.0, deg_to_rad(0.8 + tension * 1.4))
            tween.tween_property(camera_rig, "rotation", base_rig_rotation, 0.22)
        "match_cut":
            camera_rig.position = base_rig_position + Vector3(0.16, 0.0, 0.22)
            tween.tween_property(camera_rig, "position", base_rig_position, 0.55)
        "slow_dissolve", "focus_pull":
            cinematic_camera.fov = 58.0
            tween.tween_property(cinematic_camera, "fov", 67.0, 1.1)
        _:
            tween.tween_property(cinematic_camera, "fov", 64.0 + tension * 5.0, 0.6)

func _stage_camera(contract: String, tension: float) -> void:
    var low := contract.to_lower()
    var target_pos := Vector3.ZERO
    var target_rot := Vector3.ZERO
    var target_fov := 68.0
    if low.contains("sem horizonte"):
        target_pos = Vector3(0.0, 0.35, 1.8)
        target_rot = Vector3(deg_to_rad(-7.0), deg_to_rad(-5.0), deg_to_rad(1.5))
        target_fov = 76.0
    elif low.contains("travessia lenta") or low.contains("slow lateral"):
        target_pos = Vector3(-1.6, 0.45, 2.4)
        target_rot = Vector3(deg_to_rad(-3.0), deg_to_rad(12.0), 0.0)
        target_fov = 70.0
    elif low.contains("aproximação") or low.contains("push"):
        target_pos = Vector3(0.0, 0.3, 1.2)
        target_rot = Vector3(deg_to_rad(-2.0), 0.0, 0.0)
        target_fov = 56.0
    elif low.contains("íntima") or low.contains("close") or low.contains("macro"):
        target_pos = Vector3(0.35, 0.2, 0.85)
        target_rot = Vector3(deg_to_rad(-1.5), deg_to_rad(-7.0), 0.0)
        target_fov = 50.0
    elif low.contains("match cuts"):
        target_pos = Vector3(-0.75, 0.2, 1.4)
        target_rot = Vector3(0.0, deg_to_rad(8.0), 0.0)
        target_fov = 62.0
    elif low.contains("primeira pessoa") or low.contains("first-person") or low.contains("first person"):
        target_pos = Vector3(0.0, 0.05, 0.25)
        target_rot = Vector3.ZERO
        target_fov = 74.0
    else:
        target_pos = Vector3(0.0, 0.25, 1.65)
        target_rot = Vector3(deg_to_rad(-2.0), deg_to_rad(4.0 * tension), 0.0)
        target_fov = 66.0
    var tween := create_tween().set_parallel(true)
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(camera_rig, "position", target_pos, 1.0 + tension * 1.2)
    tween.tween_property(camera_rig, "rotation", target_rot, 1.0 + tension * 1.2)
    tween.tween_property(cinematic_camera, "fov", target_fov, 0.9)

func _stage_proxy(_visual_event: String, _tension: float) -> void:
    # Keep proxy_runtime as an internal evidence state only. Player-facing
    # builds must never render primitive placeholder geometry.
    _clear_proxies()
    proxy_asset_used.emit(StringName("proxy_runtime:" + String(current_shot_id)))

func _stage_light(tension: float) -> void:
    key_light.light_energy = lerpf(0.55, 1.2, tension)
    fill_light.light_energy = lerpf(0.28, 0.72, tension)
    fill_light.omni_range = lerpf(5.0, 7.5, tension)

func _clear_proxies() -> void:
    for child in proxy_root.get_children():
        child.queue_free()

func _process(delta: float) -> void:
    if not active:
        return
    drift_clock += delta
    proxy_root.rotation.y += delta * (0.015 + current_tension * 0.035)
    camera_rig.position.y += sin(drift_clock * 0.55) * delta * (0.002 + current_tension * 0.004)
