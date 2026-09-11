extends EnemyBrain
class_name DataEnemy

const PROJECTILE_SCENE := preload("res://scenes/vfx/Projectile.tscn")

var content_data: Dictionary = {}
var family := "walker"
var behavior_clock := 0.0
var hover_base_y := 0.0
var behavior_sign := 1.0
var difficulty_scalar := 1.0
var stage_pressure := 1.0
var room_pressure := 1.0
var damage_scale := 1.0
var tactical_seal := "pressure"
var vulnerability_window := false
var vulnerability_until_msec := 0
var elite_reinforced := false

func configure_from_data(data: Dictionary, next_target: Node3D = null) -> void:
    content_data = data.duplicate(true)
    enemy_id = StringName(data.get("id", "enemy"))
    display_name = String(data.get("display_name", "Presença"))
    role = String(data.get("role", "unknown"))
    family = String(data.get("family", "walker"))
    attack_definition = data.get("attack", {}).duplicate(true)
    attack_name = String(attack_definition.get("display_name", attack_definition.get("id", "Ataque")))
    move_speed = float(data.get("move_speed", data.get("stats", {}).get("move_speed", 2.8)))
    preferred_range = 4.8 if String(attack_definition.get("attack_kind", "movement")) == "projectile" else 1.15
    behavior_sign = -1.0 if abs(hash(String(enemy_id))) % 2 == 0 else 1.0
    tactical_seal = _resolve_tactical_seal()
    if next_target != null:
        target = next_target
    if is_node_ready():
        _apply_stats()

func _ready() -> void:
    super._ready()
    _apply_stats()
    hover_base_y = global_position.y

func get_attack_state_machine() -> AttackStateMachine:
    return attack_sm

func reinforce_elite() -> void:
    if elite_reinforced:
        return
    elite_reinforced = true
    role = "elite"
    combat_level += 2
    difficulty_scalar *= 1.28
    damage_scale *= 1.18
    move_speed *= 1.10
    if health:
        health.max_health *= 1.32
        health.current_health = health.max_health
    if not attack_definition.is_empty():
        attack_definition["damage"] = float(attack_definition.get("damage", 10.0)) * 1.18

func _apply_stats() -> void:
    var stage_depth := GameState.stage_index + 1
    if String(GameState.journey_state) == GameState.JOURNEY_DEGREE:
        stage_depth = 15 + int(GameState.meta_progression.get("degree_current", 1))
    var rooms_cleared := int(GameState.run_stats.get("rooms_cleared", 0))
    stage_pressure = 1.0 + minf(0.85, float(stage_depth - 1) * 0.045)
    room_pressure = 1.0 + minf(0.45, float(rooms_cleared) * 0.035)
    difficulty_scalar = 1.35 * stage_pressure * room_pressure
    damage_scale = 1.18 * stage_pressure * minf(room_pressure, 1.30)
    combat_level = maxi(combat_level, 1 + int(floor(float(stage_depth) / 3.0)) + int(floor(float(rooms_cleared) / 4.0)))

    var base_move_speed := float(content_data.get("move_speed", content_data.get("stats", {}).get("move_speed", 2.8)))
    move_speed = base_move_speed
    move_speed *= 1.10 + minf(0.22, (stage_pressure - 1.0) * 0.22 + (room_pressure - 1.0) * 0.18)

    if health:
        var base_hp := float(content_data.get("max_hp", content_data.get("stats", {}).get("max_health", 60.0)))
        health.max_health = base_hp * difficulty_scalar
        health.current_health = health.max_health

    var base_attack: Dictionary = content_data.get("attack", {}).duplicate(true)
    if not base_attack.is_empty():
        attack_definition = base_attack
        attack_definition["damage"] = float(base_attack.get("damage", 10.0)) * damage_scale
        attack_definition["windup"] = maxf(0.24, float(base_attack.get("windup", 0.4)) * 0.92)
        attack_definition["recovery"] = maxf(0.30, float(base_attack.get("recovery", 0.6)) * 0.88)
        attack_name = String(attack_definition.get("display_name", attack_definition.get("id", "Ataque")))
    attack_cooldown = 0.28 + float(abs(hash(String(enemy_id))) % 70) / 240.0
    tactical_seal = _resolve_tactical_seal()

