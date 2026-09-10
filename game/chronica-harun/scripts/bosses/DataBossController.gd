extends CharacterBody3D
class_name DataBossController

signal phase_changed(index: int)
signal boss_defeated(boss_id: StringName, reward_id: StringName)
signal combat_status_changed(boss: DataBossController, health_ratio: float)

const PROJECTILE_SCENE := preload("res://scenes/vfx/Projectile.tscn")

var boss_id: StringName = &"boss"
var display_name := "Autoridade"
var reward_id: StringName = &""
var content_data: Dictionary = {}
var phases: Array = []
var target: Node3D
var current_phase := 0
var attack_index := 0
var attack_clock := 0.8
var move_speed := 1.7
var dead := false
var combat_level := 1
var current_attack_name := ""

@onready var health: Health = $Health
@onready var attack_sm: AttackStateMachine = $AttackStateMachine
@onready var projectile_origin: Marker3D = $ProjectileOrigin
@onready var visual: Node3D = $Visual

func configure(id: StringName, next_target: Node3D) -> bool:
    var data := ContentRegistry.get_boss(id)
    if data.is_empty():
        push_error("Unknown boss: %s" % id)
        return false
    content_data = data.duplicate(true)
    boss_id = id
    display_name = String(data.get("display_name", id))
    reward_id = StringName(data.get("reward_id", ""))
    phases = data.get("phases", []).duplicate(true)
    move_speed = float(data.get("move_speed", 1.7))
    combat_level = int(data.get("level", maxi(1, GameState.stage_index + GameState.cycle + 4)))
    target = next_target
    return true

func _ready() -> void:
    health.max_health = float(content_data.get("max_hp", 900.0))
    health.current_health = health.max_health
    health.damaged.connect(_on_damaged)
    health.died.connect(_on_died)
    attack_sm.state_changed.connect(_on_attack_state_changed)
    attack_sm.emission_requested.connect(_on_emission_requested)
    attack_sm.telegraph_started.connect(_on_telegraph_started)
    _attach_model()
    add_to_group("bosses")

func _process(delta: float) -> void:
    if dead or target == null or phases.is_empty():
        return
    attack_clock -= delta
    _face_target()
    if attack_clock <= 0.0 and not attack_sm.busy:
        _choose_attack()

func apply_damage(amount: float, source_id: StringName = &"") -> bool:
    return health.apply_damage(amount, source_id)

func get_health_ratio() -> float:
    if health == null:
        return 0.0
    return health.ratio()

func get_attack_name() -> String:
    return current_attack_name

func _choose_attack() -> void:
    var phase_data: Dictionary = phases[current_phase]
    var attacks: Array = phase_data.get("attacks", [])
    if attacks.is_empty():
        return
    var definition: Dictionary = attacks[attack_index % attacks.size()].duplicate(true)
    current_attack_name = String(definition.get("display_name", definition.get("name", definition.get("id", "PODER"))))
    attack_index += 1
    if attack_sm.begin_attack(definition, target):
        attack_clock = float(definition.get("recovery", 0.7)) + 0.25

func _on_attack_state_changed(state: StringName) -> void:
    if state == &"windup":
        VFXDirector.emit_feedback(&"boss_windup", global_position + Vector3.UP * 1.0, Vector3.UP)
        AudioDirector.play_3d(&"boss_windup", global_position)

func _on_telegraph_started(_payload: Dictionary) -> void:
    VFXDirector.emit_feedback(&"enemy_telegraph", global_position + Vector3.UP * 0.03, Vector3.UP, {"boss":true})

func _on_emission_requested(payload: Dictionary) -> void:
    var definition: Dictionary = payload.get("definition", {})
    var pattern := String(definition.get("pattern", "line"))
    VFXDirector.emit_feedback(&"boss_attack", projectile_origin.global_position, -global_transform.basis.z, {"pattern":pattern})
    AudioDirector.play_3d(&"boss_attack", projectile_origin.global_position)
    if String(definition.get("attack_kind", "")) == "movement":
        _movement_attack(pattern)
    else:
        _projectile_pattern(pattern, definition)

