extends Node3D
class_name ReadableTelegraph

var _active: Array[MeshInstance3D] = []
var _generation := 0

func show_attack(definition: Dictionary, target: Node3D, origin: Vector3) -> void:
    clear()
    _generation += 1
    var generation := _generation
    global_position = origin
    var pattern := String(definition.get("pattern", "line"))
    var duration := maxf(0.08, float(definition.get("telegraph_time", 0.25)))
    var attack_range := maxf(1.0, float(definition.get("range", 5.0)))
    var direction := Vector3.FORWARD
    if target != null:
        direction = target.global_position - origin
        direction.y = 0.0
        if direction.length_squared() > 0.001:
            direction = direction.normalized()
    match pattern:
        "line", "dash":
            _add_strip(direction, attack_range, 0.34 if pattern == "line" else 0.62)
        "fan":
            for angle in [-0.34, 0.0, 0.34]:
                _add_strip(direction.rotated(Vector3.UP, angle), attack_range, 0.28)
        "radial":
            for i in range(12):
                _add_strip(Vector3.FORWARD.rotated(Vector3.UP, i * TAU / 12.0), attack_range * 0.72, 0.22)
        "zone", "summon":
            _add_zone(attack_range * (0.42 if pattern == "zone" else 0.3))
        _:
            _add_strip(direction, attack_range, 0.34)
    var timer := get_tree().create_timer(duration)
    timer.timeout.connect(func():
        if generation == _generation:
            clear()
    )

func clear() -> void:
    _generation += 1
    for mesh in _active:
        if is_instance_valid(mesh):
            mesh.queue_free()
    _active.clear()

func _material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(0.95, 0.32, 0.08, 0.27)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.no_depth_test = false
    return material

func _add_strip(direction: Vector3, length: float, width: float) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(width, 0.025, length)
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _material()
    var midpoint := direction * (length * 0.5)
    mesh_instance.position = midpoint + Vector3(0.0, 0.035, 0.0)
    if direction.length_squared() > 0.001:
        mesh_instance.look_at(global_position + direction, Vector3.UP)
    add_child(mesh_instance)
    _active.append(mesh_instance)

func _add_zone(radius: float) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = 0.025
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _material()
    mesh_instance.position.y = 0.035
    add_child(mesh_instance)
    _active.append(mesh_instance)
