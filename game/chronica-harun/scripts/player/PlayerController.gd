extends CharacterBody3D
class_name PlayerController

signal died(source_id: StringName)
signal primary_attack_requested
signal power_requested
signal instrument_requested
signal consume_requested
signal rupture_charge_requested
signal interact_requested(target: Node)
signal damaged(amount: float, source_id: StringName)
signal focus_changed(current: float, maximum: float)
signal essence_changed(value: int)
signal camera_mode_requested
signal kinesis_slot_requested(slot: int)

@export var walk_speed := 4.8
@export var sprint_speed := 7.2
@export var acceleration := 18.0
@export var jump_velocity := 4.2
@export var mouse_sensitivity := 0.0022
@export var invert_y := false
@export var max_focus := 100.0
@export var max_stamina := 100.0
@export var fall_recovery_y := -10.0
@export var recovery_height_offset := 0.35

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var health: Health = $Health

var gravity := 9.8
var pitch := 0.0
var focus := 100.0
var stamina := 100.0
var essence := 0
var shield := 0.0
var primary_cooldown := 0.0
var dodge_cooldown := 0.0
var last_safe_position := Vector3.ZERO
var has_safe_position := false

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    health.died.connect(func(source_id: StringName): died.emit(source_id))
    health.damaged.connect(_on_health_damaged)
    focus = max_focus
    stamina = max_stamina
    last_safe_position = global_position
    has_safe_position = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotation.y -= event.relative.x * mouse_sensitivity
        var vertical_sign := -1.0 if invert_y else 1.0
        pitch -= event.relative.y * mouse_sensitivity * vertical_sign
        pitch = clamp(pitch, deg_to_rad(-84.0), deg_to_rad(84.0))
        head.rotation.x = pitch
    if event.is_action_pressed("interact"):
        var target := get_interaction_target()
        interact_requested.emit(target)
        if target and target.has_method("interact"):
            target.interact(self)
    elif event.is_action_pressed("primary_attack"):
        primary_attack_requested.emit()
    elif event.is_action_pressed("power"):
        power_requested.emit()
    elif event.is_action_pressed("instrument"):
        instrument_requested.emit()
    elif event.is_action_pressed("consume"):
        consume_requested.emit()
    elif event.is_action_pressed("rupture_charge"):
        rupture_charge_requested.emit()
    elif event.is_action_pressed("camera_toggle"):
        camera_mode_requested.emit()
    elif event.is_action_pressed("kinesis_1"):
        kinesis_slot_requested.emit(0)
    elif event.is_action_pressed("kinesis_2"):
        kinesis_slot_requested.emit(1)
    elif event.is_action_pressed("kinesis_3"):
        kinesis_slot_requested.emit(2)

func _physics_process(delta: float) -> void:
    if global_position.y < fall_recovery_y:
        _recover_from_fall()
        return

    primary_cooldown = maxf(0.0, primary_cooldown - delta)
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    stamina = minf(max_stamina, stamina + 22.0 * delta)
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    forward.y = 0.0
    right.y = 0.0
    var direction := (right * input_vec.x + forward * -input_vec.y).normalized()
    var target_speed := sprint_speed if Input.is_action_pressed("sprint") and stamina > 1.0 else walk_speed
    if target_speed == sprint_speed and direction.length_squared() > 0.01:
        stamina = maxf(0.0, stamina - 20.0 * delta)
    velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
    move_and_slide()

    if is_on_floor() and global_position.y > fall_recovery_y + 1.0:
        last_safe_position = global_position
        has_safe_position = true

func _recover_from_fall() -> void:
    var target := last_safe_position if has_safe_position else Vector3.ZERO
    global_position = target + Vector3.UP * recovery_height_offset
    velocity = Vector3.ZERO

func get_interaction_target() -> Node:
    if interaction_ray and interaction_ray.is_colliding():
        return interaction_ray.get_collider()
    return null

func get_aim_target() -> Node:
    return get_interaction_target()

func spend_focus(amount: float) -> bool:
    if amount <= 0.0 or focus < amount:
        return false
    focus -= amount
    focus_changed.emit(focus, max_focus)
    return true

func restore_focus(amount: float) -> float:
    focus = minf(max_focus, focus + maxf(0.0, amount))
    focus_changed.emit(focus, max_focus)
    return focus

func add_essence(amount: int) -> int:
    essence = maxi(0, essence + amount)
    essence_changed.emit(essence)
    return essence

func apply_damage(amount: float, source_id: StringName = &"") -> bool:
    var build := BuildResolver.resolve(GameState.run_build)
    var adjusted := amount * float(build.get("damage_taken_mult", 1.0))
    if shield > 0.0:
        var absorbed := minf(shield, adjusted)
        shield -= absorbed
        adjusted -= absorbed
    if adjusted <= 0.0:
        return false
    return health.apply_damage(adjusted, source_id)

func heal(amount: float) -> float:
    return health.heal(amount)

func _on_health_damaged(_current: float, _maximum: float, amount: float, source_id: StringName) -> void:
    GameState.run_stats["damage_taken"] = float(GameState.run_stats.get("damage_taken", 0.0)) + amount
    var mutation_result := PowerMutationRuntime.on_player_damaged(amount, {"focus": focus})
    restore_focus(float(mutation_result.get("focus_gain", 0.0)))
    shield += float(mutation_result.get("shield_gain", 0.0))
    damaged.emit(amount, source_id)
    AudioDirector.play_3d(&"player_hit", global_position)
