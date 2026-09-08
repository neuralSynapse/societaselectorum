extends Node

const SAVE_PATH := "user://chronica_harun_campaign.json"
const RETRY_SENTINEL := "user://windows_native_qa_retry_sentinel.txt"
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const REQUIRED_INPUTS: Array[StringName] = [
    &"move_left", &"move_right", &"move_forward", &"move_back",
    &"jump", &"interact", &"primary_attack", &"power", &"instrument",
    &"consume", &"sprint", &"rupture_charge", &"pause", &"camera_toggle",
    &"kinesis_1", &"kinesis_2", &"kinesis_3"
]

var failures: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _fail(label: String) -> void:
    failures.append(label)
    push_error("WINDOWS_QA_FAIL " + label)

func _expect(condition: bool, label: String) -> void:
    if not condition:
        _fail(label)

func _remove_user_file(path: String) -> void:
    if FileAccess.file_exists(path):
        var absolute := ProjectSettings.globalize_path(path)
        var code := DirAccess.remove_absolute(absolute)
        if code != OK:
            _fail("cannot_remove_" + path.get_file())

func _finish() -> void:
    if failures.is_empty():
        print("WINDOWS_QA_RUNTIME_PASS")
        get_tree().quit(0)
    else:
        print("WINDOWS_QA_FAILURES=", failures)
        get_tree().quit(1)

func _make_test_floor() -> StaticBody3D:
    var body := StaticBody3D.new()
    body.collision_layer = 2
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(20.0, 0.2, 20.0)
    shape.shape = box
    shape.position = Vector3(0.0, -0.1, 0.0)
    body.add_child(shape)
    return body

func _probe_lateral_movement() -> void:
    var arena := Node3D.new()
    add_child(arena)
    arena.add_child(_make_test_floor())
    var player := PLAYER_SCENE.instantiate() as PlayerController
    arena.add_child(player)
    player.global_position = Vector3(0.0, 0.15, 0.0)
    await get_tree().physics_frame
    var start_x := player.global_position.x
    Input.action_press(&"move_right")
    for _i in range(18):
        await get_tree().physics_frame
    Input.action_release(&"move_right")
    var right_x := player.global_position.x
    _expect(right_x > start_x + 0.20, "move_right_no_lateral_displacement")
    Input.action_press(&"move_left")
    for _i in range(18):
        await get_tree().physics_frame
    Input.action_release(&"move_left")
    var left_x := player.global_position.x
    _expect(left_x < right_x - 0.20, "move_left_no_lateral_displacement")
    print("WINDOWS_QA_LATERAL_MOVEMENT_PASS")
    arena.queue_free()
    await get_tree().process_frame

func _probe_floor_collision_contract() -> void:
    var stage := {"id":"o_olho", "index":0}
    var floor := StageFloorBuilder.build(stage, 424242, 0, {})
    add_child(floor)
    var corridors := floor.get_node("Corridors") as Node3D
    _expect(corridors.get_child_count() > 0, "corridors_missing")
    for corridor in corridors.get_children():
        _expect(corridor is StaticBody3D, "corridor_missing_static_body_collision")
        if corridor is StaticBody3D:
            _expect(corridor.get_node_or_null("CollisionShape3D") != null, "corridor_missing_collision_shape")
    print("WINDOWS_QA_FLOOR_COLLISION_PASS")
    floor.queue_free()
    await get_tree().process_frame

func _probe_pause_contract() -> void:
    var hud_scene := load("res://scenes/ui/HUD.tscn") as PackedScene
    var hud := hud_scene.instantiate()
    add_child(hud)
    _expect(hud.get_node_or_null("Root/PausePanel") != null, "pause_panel_missing")
    var main_script := load("res://scripts/boot/Main.gd")
    var main_probe := main_script.new()
    _expect(main_probe.has_method("set_pause_state"), "main_pause_state_handler_missing")
    main_probe.free()
    hud.queue_free()
    await get_tree().process_frame
    print("WINDOWS_QA_PAUSE_CONTRACT_PASS")

func _probe_fall_recovery_contract() -> void:
    var player_script_text := FileAccess.get_file_as_string("res://scripts/player/PlayerController.gd")
    _expect(player_script_text.contains("fall_recovery_y"), "player_fall_recovery_threshold_missing")
    _expect(player_script_text.contains("safe_position"), "player_safe_position_missing")
    print("WINDOWS_QA_FALL_RECOVERY_CONTRACT_PASS")

