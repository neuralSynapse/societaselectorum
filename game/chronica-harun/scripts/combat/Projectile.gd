extends Area3D
class_name ReadableProjectile

signal impacted(position: Vector3, target: Node)

@export var speed := 11.0
@export var damage := 10.0
@export var lifetime := 5.0
@export var emission_budget := 0.45
var direction := Vector3.FORWARD
var source_id: StringName = &""
var age := 0.0
var active := false

func _ready() -> void:
    add_to_group("hostile_projectiles")

func configure(profile: Dictionary, origin: Vector3, travel_direction: Vector3, from_source: StringName = &"") -> void:
    global_position = origin
    direction = travel_direction.normalized()
    speed = float(profile.get("speed", speed))
    damage = float(profile.get("damage", damage))
    lifetime = float(profile.get("lifetime", lifetime))
    emission_budget = minf(VFXDirector.MAX_EMISSION, float(profile.get("emission", emission_budget)))
    source_id = from_source
    active = true
    var mesh_instance := get_node_or_null("Mesh") as MeshInstance3D
    if mesh_instance and mesh_instance.material_override is StandardMaterial3D:
        var material := mesh_instance.material_override as StandardMaterial3D
        material.emission_energy_multiplier = emission_budget

func _physics_process(delta: float) -> void:
    if not active:
        return
    age += delta
    if age >= lifetime:
        queue_free()
        return
    global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
    if not active:
        return
    if body.has_method("apply_damage"):
        var mutation_result := PowerMutationRuntime.on_projectile_about_to_hit({"source_id": String(source_id)})
        if mutation_result.get("ignore", false):
            VFXDirector.emit_feedback(&"projectile_impact", global_position, -direction, {"ignored":true})
            AudioDirector.play_3d(&"projectile_impact", global_position)
            active = false
            queue_free()
            return
        body.apply_damage(damage, source_id)
    VFXDirector.emit_feedback(&"projectile_impact", global_position, -direction, {"source_id":String(source_id)})
    AudioDirector.play_3d(&"projectile_impact", global_position)
    impacted.emit(global_position, body)
    active = false
    queue_free()
