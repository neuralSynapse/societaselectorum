extends Node

var failures: Array[String] = []
var attack_events := 0
var interact_events := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_gate")

func _fail(message: String) -> void:
    failures.append(message)
    printerr("PLAYABILITY_GATE_FAIL: %s" % message)

func _physics_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().physics_frame

func _settle_player(player: PlayerController, position: Vector3) -> void:
    player.global_position = position
    player.velocity = Vector3.ZERO
    await _physics_frames(16)

func _on_attack_test() -> void:
    attack_events += 1

func _on_interact_test(_target: Node) -> void:
    interact_events += 1

func _run_gate() -> void:
    var host := Node3D.new()
    host.name = "RuntimePlayabilityGateHost"
    add_child(host)

    var stage := StageFloorBuilder.build({"id":"o_olho", "index":0}, 93017, 1, {})
    host.add_child(stage)
    await get_tree().process_frame

    var corridors := stage.get_node_or_null("Corridors")
    if corridors == null or corridors.get_child_count() == 0:
        _fail("stage floor created no corridor nodes")
    else:
        var first_corridor := corridors.get_child(0)
        if not first_corridor is StaticBody3D:
            _fail("corridor is visual-only instead of StaticBody3D")
        elif first_corridor.get_node_or_null("CollisionShape3D") == null:
            _fail("corridor StaticBody3D has no CollisionShape3D")

    var rooms := stage.get_node_or_null("Rooms")
    var threshold := rooms.get_node_or_null("threshold") if rooms else null
    if threshold == null:
        _fail("threshold room missing")
    else:
        var east_wall := threshold.get_node_or_null("EastWall") as StaticBody3D
        if east_wall == null:
            _fail("threshold east wall missing")
        elif east_wall.collision_layer != 0:
            _fail("opened room wall still collides and blocks corridor passage")
        elif east_wall.get_node_or_null("PortalSideA") == null or east_wall.get_node_or_null("PortalSideB") == null:
            _fail("opened room wall has no physical side segments around the portal")

    var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
    var player := player_scene.instantiate() as PlayerController
    host.add_child(player)
    await _settle_player(player, Vector3(0.0, 1.2, 0.0))

    # Each movement direction gets an isolated position/velocity so inertia cannot fake a pass.
    await _settle_player(player, Vector3(0.0, 1.2, 0.0))
    Input.action_press("move_left")
    await _physics_frames(45)
    Input.action_release("move_left")
    if player.global_position.x > -1.0:
        _fail("move_left/A does not move the real player left")

    await _settle_player(player, Vector3(0.0, 1.2, 0.0))
    Input.action_press("move_right")
    await _physics_frames(45)
    Input.action_release("move_right")
    if player.global_position.x < 1.0:
        _fail("move_right/D does not move the real player right")

    await _settle_player(player, Vector3(0.0, 1.2, 0.0))
    Input.action_press("move_forward")
    await _physics_frames(45)
    Input.action_release("move_forward")
    if player.global_position.z > -1.0:
        _fail("move_forward/W does not move the real player forward")

    await _settle_player(player, Vector3(0.0, 1.2, 0.0))
    Input.action_press("move_back")
    await _physics_frames(45)
    Input.action_release("move_back")
    if player.global_position.z < 1.0:
        _fail("move_back/S does not move the real player backward")

    # Verify first-person look math without depending on a headless OS cursor capture mode.
    await _settle_player(player, Vector3(0.0, 1.2, 0.0))
    var yaw_before := player.rotation.y
    player._apply_mouse_look(Vector2(24.0, 0.0))
    if is_equal_approx(player.rotation.y, yaw_before):
        _fail("mouse look does not rotate the first-person player camera rig")
    player.rotation.y = 0.0

    # Verify the room-to-room route is physically traversable, not merely drawn.
    await _settle_player(player, Vector3(0.0, 1.2, 0.0))
    var start_x := player.global_position.x
    Input.action_press("move_right")
    await _physics_frames(210)
    Input.action_release("move_right")
    await _physics_frames(12)
    if player.global_position.x < start_x + 9.0:
        _fail("player cannot traverse threshold -> corridor -> next room using real movement")

    # Push into the corridor rail. The player must remain on the bridge instead of leaving the map.
    await _settle_player(player, Vector3(7.0, 1.2, 0.0))
    Input.action_press("move_back")
    await _physics_frames(90)
    Input.action_release("move_back")
    if absf(player.global_position.z) > 1.05 or player.global_position.y < -2.0:
        _fail("corridor side protection does not keep the player on the walkable route")

    # Deliberately throw the player into the void and demand automatic recovery.
    player.global_position = Vector3(0.0, -40.0, 0.0)
    player.velocity = Vector3.ZERO
    await _physics_frames(8)
    if player.global_position.y < -5.0:
        _fail("player has no void/fall recovery and remains outside the playable floor")

    # Basic first-person action contract must respond to actual action events.
    player.primary_attack_requested.connect(_on_attack_test)
    player.interact_requested.connect(_on_interact_test)
    var attack_event := InputEventAction.new()
    attack_event.action = &"primary_attack"
    attack_event.pressed = true
    player._unhandled_input(attack_event)
    if attack_events != 1:
        _fail("primary attack input does not reach the player combat contract")
    var interact_event := InputEventAction.new()
    interact_event.action = &"interact"
    interact_event.pressed = true
    player._unhandled_input(interact_event)
    if interact_events != 1:
        _fail("interact/E input does not reach the player interaction contract")

    var pause_path := "res://scenes/ui/PauseMenu.tscn"
    var pause_controller: Node = null
    if not ResourceLoader.exists(pause_path):
        _fail("dedicated pause menu scene does not exist")
    else:
        var pause_scene: PackedScene = load(pause_path)
        pause_controller = pause_scene.instantiate()
        add_child(pause_controller)
        await get_tree().process_frame

    if get_tree().paused:
        get_tree().paused = false
    if pause_controller != null:
        var pause_event := InputEventAction.new()
        pause_event.action = &"pause"
        pause_event.pressed = true
        pause_controller._unhandled_input(pause_event)
        if not get_tree().paused:
            _fail("ESC/pause action does not actually pause the SceneTree")
        var overlay := pause_controller.get_node_or_null("Overlay") as Control
        if overlay == null or not overlay.visible:
            _fail("pause menu did not become visible after ESC action")
        pause_controller.resume_game()
        if get_tree().paused:
            _fail("resume does not unpause the SceneTree")

    if failures.is_empty():
        print("CHRONICA_REAL_PLAYABILITY_GATE_OK")
        get_tree().quit(0)
    else:
        printerr("CHRONICA_REAL_PLAYABILITY_GATE_FAILED_COUNT=%d" % failures.size())
        get_tree().quit(1)
