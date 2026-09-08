extends Node

const MAIN_SCENE := preload("res://scenes/boot/Main.tscn")
const RETRY_SENTINEL := "user://chronica_player_probe_retry.txt"
const FAILURE_PATH := "user://chronica_player_probe_failures.json"

var failures: Array[String] = []
var main: Node
var stage: StageDirector
var player: PlayerController

func _ready() -> void:
    call_deferred("_run")

func _fail(label: String) -> void:
    failures.append(label)
    push_error("PLAYER_QA_FAIL " + label)

func _expect(condition: bool, label: String) -> void:
    if not condition:
        _fail(label)

func _wait_frames(count: int) -> void:
    for _index in count:
        await get_tree().process_frame

func _wait_seconds(seconds: float) -> void:
    await get_tree().create_timer(seconds, true).timeout

func _remove_user_file(path: String) -> void:
    if not FileAccess.file_exists(path):
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish() -> void:
    if failures.is_empty():
        print("PLAYER_GAMEPLAY_RUNTIME_PASS")
        get_tree().quit(0)
    else:
        print("PLAYER_GAMEPLAY_RUNTIME_FAILURES=", failures)
        get_tree().quit(1)

func _run() -> void:
    if FileAccess.file_exists(RETRY_SENTINEL):
        await _run_reload_phase()
        return

    _remove_user_file(SaveService.SAVE_PATH)
    GameState.start_new_campaign(9012026)
    _expect(SaveService.save_campaign(GameState.to_save_data()), "initial_save_failed")

    main = MAIN_SCENE.instantiate()
    add_child(main)
    await _wait_frames(8)
    stage = main.get_node_or_null("StageDirector") as StageDirector
    player = stage.player if stage != null else null
    _expect(stage != null, "stage_director_missing")
    _expect(player != null, "player_missing")
    if player == null or stage == null:
        _finish()
        return

    var main_gameplay := bool(main.get("gameplay_enabled"))
    _expect(main_gameplay, "first_boot_gameplay_disabled")
    var world_root := main.get_node_or_null("WorldRoot") as Node3D
    _expect(world_root != null and world_root.visible, "world_hidden_on_first_boot")
    _expect(world_root != null and world_root.process_mode != Node.PROCESS_MODE_DISABLED, "world_disabled_on_first_boot")
    _expect(player.process_mode != Node.PROCESS_MODE_DISABLED, "player_disabled_on_first_boot")
    _expect(player.camera.current, "player_camera_not_current_on_first_boot")
    if DisplayServer.get_name() not in ["headless", "dummy"]:
        _expect(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse_not_captured_on_first_boot")

    var camera_modes := stage.world_expansion.camera_modes if stage.world_expansion != null else null
    _expect(camera_modes != null and camera_modes.mode == &"first_person", "first_person_not_default")
    if camera_modes != null:
        camera_modes.toggle_mode()
        _expect(camera_modes.mode == &"over_shoulder", "camera_toggle_did_not_switch")
        camera_modes.toggle_mode()
        _expect(camera_modes.mode == &"first_person", "camera_toggle_did_not_restore")

    var threshold := stage.room_director.rooms.get(&"threshold") as RoomShell
    _expect(threshold != null, "threshold_missing")
    var start_position := player.global_position
    Input.action_press("move_right")
    await _wait_seconds(1.2)
    Input.action_release("move_right")
    print("PLAYER_QA_INPUT left=", Input.is_action_pressed("move_left"), " right=", Input.is_action_pressed("move_right"), " forward=", Input.is_action_pressed("move_forward"), " back=", Input.is_action_pressed("move_back"))
    _expect(player.global_position.x > start_position.x + 2.0, "wasd_movement_not_applied")

    player.set_physics_process(false)
    await _visit_room(&"combat_1")
    print("PLAYER_QA_COMBAT_POS player=", player.global_position, " room=", (stage._room("combat_1") as RoomShell).global_position)
    _expect(stage.room_director.active_room == &"combat_1", "combat_room_not_entered")
    _expect(not stage.active_enemies.is_empty(), "combat_enemies_not_spawned")
    if not stage.active_enemies.is_empty():
        var first_enemy := stage.active_enemies[0] as DataEnemy
        var before_health := first_enemy.health.current_health
        var visual := first_enemy.get_node_or_null("Visual") as Node3D
        var model_loaded := false
        if visual != null:
            for visual_child in visual.get_children():
                if not String(visual_child.name).begins_with("Fallback_"):
                    model_loaded = true
                    break
        _expect(model_loaded, "generated_enemy_model_not_loaded")
        _face_target(first_enemy)
        await _wait_frames(1)
        player.interaction_ray.force_raycast_update()
        print("PLAYER_QA_AIM_COLLIDER=", player.interaction_ray.get_collider(), " target=", first_enemy.global_position, " camera=", player.camera.global_position, " ray=", player.interaction_ray.global_position, " ray_target=", player.interaction_ray.target_position, " mask=", player.interaction_ray.collision_mask, " enabled=", player.interaction_ray.enabled, " rot=", player.rotation)
        var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, first_enemy.global_position + Vector3.UP * 0.6, 14)
        print("PLAYER_QA_DIRECT_RAY=", player.get_world_3d().direct_space_state.intersect_ray(query))
        player.primary_attack_requested.emit()
        await _wait_seconds(0.38)
        _expect(first_enemy.health.current_health < before_health, "primary_attack_missed_enemy")
        await _kill_active_enemies()
    _expect((stage._room("combat_1") as RoomShell).cleared, "combat_room_not_cleared")
    player.set_physics_process(true)

    var build_before := GameState.run_build.duplicate(true)
    await _visit_room(&"reward_1")
    await _wait_frames(3)
    var reward := stage._room("reward_1") as RoomShell
    var pickup := reward.get_node_or_null("WorldPickup") as PickupController if reward != null else null
    _expect(pickup != null, "reward_pickup_not_spawned")
    if pickup != null:
        _expect(pickup.interact(player), "reward_pickup_not_collectible")
        await _wait_frames(2)
    _expect(GameState.run_build != build_before, "build_did_not_change_after_pickup")
    get_tree().paused = false

    for room_id in [&"combat_2", &"sanctuary", &"combat_3"]:
        await _visit_room(room_id)
        if String(room_id).begins_with("combat_"):
            await _kill_active_enemies()
            get_tree().paused = false

    await _visit_room(&"boss")
    await _wait_frames(5)
    var boss := stage.boss
    _expect(boss != null, "boss_not_reachable")
    if boss != null:
        boss.apply_damage(310.0, &"player_primary")
        await _wait_seconds(0.22)
        _expect(boss.current_phase >= 1, "boss_phase_two_not_reached")
        boss.apply_damage(310.0, &"player_primary")
        await _wait_seconds(0.22)
        _expect(boss.current_phase >= 2, "boss_phase_three_not_reached")
        boss.apply_damage(400.0, &"player_primary")
        await _wait_seconds(1.0)
        _expect(GameState.completion_marks.has("o_olho"), "boss_completion_not_recorded")

    GameState.run_stats["player_probe_marker"] = 77
    _expect(GameState.save_run(), "save_run_failed")
    var snapshot := SaveService.load_campaign()
    _expect(int(snapshot.get("run_stats", {}).get("player_probe_marker", -1)) == 77, "save_load_roundtrip_failed")

    var retry_file := FileAccess.open(RETRY_SENTINEL, FileAccess.WRITE)
    _expect(retry_file != null, "retry_sentinel_failed")
    if retry_file != null:
        retry_file.store_string("reload")
    var failure_file := FileAccess.open(FAILURE_PATH, FileAccess.WRITE)
    if failure_file != null:
        failure_file.store_string(JSON.stringify(failures))
    player.apply_damage(1000.0, &"player_probe")
    await _wait_seconds(2.2)
    _fail("retry_scene_did_not_reload")
    _finish()

