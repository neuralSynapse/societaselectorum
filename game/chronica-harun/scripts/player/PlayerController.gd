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
signal dodge_started(perfect_window: float)
signal dodge_completed(perfect: bool)
signal mouse_capture_changed(captured: bool)

@export var walk_speed := 4.8
@export var sprint_speed := 7.2
@export var acceleration := 18.0
@export var jump_velocity := 4.2
@export var mouse_sensitivity := 0.0022
@export var invert_y := false
@export var max_focus := 100.0
@export var max_stamina := 100.0
@export var fall_recovery_y := -8.0
@export var dodge_speed := 12.2
@export var dodge_duration := 0.24
@export var dodge_invulnerability := 0.18
@export var perfect_dodge_window := 0.09
@export var dodge_stamina_cost := 26.0
@export var dodge_recovery := 0.72
@export var power_recovery := 0.85

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
var power_cooldown := 0.0
var dodge_cooldown := 0.0
var dodge_time_remaining := 0.0
var dodge_invulnerability_remaining := 0.0
var dodge_elapsed := 0.0
var dodge_direction := Vector3.ZERO
var dodge_contact_checked := false
var dodge_was_perfect := false
var safe_position := Vector3.ZERO

func _ready() -> void:
    # Browsers reject pointer lock unless it originates from a real user gesture.
    # Native desktop keeps the immediate capture behaviour.
    if OS.has_feature("web"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        mouse_capture_changed.emit(false)
    else:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        mouse_capture_changed.emit(true)
    health.died.connect(func(source_id: StringName): died.emit(source_id))
    health.damaged.connect(_on_health_damaged)
    focus = max_focus
    stamina = max_stamina
    safe_position = global_position

func _unhandled_input(event: InputEvent) -> void:
    if _request_mouse_capture_from_user_gesture(event):
        return
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
        if power_cooldown <= 0.0:
            power_cooldown = power_recovery
            power_requested.emit()
    elif event.is_action_pressed("dodge"):
        _start_dodge()
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

func _request_mouse_capture_from_user_gesture(event: InputEvent) -> bool:
    if not OS.has_feature("web") or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        return false
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            mouse_capture_changed.emit(true)
            get_viewport().set_input_as_handled()
            return true
    return false

func _physics_process(delta: float) -> void:
    primary_cooldown = maxf(0.0, primary_cooldown - delta)
    power_cooldown = maxf(0.0, power_cooldown - delta)
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    dodge_invulnerability_remaining = maxf(0.0, dodge_invulnerability_remaining - delta)
    if dodge_time_remaining > 0.0:
        dodge_time_remaining = maxf(0.0, dodge_time_remaining - delta)
        dodge_elapsed += delta
        velocity.x = dodge_direction.x * dodge_speed
        velocity.z = dodge_direction.z * dodge_speed
        if not is_on_floor():
            velocity.y -= gravity * delta
        move_and_slide()
        _update_safe_position()
        if dodge_time_remaining <= 0.0:
            dodge_completed.emit(dodge_was_perfect)
        return

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
    _update_safe_position()

func _start_dodge() -> bool:
    if dodge_cooldown > 0.0 or dodge_time_remaining > 0.0 or stamina < dodge_stamina_cost:
        return false
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    forward.y = 0.0
    right.y = 0.0
    var requested := (right * input_vec.x + forward * -input_vec.y).normalized()
    dodge_direction = requested if requested.length_squared() > 0.01 else forward.normalized()
    stamina -= dodge_stamina_cost
    dodge_time_remaining = dodge_duration
    dodge_invulnerability_remaining = dodge_invulnerability
    dodge_elapsed = 0.0
    dodge_contact_checked = false
    dodge_was_perfect = false
    dodge_cooldown = dodge_recovery
    _apply_dodge_mutation(PowerMutationRuntime.on_dodge(false, {"stamina": stamina}))
    dodge_started.emit(perfect_dodge_window)
    VFXDirector.emit_feedback(&"player_dodge", global_position + Vector3.UP * 0.85, dodge_direction)
    AudioDirector.play_3d(&"dodge", global_position)
    return true

func _update_safe_position() -> void:
    if is_on_floor() and global_position.y > fall_recovery_y:
        safe_position = global_position
    if global_position.y < fall_recovery_y:
        _recover_from_fall()

func _recover_from_fall() -> void:
    global_position = safe_position + Vector3(0.0, 0.35, 0.0)
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

func get_power_cooldown() -> float:
    return power_cooldown

func apply_damage(amount: float, source_id: StringName = &"") -> bool:
    if dodge_invulnerability_remaining > 0.0:
        if not dodge_contact_checked:
            dodge_contact_checked = true
            dodge_was_perfect = dodge_elapsed <= perfect_dodge_window
            if dodge_was_perfect:
                _apply_dodge_mutation(PowerMutationRuntime.on_dodge(true, {"source_id": source_id, "stamina": stamina}))
                VFXDirector.emit_feedback(&"perfect_dodge", global_position + Vector3.UP * 0.9, dodge_direction)
                AudioDirector.play_3d(&"perfect_dodge", global_position)
        return false
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

func _apply_dodge_mutation(result: Dictionary) -> void:
    stamina = minf(max_stamina, stamina + float(result.get("stamina", 0.0)))
    var charges := int(result.get("charges", 0))
    if charges > 0:
        RogueliteContentService.recharge_instrument(charges)
    if bool(result.get("projectile_invulnerability", false)):
        dodge_invulnerability_remaining = maxf(dodge_invulnerability_remaining, dodge_duration)

func _on_health_damaged(_current: float, _maximum: float, amount: float, source_id: StringName) -> void:
    GameState.run_stats["damage_taken"] = float(GameState.run_stats.get("damage_taken", 0.0)) + amount
    var mutation_result := PowerMutationRuntime.on_player_damaged(amount, {"focus": focus})
    restore_focus(float(mutation_result.get("focus_gain", 0.0)))
    shield += float(mutation_result.get("shield_gain", 0.0))
    damaged.emit(amount, source_id)
    AudioDirector.play_3d(&"player_hit", global_position)
