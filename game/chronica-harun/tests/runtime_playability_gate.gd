extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_gate")

func _fail(message: String) -> void:
    failures.append(message)
    printerr("PLAYABILITY_GATE_FAIL: %s" % message)

func _physics_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame

func _run_gate() -> void:
    var host := Node3D.new()
    host.name = "RuntimePlayabilityGate"
    root.add_child(host)

    var stage := StageFloorBuilder.build({"id":"o_olho", "index":0}, 93017, 1, {})
    host.add_child(stage)
    await process_frame

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
    player.global_position = Vector3(0.0, 1.2, 0.0)
    await _physics_frames(20)

    var start_x := player.global_position.x
    Input.action_press("move_right")
    await _physics_frames(210)
    Input.action_release("move_right")
    await _physics_frames(12)
    if player.global_position.x < start_x + 9.0:
        _fail("player cannot traverse threshold -> corridor -> next room using real movement")

    player.global_position = Vector3(0.0, -40.0, 0.0)
    player.velocity = Vector3.ZERO
    await _physics_frames(8)
    if player.global_position.y < -5.0:
        _fail("player has no void/fall recovery and remains outside the playable floor")

    var pause_path := "res://scenes/ui/PauseMenu.tscn"
    var pause_controller: Node = null
    if not ResourceLoader.exists(pause_path):
        _fail("dedicated pause menu scene does not exist")
    else:
        var pause_scene: PackedScene = load(pause_path)
        pause_controller = pause_scene.instantiate()
        root.add_child(pause_controller)
        await process_frame

    if paused:
        paused = false
    if pause_controller != null:
        var pause_event := InputEventAction.new()
        pause_event.action = &"pause"
        pause_event.pressed = true
        pause_controller._unhandled_input(pause_event)
        if not paused:
            _fail("ESC/pause action does not actually pause the SceneTree")
        var overlay := pause_controller.get_node_or_null("Overlay") as Control
        if overlay == null or not overlay.visible:
            _fail("pause menu did not become visible after ESC action")
        pause_controller.resume_game()
        if paused:
            _fail("resume does not unpause the SceneTree")

    if failures.is_empty():
        print("CHRONICA_REAL_PLAYABILITY_GATE_OK")
        quit(0)
    else:
        printerr("CHRONICA_REAL_PLAYABILITY_GATE_FAILED_COUNT=%d" % failures.size())
        quit(1)
