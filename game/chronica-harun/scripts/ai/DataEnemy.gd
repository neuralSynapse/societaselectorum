extends EnemyBrain
class_name DataEnemy

const PROJECTILE_SCENE := preload("res://scenes/vfx/Projectile.tscn")

var content_data: Dictionary = {}
var family := "walker"
var behavior_clock := 0.0
var hover_base_y := 0.0

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

func _apply_stats() -> void:
    if health:
        health.max_health = float(content_data.get("max_hp", content_data.get("stats", {}).get("max_health", 60.0)))
        health.current_health = health.max_health
    attack_cooldown = 0.45 + float(abs(hash(String(enemy_id))) % 100) / 190.0

func think(delta: float) -> void:
    behavior_clock += delta
    face_target()
    var distance := distance_to_target()
    match family:
        "crawler", "ram_archon", "hyena_archon", "beast":
            _pursue(delta, distance, 1.16)
        "eye", "seven_head_serpent", "fire_face", "ritualist", "chorus":
            _ranged_spacing(delta, distance)
        "shade":
            _phase_stalk(delta, distance)
        "chain", "construct", "simian_archon":
            _pursue(delta, distance, 0.62)
        "winged":
            _hover_skirmish(delta, distance)
        "serpent", "draconic":
            _serpentine(delta, distance)
        "asinine_archon":
            _ranged_spacing(delta, distance)
        _:
            _pursue(delta, distance, 0.82)
    if attack_cooldown <= 0.0 and distance <= float(attack_definition.get("range", preferred_range + 0.8)):
        if request_attack(attack_definition):
            attack_cooldown = float(attack_definition.get("windup", 0.4)) + float(attack_definition.get("recovery", 0.6)) + 0.25

func _pursue(delta: float, distance: float, speed_multiplier: float) -> void:
    if distance > preferred_range:
        move_toward_target(delta, speed_multiplier)
    else:
        velocity = Vector3.ZERO

func _ranged_spacing(delta: float, distance: float) -> void:
    if distance < preferred_range * 0.7:
        move_away_from_target(delta, 0.72)
    elif distance > preferred_range * 1.3:
        move_toward_target(delta, 0.55)
    else:
        velocity = Vector3.ZERO

func _phase_stalk(delta: float, distance: float) -> void:
    if distance > 1.1:
        move_toward_target(delta, 0.6 if int(behavior_clock * 2.0) % 2 == 0 else 1.15)

func _hover_skirmish(delta: float, distance: float) -> void:
    global_position.y = hover_base_y + 0.14 + sin(behavior_clock * 3.1) * 0.1
    _ranged_spacing(delta, distance)

func _serpentine(delta: float, distance: float) -> void:
    if distance > 1.0:
        move_toward_target(delta, 0.82 + abs(sin(behavior_clock * 4.4)) * 0.25)
        rotate_y(sin(behavior_clock * 4.0) * delta * 0.6)

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
            for i in range(8): angles.append(i * TAU / 8.0)
        "fan": angles = [-0.28, 0.0, 0.28]
        "zone": angles = [-0.42, -0.21, 0.0, 0.21, 0.42]
        _:
            angles = [0.0]
    for angle in angles:
        var direction := base.rotated(Vector3.UP, angle)
        if pattern == "radial": direction = Vector3(cos(angle), 0.0, sin(angle))
        var projectile := PROJECTILE_SCENE.instantiate() as ReadableProjectile
        get_tree().current_scene.add_child(projectile)
        projectile.configure({"speed": 8.5 + move_speed, "damage": float(definition.get("damage", 10.0)), "lifetime": 5.0, "emission": 0.42}, origin, direction, enemy_id)
    AudioDirector.play_3d(&"enemy_shot", origin)