func _run_reload_phase() -> void:
    _remove_user_file(RETRY_SENTINEL)
    var previous_failures := FileAccess.open(FAILURE_PATH, FileAccess.READ)
    if previous_failures != null:
        var parsed = JSON.parse_string(previous_failures.get_as_text())
        if parsed is Array:
            for failure in parsed:
                failures.append(String(failure))
    _remove_user_file(FAILURE_PATH)
    main = MAIN_SCENE.instantiate()
    add_child(main)
    await _wait_frames(8)
    stage = main.get_node_or_null("StageDirector") as StageDirector
    player = stage.player if stage != null else null
    var snapshot := SaveService.load_campaign()
    _expect(not snapshot.is_empty(), "reload_save_missing")
    _expect(int(snapshot.get("run_stats", {}).get("player_probe_marker", -1)) == 77, "reload_save_state_missing")
    _expect(bool(main.get("gameplay_enabled")), "reload_gameplay_disabled")
    _expect(player != null and player.camera.current, "reload_player_camera_not_current")
    _finish()

func _visit_room(room_id: StringName) -> void:
    var room := stage.room_director.rooms.get(room_id) as RoomShell
    _expect(room != null, "room_missing_" + String(room_id))
    if room == null:
        return
    player.global_position = room.global_position + Vector3(0.0, 0.15, 0.0)
    print("PLAYER_QA_VISIT room=", room_id, " assigned=", player.global_position)
    room._on_body_entered(player)
    player.velocity = Vector3.ZERO
    print("PLAYER_QA_VISIT_INPUT=", Input.get_vector("move_left", "move_right", "move_forward", "move_back"))
    await _wait_frames(5)

func _face_target(target: Node3D) -> void:
    var flat := target.global_position
    flat.y = player.global_position.y
    player.look_at(flat, Vector3.UP)

func _kill_active_enemies() -> void:
    var guard := 0
    while not stage.active_enemies.is_empty() and guard < 16:
        for enemy in stage.active_enemies.duplicate():
            if is_instance_valid(enemy) and enemy.has_method("apply_damage"):
                enemy.apply_damage(10000.0, &"player_probe")
        await _wait_frames(4)
        guard += 1
    _expect(stage.active_enemies.is_empty(), "room_enemies_not_killed")
