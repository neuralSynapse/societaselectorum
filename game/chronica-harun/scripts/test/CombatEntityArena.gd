extends Node3D
class_name CombatEntityArena

@export var enemy_id: StringName = &"o_olho_presence_02"
@export var boss_id: StringName = &"blind_observer"
@export var auto_spawn := true

@onready var target: CharacterBody3D = $Target
@onready var enemy_spawn: Marker3D = $EnemySpawn
@onready var boss_spawn: Marker3D = $BossSpawn

func _ready() -> void:
    if not auto_spawn:
        return
    _spawn_enemy()
    _spawn_boss()
    print("CHRONICA_FRONT_B_ARENA_READY")

func _spawn_enemy() -> void:
    var data := ContentRegistry.get_enemy(enemy_id)
    if data.is_empty():
        push_warning("Arena enemy id unavailable: %s" % enemy_id)
        return
    var packed := load("res://scenes/enemies/EnemyBase.tscn") as PackedScene
    var enemy := packed.instantiate() as DataEnemy
    add_child(enemy)
    enemy.global_position = enemy_spawn.global_position
    enemy.configure_from_data(data, target)

func _spawn_boss() -> void:
    var data := ContentRegistry.get_boss(boss_id)
    if data.is_empty():
        push_warning("Arena boss id unavailable: %s" % boss_id)
        return
    var packed := load("res://scenes/bosses/BossBase.tscn") as PackedScene
    var boss := packed.instantiate() as DataBossController
    add_child(boss)
    boss.global_position = boss_spawn.global_position
    boss.configure(boss_id, target)