func _projectile_pattern(pattern: String, definition: Dictionary) -> void:
    if target == null:
        return
    var origin := projectile_origin.global_position
    var base := (target.global_position + Vector3.UP - origin).normalized()
    var angles: Array[float] = []
    match pattern:
        "radial":
            for i in range(10): angles.append(i * TAU / 10.0)
        "fan": angles = [-0.42, -0.21, 0.0, 0.21, 0.42]
        "summon": angles = [-0.32, 0.0, 0.32]
        "zone": angles = [-0.55, -0.28, 0.0, 0.28, 0.55]
        _: angles = [-0.08, 0.0, 0.08]
    for angle in angles:
        var direction := base.rotated(Vector3.UP, angle)
        if pattern == "radial": direction = Vector3(cos(angle), 0.0, sin(angle))
        var projectile := PROJECTILE_SCENE.instantiate() as ReadableProjectile
        get_tree().current_scene.add_child(projectile)
        projectile.configure({"speed": 10.0 + current_phase * 1.4, "damage": float(definition.get("damage", 20.0)), "emission": 0.5, "lifetime": 5.2}, origin, direction, boss_id)
    AudioDirector.play_3d(&"enemy_shot", origin)

func _movement_attack(pattern: String) -> void:
    if target == null:
        return
    var delta := target.global_position - global_position
    delta.y = 0.0
    if delta.length_squared() <= 0.01:
        return
    velocity = delta.normalized() * (8.0 if pattern == "dash" else 5.0)
    move_and_slide()

func _on_damaged(current: float, maximum: float, _amount: float, _source_id: StringName) -> void:
    VFXDirector.emit_feedback(&"enemy_hit", global_position + Vector3.UP * 1.0, Vector3.UP, {"boss":true})
    AudioDirector.play_3d(&"enemy_hit", global_position)
    var ratio := current / maxf(1.0, maximum)
    combat_status_changed.emit(self, ratio)
    var next_phase := 2 if ratio <= 0.32 else (1 if ratio <= 0.66 else 0)
    if next_phase != current_phase:
        current_phase = next_phase
        attack_index = 0
        phase_changed.emit(current_phase + 1)
        VFXDirector.emit_feedback(&"boss_phase", global_position + Vector3.UP * 0.05, Vector3.UP, {"phase":current_phase + 1})
        AudioDirector.play_3d(&"boss_phase", global_position)

func _on_died(_source_id: StringName) -> void:
    if dead:
        return
    dead = true
    combat_status_changed.emit(self, 0.0)
    VFXDirector.emit_feedback(&"boss_death", global_position + Vector3.UP * 0.08, Vector3.UP)
    AudioDirector.play_3d(&"boss_death", global_position)
    boss_defeated.emit(boss_id, reward_id)
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector3.ZERO, 0.7)
    tween.tween_callback(queue_free)

func _face_target() -> void:
    if target == null:
        return
    var flat := Vector3(target.global_position.x, global_position.y, target.global_position.z)
    if flat.distance_to(global_position) > 0.05:
        look_at(flat, Vector3.UP)

func _attach_model() -> void:
    var path := String(content_data.get("model_path", ""))
    if not path.is_empty() and ResourceLoader.exists(path):
        var resource = load(path)
        if resource is PackedScene:
            visual.add_child((resource as PackedScene).instantiate())
            return
    var fallback := MeshInstance3D.new()
    var mesh := SphereMesh.new(); mesh.radius = 0.9; mesh.height = 1.8
    fallback.mesh = mesh
    var material := StandardMaterial3D.new(); material.albedo_color = Color(0.12, 0.09, 0.06); material.roughness = 0.82; material.emission_enabled = false
    fallback.material_override = material
    fallback.position.y = 1.1
    visual.add_child(fallback)
