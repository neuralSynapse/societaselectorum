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
    print("COLLISION_RUNTIME=PASS")
    get_tree().quit(0)