func _run() -> void:
    _expect(OS.get_name() == "Windows", "os_not_windows")
    print("WINDOWS_QA_OS=", OS.get_name())
    print("WINDOWS_QA_DISPLAY_DRIVER=", DisplayServer.get_name())

    var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
    _expect(main_scene == "res://scenes/boot/Main.tscn", "main_scene_mismatch")
    print("WINDOWS_QA_MAIN_SCENE=", main_scene)

    var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)
    _expect(save_absolute.is_absolute_path(), "save_path_not_absolute")
    _expect(save_absolute.contains(":/") or save_absolute.contains(":\\"), "save_path_not_windows")
    print("WINDOWS_QA_SAVE_PATH=", save_absolute)

    var retry_phase := FileAccess.file_exists(RETRY_SENTINEL)
    if retry_phase:
        _remove_user_file(RETRY_SENTINEL)
        var retry_snapshot := SaveService.load_campaign()
        _expect(not retry_snapshot.is_empty(), "retry_save_missing")
        if not retry_snapshot.is_empty():
            GameState.load_save_data(retry_snapshot)
        _expect(int(GameState.run_stats.get("windows_qa_retry_marker", -1)) == 77, "retry_state_not_restored")
        print("WINDOWS_QA_RETRY_PASS")
        _finish()
        return

    _remove_user_file(SAVE_PATH)
    GameState.start_new_campaign(424242)
    _expect(String(GameState.selected_character_id) == "harun", "new_campaign_character")
    _expect(String(GameState.current_stage_id) == "o_olho", "new_campaign_stage")
    _expect(GameState.stage_index == 0, "new_campaign_stage_index")
    _expect(GameState.run_seed == 424242, "new_campaign_seed")
    print("WINDOWS_QA_NEW_CAMPAIGN_PASS")

    GameState.run_stats["windows_qa_marker"] = 1234
    _expect(SaveService.save_campaign(GameState.to_save_data()), "save_campaign_failed")
    GameState.run_stats["windows_qa_marker"] = -1
    var loaded := SaveService.load_campaign()
    _expect(not loaded.is_empty(), "load_campaign_empty")
    if not loaded.is_empty():
        GameState.load_save_data(loaded)
    _expect(int(GameState.run_stats.get("windows_qa_marker", -1)) == 1234, "save_load_roundtrip")
    print("WINDOWS_QA_SAVE_LOAD_PASS")

    for action in REQUIRED_INPUTS:
        _expect(InputMap.has_action(action), "missing_input_" + String(action))
    print("WINDOWS_QA_INPUT_PASS")

    await _probe_lateral_movement()
    await _probe_floor_collision_contract()
    await _probe_pause_contract()
    _probe_fall_recovery_contract()

    var camera_modes := CameraModeController.new()
    add_child(camera_modes)
    camera_modes.configure(null)
    _expect(camera_modes.mode == &"first_person", "camera_default_not_first_person")
    camera_modes.toggle_mode()
    _expect(camera_modes.mode == &"over_shoulder", "camera_toggle_to_over_shoulder")
    camera_modes.toggle_mode()
    _expect(camera_modes.mode == &"first_person", "camera_toggle_back_first_person")
    print("WINDOWS_QA_CAMERA_PASS")

    var viewport_width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
    var viewport_height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
    var window_width := int(ProjectSettings.get_setting("display/window/size/window_width_override", 0))
    var window_height := int(ProjectSettings.get_setting("display/window/size/window_height_override", 0))
    _expect(viewport_width == 1920 and viewport_height == 1080, "viewport_resolution_mismatch")
    _expect(window_width == 1280 and window_height == 720, "window_resolution_mismatch")
    print("WINDOWS_QA_VIEWPORT=", viewport_width, "x", viewport_height)
    print("WINDOWS_QA_WINDOW_OVERRIDE=", window_width, "x", window_height)
    print("WINDOWS_QA_ENGINE_MAX_FPS=", Engine.max_fps)

    var manifest_file := FileAccess.open("res://distribution/release_manifest.json", FileAccess.READ)
    _expect(manifest_file != null, "release_manifest_unreadable")
    if manifest_file != null:
        var manifest = JSON.parse_string(manifest_file.get_as_text())
        _expect(manifest is Dictionary, "release_manifest_invalid_json")
        if manifest is Dictionary:
            var presets: Dictionary = manifest.get("quality_presets", {})
            var preset_1080: Dictionary = presets.get("1080p", {})
            _expect(int(preset_1080.get("target_fps", 0)) == 60, "quality_target_fps_mismatch")
            print("WINDOWS_QA_QUALITY_TARGET_FPS=", int(preset_1080.get("target_fps", 0)))

    if not failures.is_empty():
        _finish()
        return

    GameState.run_stats["windows_qa_retry_marker"] = 77
    _expect(SaveService.save_campaign(GameState.to_save_data()), "retry_save_campaign_failed")
    var sentinel := FileAccess.open(RETRY_SENTINEL, FileAccess.WRITE)
    _expect(sentinel != null, "retry_sentinel_open_failed")
    if sentinel != null:
        sentinel.store_string("reload")
    if not failures.is_empty():
        _finish()
        return
    print("WINDOWS_QA_RETRY_PHASE_1")
    get_tree().reload_current_scene()