func think(delta: float) -> void:
    behavior_clock += delta
    vulnerability_window = Time.get_ticks_msec() <= vulnerability_until_msec
    face_target()
    var distance: float = distance_to_target()
    match family:
        "ram_archon":
            _ram_charge_stalk(delta, distance)
        "hyena_archon":
            _zigzag_hunt(delta, distance)
        "asinine_archon":
            _strafe_ranged(delta, distance)
        "chorus":
            _orbit_ranged(delta, distance)
        "fire", "beast":
            _burst_pursuit(delta, distance)
        "construct":
            _anchor_advance(delta, distance)
        "walker":
            _skitter_flank(delta, distance)
        "crawler":
            _pursue(delta, distance, 1.24)
        "eye", "seven_head_serpent", "fire_face", "ritualist":
            _ranged_spacing(delta, distance)
        "shade":
            _phase_stalk(delta, distance)
        "chain", "simian_archon":
            _pursue(delta, distance, 0.78)
        "winged":
            _hover_skirmish(delta, distance)
        "serpent", "draconic":
            _serpentine(delta, distance)
        _:
            _pursue(delta, distance, 0.96)
    if attack_cooldown <= 0.0 and distance <= float(attack_definition.get("range", preferred_range + 0.8)):
        if request_attack(attack_definition):
            attack_cooldown = maxf(0.38, (float(attack_definition.get("windup", 0.4)) + float(attack_definition.get("recovery", 0.6)) + 0.16) / minf(1.45, stage_pressure))

func apply_damage(amount: float, source_id: StringName = &"") -> bool:
    if health == null:
        return false
    var multiplier := _incoming_damage_multiplier(source_id)
    return health.apply_damage(amount * multiplier, source_id)

func _incoming_damage_multiplier(source_id: StringName) -> float:
    if String(source_id) in ["ritual_effect", "tower", "sun", "sacrifice_room"]:
        return 1.0
    var now := Time.get_ticks_msec()
    var revealed := has_meta("revealed_until") and int(get_meta("revealed_until")) >= now
    if vulnerability_window:
        return 1.0
    match tactical_seal:
        "revelation": return 1.0 if revealed else 0.42
        "fracture": return 0.50
        "observation": return 0.58
        "counterstep": return 0.68
        "pressure": return 0.84
        _: return 1.0

func _resolve_tactical_seal() -> String:
    match family:
        "shade": return "revelation"
        "construct", "chain": return "fracture"
        "eye", "ritualist", "chorus", "fire_face": return "observation"
        "serpent", "draconic", "seven_head_serpent", "ram_archon": return "counterstep"
        _: return "pressure"

func _on_attack_state_changed(state: StringName) -> void:
    super._on_attack_state_changed(state)
    if state == &"windup":
        var windup := float(attack_definition.get("windup", 0.4))
        vulnerability_until_msec = Time.get_ticks_msec() + int((windup + 0.20) * 1000.0)
        vulnerability_window = true
    elif state == &"recovery":
        vulnerability_until_msec = max(vulnerability_until_msec, Time.get_ticks_msec() + 360)
        vulnerability_window = true

func _pursue(delta: float, distance: float, speed_multiplier: float) -> void:
    if distance > preferred_range:
        move_toward_target(delta, speed_multiplier)
    else:
        velocity = Vector3.ZERO

func _ranged_spacing(delta: float, distance: float) -> void:
    if distance < preferred_range * 0.7:
        move_away_from_target(delta, 0.92)
    elif distance > preferred_range * 1.3:
        move_toward_target(delta, 0.72)
    else:
        var pulse := sin(behavior_clock * 2.4)
        if abs(pulse) > 0.55:
            _strafe_ranged(delta, distance)
        else:
            velocity = Vector3.ZERO

func _phase_stalk(delta: float, distance: float) -> void:
    if distance > 1.1:
        move_toward_target(delta, 0.72 if int(behavior_clock * 2.0) % 2 == 0 else 1.34)

func _hover_skirmish(delta: float, distance: float) -> void:
    global_position.y = hover_base_y + 0.14 + sin(behavior_clock * 3.1) * 0.1
    _ranged_spacing(delta, distance)

func _serpentine(delta: float, distance: float) -> void:
    if distance > 1.0:
        move_toward_target(delta, 0.96 + abs(sin(behavior_clock * 4.4)) * 0.34)
        rotate_y(sin(behavior_clock * 4.0) * delta * 0.8)

func _ram_charge_stalk(delta: float, distance: float) -> void:
    if distance <= preferred_range:
        velocity = Vector3.ZERO
        return
    var phase: float = fmod(behavior_clock, 2.05)
    var multiplier: float = 2.05 if phase < 0.46 else 0.62
    move_toward_target(delta, multiplier)

