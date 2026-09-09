extends Node

var failures: Array[String] = []
var attack_events := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_gate")

func _fail(message: String) -> void:
    failures.append(message)
    printerr("INITIAL_WEAPON_GATE_FAIL: %s" % message)

func _physics_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().physics_frame

func _settle_player(player: PlayerController, position: Vector3) -> void:
    player.global_position = position
    player.velocity = Vector3.ZERO
    await _physics_frames(14)

func _on_attack() -> void:
    attack_events += 1

func _press_primary(player: PlayerController) -> void:
    var event := InputEventAction.new()
    event.action = &"primary_attack"
    event.pressed = true
    player._unhandled_input(event)

func _run_gate() -> void:
    GameState.start_new_campaign(94101)

    var world := Node3D.new()
    add_child(world)
    var ui := CanvasLayer.new()
    add_child(ui)
    var stage := StageDirector.new()
    add_child(stage)
    stage.configure(world, ui)
    await get_tree().process_frame

    var player := stage.player
    var threshold := stage.floor_instance.get_node_or_null("Rooms/threshold") as RoomShell
    var east_door := threshold.get_node_or_null("DoorSet/EastDoor") as StaticBody3D if threshold else null
    var weapon = stage.get_initial_weapon_pickup()

    if player == null or threshold == null or east_door == null:
        _fail("O OLHO runtime did not create the canonical player, threshold and east gate")
    if weapon == null:
        _fail("O OLHO did not spawn the hidden physical weapon")

    if player:
        player.primary_attack_requested.connect(_on_attack)
        _press_primary(player)
        if attack_events != 0:
            _fail("primary attack fires before the physical weapon is acquired")
        if player.has_initial_weapon():
            _fail("Harun begins O OLHO already carrying the physical weapon")
        if player.is_primary_attack_enabled():
            _fail("primary attack state is enabled before weapon acquisition")

    if threshold and not threshold.locked:
        _fail("threshold route is not logically locked before weapon acquisition")
    if east_door and (east_door.collision_layer != 2 or not east_door.visible):
        _fail("east threshold gate is not physically closed before weapon acquisition")

    if player:
        await _settle_player(player, Vector3(0.0, 1.2, 0.0))
        Input.action_press("move_right")
        await _physics_frames(170)
        Input.action_release("move_right")
        if player.global_position.x > 5.25:
            _fail("player can enter the first mandatory combat before acquiring the physical weapon")

    if weapon:
        if weapon.visible:
            _fail("physical weapon is visible before Revelatory Eye activation")
        var focus_before := player.focus if player else 0.0
        stage._on_power_requested()
        await get_tree().process_frame
        if player and not is_equal_approx(player.focus, focus_before):
            _fail("Revelatory Eye incorrectly consumes focus despite its zero-cost definition")
        if not weapon.visible or not weapon.is_revealed():
            _fail("Revelatory Eye does not reveal the physical weapon")

        if player:
            if not weapon.interact(player):
                _fail("revealed physical weapon cannot be acquired")
            await get_tree().process_frame

    if player:
        if not player.has_initial_weapon():
            _fail("weapon acquisition does not equip the physical weapon")
        if not player.is_primary_attack_enabled():
            _fail("weapon acquisition does not enable primary attack")
        var viewmodel := player.get_node_or_null("Head/Camera3D/ViewModelRoot/InitialWeapon") as Node3D
        if viewmodel == null or not viewmodel.visible:
            _fail("equipped physical weapon is not visible in the first-person viewmodel")
        _press_primary(player)
        if attack_events != 1:
            _fail("primary attack remains unavailable after weapon acquisition")

    if threshold and threshold.locked:
        _fail("threshold route remains logically locked after weapon acquisition")
    if east_door and (east_door.collision_layer != 0 or east_door.visible):
        _fail("east threshold gate remains physically closed after weapon acquisition")
    if not bool(GameState.meta_progression.get("initial_weapon_acquired", false)):
        _fail("campaign state does not remember physical weapon acquisition")

    # Enter the first mandatory encounter using the actual player and physics route.
    if player:
        await _settle_player(player, Vector3(0.0, 1.2, 0.0))
        Input.action_press("move_right")
        await _physics_frames(210)
        Input.action_release("move_right")
        await _physics_frames(10)
        if player.global_position.x < 9.0:
            _fail("first mandatory combat route does not become physically traversable after acquisition")

    var combat_room := stage.floor_instance.get_node_or_null("Rooms/combat_1") as RoomShell
    if combat_room == null:
        _fail("first mandatory combat room is missing")
    else:
        if not stage.room_spawned.has("combat_1"):
            _fail("entering combat_1 does not spawn its encounter")
        if stage.active_enemies.is_empty():
            _fail("combat_1 starts with no enemies")
        if not combat_room.locked:
            _fail("combat_1 does not lock while its enemies are alive")

        # Resolve the encounter through the real health/death signals so RoomDirector must clear it.
        var enemies := stage.active_enemies.duplicate()
        for enemy in enemies:
            if is_instance_valid(enemy) and enemy.has_method("apply_damage"):
                enemy.call("apply_damage", 99999.0, &"playability_gate")
        await _physics_frames(30)

        if not combat_room.cleared:
            _fail("combat_1 does not mark itself cleared after all enemies die")
        if combat_room.locked:
            _fail("combat_1 remains locked after all enemies die")
        if int(GameState.run_stats.get("rooms_cleared", 0)) < 1:
            _fail("combat clear does not advance run statistics")

        var reward_room := stage.floor_instance.get_node_or_null("Rooms/reward_1") as RoomShell
        if reward_room == null:
            _fail("reward room after combat_1 is missing")
        else:
            var reward_found := false
            for child in reward_room.get_children():
                if child is PickupController:
                    reward_found = true
                    break
            if not reward_found:
                _fail("clearing combat_1 does not spawn its reward pickup")

    # The clear must also let the player physically leave combat_1 toward the reward room.
    if player and combat_room:
        await _settle_player(player, Vector3(14.0, 1.2, 0.0))
        Input.action_press("move_right")
        await _physics_frames(210)
        Input.action_release("move_right")
        await _physics_frames(8)
        if player.global_position.x < 23.0:
            _fail("player cannot leave cleared combat_1 toward reward_1")

    var snapshot := GameState.to_save_data()
    GameState.start_new_campaign(94102)
    GameState.load_save_data(snapshot)

    var reload_world := Node3D.new()
    add_child(reload_world)
    var reload_ui := CanvasLayer.new()
    add_child(reload_ui)
    var reload_stage := StageDirector.new()
    add_child(reload_stage)
    reload_stage.configure(reload_world, reload_ui)
    await get_tree().process_frame

    var reload_player := reload_stage.player
    var reload_threshold := reload_stage.floor_instance.get_node_or_null("Rooms/threshold") as RoomShell
    var reload_east_door := reload_threshold.get_node_or_null("DoorSet/EastDoor") as StaticBody3D if reload_threshold else null
    if reload_stage.get_initial_weapon_pickup() != null:
        _fail("physical weapon pickup respawns after persisted acquisition")
    if reload_player == null or not reload_player.has_initial_weapon() or not reload_player.is_primary_attack_enabled():
        _fail("persisted campaign reload does not restore the physical weapon")
    if reload_threshold and reload_threshold.locked:
        _fail("persisted campaign reload relocks the initial threshold")
    if reload_east_door and (reload_east_door.collision_layer != 0 or reload_east_door.visible):
        _fail("persisted campaign reload physically closes the already-cleared initial threshold")

    if failures.is_empty():
        print("CHRONICA_INITIAL_WEAPON_GATE_OK")
        get_tree().quit(0)
    else:
        printerr("CHRONICA_INITIAL_WEAPON_GATE_FAILED_COUNT=%d" % failures.size())
        get_tree().quit(1)
