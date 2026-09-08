extends Node
class_name CameraModeController

signal mode_changed(mode: StringName)

const SETTINGS_PATH := "res://data/settings/camera_modes.json"
var mode: StringName = &"first_person"
var config: Dictionary = {}
var player: PlayerController
var world_camera: Camera3D
var first_person := true
var over_shoulder := false

func configure(target_player: PlayerController) -> void:
    player = target_player
    world_camera = player.camera if player != null else null
    config = _load_json(SETTINGS_PATH)
    set_mode(StringName(config.get("default", "first_person")))

func set_mode(next_mode: StringName) -> bool:
    if config.is_empty(): config = _load_json(SETTINGS_PATH)
    if not config.get("modes", {}).has(String(next_mode)): return false
    mode = next_mode
    first_person = mode == &"first_person"
    over_shoulder = mode == &"over_shoulder"
    if player != null and world_camera != null:
        var viewmodel := player.get_node_or_null("Head/Camera3D/ViewModelRoot") as Node3D
        var body_mesh := player.get_node_or_null("BodyMesh") as MeshInstance3D
        if first_person:
            world_camera.position = Vector3.ZERO
            if viewmodel: viewmodel.visible = true
            if body_mesh: body_mesh.visible = false
        else:
            var row: Dictionary = config.get("modes", {}).get("over_shoulder", {})
            world_camera.position = Vector3(float(row.get("side_offset", .55)), float(row.get("height", 1.45)) - 1.45, float(row.get("distance", 3.2)))
            if viewmodel: viewmodel.visible = false
            if body_mesh: body_mesh.visible = true
    mode_changed.emit(mode)
    return true

func toggle_mode() -> void:
    set_mode(&"over_shoulder" if first_person else &"first_person")

func _load_json(path: String) -> Dictionary:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return {}
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Dictionary else {}