func _zigzag_hunt(delta: float, distance: float) -> void:
    if target == null or distance <= preferred_range:
        velocity = Vector3.ZERO
        return
    var forward: Vector3 = target.global_position - global_position
    forward.y = 0.0
    if forward.length_squared() <= 0.001:
        return
    forward = forward.normalized()
    var side: Vector3 = Vector3(-forward.z, 0.0, forward.x)
    var weave: float = sin(behavior_clock * 6.8 + float(abs(hash(String(enemy_id))) % 13)) * 0.78
    _move_direction(delta, (forward + side * weave).normalized(), 1.15)

func _strafe_ranged(delta: float, distance: float) -> void:
    if target == null:
        return
    if distance < preferred_range * 0.72:
        move_away_from_target(delta, 0.94)
        return
    if distance > preferred_range * 1.38:
        move_toward_target(delta, 0.68)
        return
    var radial: Vector3 = target.global_position - global_position
    radial.y = 0.0
    if radial.length_squared() <= 0.001:
        return
    radial = radial.normalized()
    var tangent: Vector3 = Vector3(-radial.z, 0.0, radial.x) * behavior_sign
    _move_direction(delta, tangent, 0.86)

func _orbit_ranged(delta: float, distance: float) -> void:
    if target == null:
        return
    var radial: Vector3 = target.global_position - global_position
    radial.y = 0.0
    if radial.length_squared() <= 0.001:
        return
    radial = radial.normalized()
    var tangent: Vector3 = Vector3(-radial.z, 0.0, radial.x) * behavior_sign
    var correction: float = clampf((distance - preferred_range) / maxf(1.0, preferred_range), -0.7, 0.7)
    var direction: Vector3 = (tangent + radial * correction).normalized()
    _move_direction(delta, direction, 0.82)

func _burst_pursuit(delta: float, distance: float) -> void:
    if distance <= preferred_range:
        velocity = Vector3.ZERO
        return
    var phase: float = fmod(behavior_clock + float(abs(hash(String(enemy_id))) % 7) * 0.13, 1.45)
    var multiplier: float = 1.72 if phase < 0.50 else 0.78
    move_toward_target(delta, multiplier)

func _anchor_advance(delta: float, distance: float) -> void:
    if distance <= preferred_range:
        velocity = Vector3.ZERO
        return
    var phase: float = fmod(behavior_clock, 1.35)
    if phase < 0.60:
        move_toward_target(delta, 1.08)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
        move_and_slide()

func _skitter_flank(delta: float, distance: float) -> void:
    if target == null or distance <= preferred_range:
        velocity = Vector3.ZERO
        return
    var forward: Vector3 = target.global_position - global_position
    forward.y = 0.0
    if forward.length_squared() <= 0.001:
        return
    forward = forward.normalized()
    var side: Vector3 = Vector3(-forward.z, 0.0, forward.x)
    var flank: float = sin(behavior_clock * 4.1) * 0.58 * behavior_sign
    _move_direction(delta, (forward + side * flank).normalized(), 1.02)

func _move_direction(delta: float, direction: Vector3, speed_multiplier: float) -> void:
    if direction.length_squared() <= 0.001:
        velocity = Vector3.ZERO
        return
    var desired: Vector3 = direction.normalized() * move_speed * speed_multiplier
    velocity.x = move_toward(velocity.x, desired.x, 14.0 * delta)
    velocity.z = move_toward(velocity.z, desired.z, 14.0 * delta)
    move_and_slide()

func _on_emission_requested(payload: Dictionary) -> void:
    var definition: Dictionary = payload.get("definition", {})
    if String(definition.get("attack_kind", "")) != "projectile" or target == null:
        return
    var pattern := String(definition.get("pattern", "line"))
    var origin := projectile_origin.global_position
    var base := (target.global_position + Vector3.UP - origin).normalized()
    var angles: Array[float] = []
    match pattern:
        "radial":
            for i in range(10): angles.append(i * TAU / 10.0)
        "fan": angles = [-0.34, -0.16, 0.0, 0.16, 0.34]
        "zone": angles = [-0.48, -0.24, 0.0, 0.24, 0.48]
        _:
            angles = [0.0]
    for angle in angles:
        var direction := base.rotated(Vector3.UP, angle)
        if pattern == "radial": direction = Vector3(cos(angle), 0.0, sin(angle))
        var projectile := PROJECTILE_SCENE.instantiate() as ReadableProjectile
        get_tree().current_scene.add_child(projectile)
        projectile.configure({"speed": 9.5 + move_speed, "damage": float(definition.get("damage", 10.0)), "lifetime": 5.0, "emission": 0.50}, origin, direction, enemy_id)
    AudioDirector.play_3d(&"enemy_shot", origin)
