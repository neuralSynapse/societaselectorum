extends Node

const TEST_SEED := 96301
var failures: Array[String] = []
var completed_events := 0
var completed_stage: StringName = &""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_gate")

func _fail(message: String) -> void:
    failures.append(message)
    printerr("STAGE_COMPLETION_GATE_FAIL: %s" % message)

func _physics_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().physics_frame

func _on_stage_completed(stage_id: StringName, _summary: Dictionary) -> void:
    completed_events += 1
    completed_stage = stage_id

func _kill_active_enemies(stage: StageDirector, room_id: StringName) -> void:
    stage.room_director.activate_room(room_id)
    await get_tree().process_frame
    await _physics_frames(2)
    var room := stage._room(String(room_id))
    if room == null:
        _fail("missing room %s" % room_id)
        return
    if not room.locked:
        _fail("%s did not lock when combat activated" % room_id)
    var enemies: Array = stage.room_director.enemies_by_room.get(room_id, []).duplicate()
    if enemies.is_empty():
        _fail("%s spawned no enemies" % room_id)
        return
    for enemy in enemies:
        if is_instance_valid(enemy) and enemy.has_method("apply_damage"):
            var health = enemy.get("health")
            if health is Health:
                health.invulnerable_for = 0.0
            enemy.apply_damage(99999.0, &"stage_completion_gate")
            await get_tree().process_frame
    await _physics_frames(3)
    if room.locked or not room.cleared:
        _fail("%s did not clear and unlock after all enemies died" % room_id)

func _run_gate() -> void:
    GameState.start_new_campaign(TEST_SEED)
    GameState.meta_progression["initial_weapon_acquired"] = true

    var world := Node3D.new()
    world.name = "GateWorld"
    add_child(world)
    var ui := CanvasLayer.new()
    ui.name = "GateUI"
    add_child(ui)
    var stage := StageDirector.new()
    stage.name = "GateStageDirector"
    add_child(stage)
    stage.stage_completed.connect(_on_stage_completed)
    stage.configure(world, ui)
    await get_tree().process_frame

    if String(stage.stage_data.get("id", "")) != "o_olho":
        _fail("campaign did not boot O OLHO")
    if stage.player == null or not stage.player.has_initial_weapon() or not stage.player.is_primary_attack_enabled():
        _fail("persisted initial weapon state did not produce a combat-ready player")

    await _kill_active_enemies(stage, &"combat_1")
    await _kill_active_enemies(stage, &"combat_2")
    await _kill_active_enemies(stage, &"combat_3")

    stage.room_director.activate_room(&"boss")
    await get_tree().process_frame
    await _physics_frames(2)
    var boss_room := stage._room("boss")
    if boss_room == null or not boss_room.locked:
        _fail("boss room did not exist and lock on activation")
    if stage.boss == null:
        _fail("O OLHO boss did not spawn")
    else:
        stage.boss.health.invulnerable_for = 0.0
        stage.boss.apply_damage(999999.0, &"stage_completion_gate")
        await get_tree().process_frame
        await _physics_frames(3)

    if completed_events != 1 or completed_stage != &"o_olho":
        _fail("stage_completed did not fire exactly once for O OLHO")
    if GameState.stage_index != 1 or GameState.current_stage_id != &"a_chama":
        _fail("boss defeat did not advance campaign from O OLHO to A CHAMA")
    if not bool(GameState.completion_marks.get("o_olho", false)):
        _fail("O OLHO completion mark was not persisted in runtime state")

    var saved := SaveService.load_campaign()
    if saved.is_empty():
        _fail("boss completion did not save campaign")
    elif String(saved.get("current_stage_id", "")) != "a_chama" or int(saved.get("stage_index", -1)) != 1:
        _fail("saved campaign does not point to A CHAMA after O OLHO boss")

    if not saved.is_empty():
        GameState.load_save_data(saved)
        var next_world := Node3D.new()
        next_world.name = "NextStageWorld"
        add_child(next_world)
        var next_ui := CanvasLayer.new()
        next_ui.name = "NextStageUI"
        add_child(next_ui)
        var next_stage := StageDirector.new()
        next_stage.name = "NextStageDirector"
        add_child(next_stage)
        next_stage.configure(next_world, next_ui)
        await get_tree().process_frame
        if String(next_stage.stage_data.get("id", "")) != "a_chama":
            _fail("persisted campaign cannot boot A CHAMA")
        if next_stage.player == null or not next_stage.player.has_initial_weapon() or not next_stage.player.is_primary_attack_enabled():
            _fail("A CHAMA boot loses the acquired physical weapon or attack capability")

    if failures.is_empty():
        print("CHRONICA_STAGE_COMPLETION_GATE_OK")
        get_tree().quit(0)
    else:
        printerr("CHRONICA_STAGE_COMPLETION_GATE_FAILED_COUNT=%d" % failures.size())
        get_tree().quit(1)
