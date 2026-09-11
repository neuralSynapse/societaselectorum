extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/EnemyBase.tscn")

func _ready() -> void:
    call_deferred("_run_probe")

func _run_probe() -> void:
    var wall := StaticBody3D.new()
    wall.name = "ProbeWall"
    wall.collision_layer = 2
    wall.collision_mask = 0
    add_child(wall)
    wall.position = Vector3(0.0, 1.0, -4.0)

    var wall_shape := CollisionShape3D.new()
    var wall_box := BoxShape3D.new()
    wall_box.size = Vector3(8.0, 3.0, 0.2)
    wall_shape.shape = wall_box
    wall.add_child(wall_shape)

    var target := Node3D.new()
    target.name = "EnemyWallTarget"
    add_child(target)
    target.position = Vector3(0.0, 0.0, -8.0)

    var enemy := ENEMY_SCENE.instantiate() as DataEnemy
    add_child(enemy)
    enemy.position = Vector3(0.0, 0.0, -2.5)
    enemy.set_target(target)
    enemy.set_physics_process(false)

    await get_tree().physics_frame
    await get_tree().physics_frame

    for _step in range(120):
        await get_tree().physics_frame
        enemy.move_toward_target(1.0 / 60.0, 1.0)

    if enemy.global_position.z <= -3.8:
        push_error("Enemy crossed room wall: z=%.3f" % enemy.global_position.z)
        get_tree().quit(2)
        return
    print("ENEMY_WALL_COLLISION=PASS z=%.3f" % enemy.global_position.z)

    enemy.position = Vector3(0.0, 0.0, -1.8)
    enemy.velocity = Vector3.ZERO
    target.position = enemy.position

    var player := PLAYER_SCENE.instantiate() as PlayerController
    add_child(player)
    player.position = Vector3(0.0, 0.0, 0.0)
    player.set_physics_process(false)
    player.set_process_input(false)

    await get_tree().physics_frame
    await get_tree().physics_frame

    for _step in range(90):
        await get_tree().physics_frame
        player.velocity = Vector3(0.0, 0.0, -5.0)
        player.move_and_slide()

    if player.global_position.z <= -1.5:
        push_error("Player crossed enemy body: z=%.3f" % player.global_position.z)
        get_tree().quit(3)
        return
    print("PLAYER_ENEMY_COLLISION=PASS z=%.3f" % player.global_position.z)

    player.queue_free()
    enemy.queue_free()
    wall.queue_free()
    target.queue_free()
    await get_tree().physics_frame

    var journey := ContentRegistry.get_student_journey()
    if journey.is_empty():
        push_error("No journey available for doorway probe")
        get_tree().quit(4)
        return
    var floor := StageFloorBuilder.build(journey[0], 9301, 1, {})
    add_child(floor)
    var threshold := floor.get_node("Rooms/threshold") as RoomShell
    var doorway_player := PLAYER_SCENE.instantiate() as PlayerController
    add_child(doorway_player)
    doorway_player.global_position = threshold.global_position + Vector3(0.0, 0.15, 0.0)
    doorway_player.set_physics_process(false)
    doorway_player.set_process_input(false)

    await get_tree().physics_frame
    await get_tree().physics_frame

    for _step in range(150):
        await get_tree().physics_frame
        doorway_player.velocity = Vector3(5.2, 0.0, 0.0)
        doorway_player.move_and_slide()

    if doorway_player.global_position.x <= 6.0:
        push_error("Threshold exit is physically blocked: x=%.3f" % doorway_player.global_position.x)
        get_tree().quit(5)
        return
    print("THRESHOLD_DOORWAY_COLLISION=PASS x=%.3f" % doorway_player.global_position.x)

    var room_director := floor.get_node("RoomDirector") as RoomDirector
    var combat_room := floor.get_node("Rooms/combat_1") as RoomShell
    room_director.register_room(combat_room)
    room_director.activate_room(&"combat_1")
    if not combat_room.locked:
        push_error("Combat room did not lock on first activation")
        get_tree().quit(6)
        return
    room_director.clear_room(&"combat_1")
    if combat_room.locked or not combat_room.cleared:
        push_error("Combat room did not clear correctly")
        get_tree().quit(7)
        return
    room_director.activate_room(&"combat_1")
    if combat_room.locked:
        push_error("Cleared combat room relocked on reentry")
        get_tree().quit(8)
        return

    var replacement := RoomShell.new()
    replacement.room_id = &"combat_1"
    replacement.room_role = &"combat"
    floor.add_child(replacement)
    room_director.register_room(replacement)
    room_director.activate_room(&"combat_1")
    if replacement.locked or not replacement.cleared:
        push_error("Cleared room state did not survive room instance refresh")
        get_tree().quit(9)
        return
    print("CLEARED_ROOM_REENTRY=PASS")
    print("COLLISION_RUNTIME=PASS")
    get_tree().quit(0)
