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

func begin_sequence(sequence_id: StringName, _sequence: Dictionary = {}) -> void:
    current_sequence_id = sequence_id
    active = true
    visible = true
    cinematic_camera.current = true
    drift_clock = 0.0

func end_sequence(sequence_id: StringName) -> void:
    if sequence_id == &"see_govern_make":
        handoff_ready.emit()

func prepare_gameplay_handoff(target_camera: Camera3D) -> void:
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

func _stage_proxy(visual_event: String, tension: float) -> void:
    _clear_proxies()
    var seed_value: int = absi(hash(visual_event + String(current_shot_id)))
    var count: int = 1 + (seed_value % 4)
    for i in range(count):
        var mesh_instance := MeshInstance3D.new()
        mesh_instance.name = "RuntimeProxy_%02d" % i
        if (seed_value + i) % 3 == 0:
            var sphere := SphereMesh.new()
            sphere.radius = 0.22 + 0.08 * i
            sphere.height = sphere.radius * 2.0
            mesh_instance.mesh = sphere
        elif (seed_value + i) % 3 == 1:
            var box := BoxMesh.new()
            box.size = Vector3(0.32 + i * 0.08, 0.5 + i * 0.06, 0.24 + i * 0.04)
            mesh_instance.mesh = box
        else:
            var torus := TorusMesh.new()
            torus.inner_radius = 0.18 + i * 0.04
            torus.outer_radius = 0.46 + i * 0.06
            mesh_instance.mesh = torus
        var material := StandardMaterial3D.new()
        var hue := fmod(float(seed_value % 1000) / 1000.0 + float(i) * 0.11, 1.0)
        material.albedo_color = Color.from_hsv(hue, 0.28 + tension * 0.45, 0.28 + tension * 0.52, 0.88)
        material.emission_enabled = true
        material.emission = material.albedo_color * (0.25 + tension * 0.45)
        material.emission_energy_multiplier = 0.8 + tension * 1.8
        mesh_instance.material_override = material
        mesh_instance.position = Vector3((float(i) - float(count - 1) * 0.5) * 0.72, sin(float(i) * 1.8) * 0.24, -2.6 - float(i) * 0.32)
        mesh_instance.rotation = Vector3(0.2 * i, 0.35 * i, 0.12 * i)
        mesh_instance.set_meta("asset_status", "proxy_runtime")
        mesh_instance.set_meta("visual_contract", visual_event)
        proxy_root.add_child(mesh_instance)
    proxy_asset_used.emit(StringName("proxy_runtime:" + String(current_shot_id)))

func _stage_light(tension: float) -> void:
    key_light.light_energy = lerpf(0.28, 1.2, tension)
    fill_light.light_energy = lerpf(0.08, 0.72, tension)
    fill_light.omni_range = lerpf(2.5, 6.5, tension)

func _clear_proxies() -> void:
    for child in proxy_root.get_children():
        child.queue_free()

func _process(delta: float) -> void:
    if not active:
        return
    drift_clock += delta
    proxy_root.rotation.y += delta * (0.015 + current_tension * 0.035)
    camera_rig.position.y += sin(drift_clock * 0.55) * delta * (0.002 + current_tension * 0.004)
