extends CharacterBody3D
class_name EnemyBrain

signal died(source_id: StringName)
signal identified(enemy_id: StringName, display_name: String, role: String, attack_name: String)

@export var enemy_id: StringName = &"enemy"
@export var display_name := "Presença"
@export var role := "unknown"
@export var attack_name := "Ataque"
@export var move_speed := 2.8
@export var preferred_range := 1.2

@onready var health: Health = $Health
@onready var attack_sm: AttackStateMachine = $AttackStateMachine
@onready var projectile_origin: Marker3D = $ProjectileOrigin
@onready var telegraph_origin: Marker3D = $TelegraphOrigin
@onready var telegraph_root: Node3D = $TelegraphRoot
@onready var impact_origin: Marker3D = $ImpactOrigin
@onready var visual: Node3D = $Visual

var target: Node3D
var room_active := true
var attack_definition: Dictionary = {}
var attack_cooldown := 0.0
var readable_telegraph: ReadableTelegraph

func _ready() -> void:
    health.died.connect(_on_died)
    health.damaged.connect(_on_damaged)
    attack_sm.telegraph_started.connect(_on_telegraph_started)
    attack_sm.emission_requested.connect(_on_emission_requested)
    attack_sm.impact_window_started.connect(_on_impact_window)
    readable_telegraph = ReadableTelegraph.new()
    telegraph_root.add_child(readable_telegraph)
    add_to_group("enemies")

func set_target(next_target: Node3D) -> void:
    target = next_target

func set_room_active(value: bool) -> void:
    room_active = value
    if not value:
        velocity = Vector3.ZERO
        if readable_telegraph:
            readable_telegraph.clear()

func reveal_identity() -> void:
    identified.emit(enemy_id, display_name, role, attack_name)

func _physics_process(delta: float) -> void:
    if not room_active or target == null or health.dead:
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    think(delta)

func think(_delta: float) -> void:
    pass

func distance_to_target() -> float:
    if target == null:
        return INF
    return global_position.distance_to(target.global_position)

func face_target() -> void:
    if target == null:
        return
    var flat := Vector3(target.global_position.x, global_position.y, target.global_position.z)
    if flat.distance_to(global_position) > 0.05:
        look_at(flat, Vector3.UP)

func move_toward_target(delta: float, speed_multiplier := 1.0) -> void:
    if target == null:
        return
    var to_target := target.global_position - global_position
    to_target.y = 0.0
    if to_target.length_squared() <= 0.001:
        velocity = Vector3.ZERO
        return
    var desired := to_target.normalized() * move_speed * speed_multiplier
    velocity.x = move_toward(velocity.x, desired.x, 12.0 * delta)
    velocity.z = move_toward(velocity.z, desired.z, 12.0 * delta)
    move_and_slide()

func move_away_from_target(delta: float, speed_multiplier := 1.0) -> void:
    if target == null:
        return
    var away := global_position - target.global_position
    away.y = 0.0
    if away.length_squared() <= 0.001:
        away = Vector3.RIGHT
    var desired := away.normalized() * move_speed * speed_multiplier
    velocity.x = move_toward(velocity.x, desired.x, 10.0 * delta)
    velocity.z = move_toward(velocity.z, desired.z, 10.0 * delta)
    move_and_slide()

func request_attack(definition: Dictionary) -> bool:
    if target == null or definition.is_empty():
        return false
    return attack_sm.begin_attack(definition, target)

func apply_damage(amount: float, source_id: StringName = &"") -> bool:
    return health.apply_damage(amount, source_id)

func _on_telegraph_started(payload: Dictionary) -> void:
    face_target()
    var definition: Dictionary = payload.get("definition", {})
    if readable_telegraph:
        readable_telegraph.show_attack(definition, target, telegraph_origin.global_position)
    AudioDirector.play_enemy_family(String(get("family")), &"windup", telegraph_origin.global_position)

func _on_emission_requested(_payload: Dictionary) -> void:
    pass

func _on_impact_window(payload: Dictionary) -> void:
    var definition: Dictionary = payload.get("definition", {})
    if String(definition.get("attack_kind", "")) != "movement":
        return
    CombatFeedback.impact(get_tree().current_scene, impact_origin.global_position, 0.8)
    if target and distance_to_target() <= float(definition.get("range", 1.4)):
        if target.has_method("apply_damage"):
            target.apply_damage(float(definition.get("damage", 10.0)), enemy_id)

func _on_damaged(_current: float, _maximum: float, amount: float, _source_id: StringName) -> void:
    CombatFeedback.hit_flash(visual, maxf(0.5, amount / 10.0))

func _on_died(source_id: StringName) -> void:
    if readable_telegraph:
        readable_telegraph.clear()
    died.emit(source_id)
    set_physics_process(false)
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector3(1.0, 0.05, 1.0), 0.25)
    tween.tween_callback(queue_free)
