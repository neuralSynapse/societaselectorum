extends Node
class_name CombatFeedback

static func impact(root: Node, position: Vector3, intensity: float = 1.0) -> void:
    if root == null:
        return
    var holder := Node3D.new()
    holder.name = "CombatImpactFeedback"
    root.add_child(holder)
    holder.global_position = position

    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.08 * maxf(0.5, intensity)
    mesh.height = mesh.radius * 2.0
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(1.0, 0.48, 0.16, 0.8)
    material.emission_enabled = true
    material.emission = Color(0.9, 0.25, 0.05)
    material.emission_energy_multiplier = minf(1.4, 0.55 + intensity * 0.25)
    mesh_instance.material_override = material
    holder.add_child(mesh_instance)

    var light := OmniLight3D.new()
    light.omni_range = 2.2 + intensity
    light.light_energy = 0.7 + intensity * 0.2
    holder.add_child(light)

    var tween := holder.create_tween()
    tween.set_parallel(true)
    tween.tween_property(holder, "scale", Vector3.ONE * (1.8 + intensity * 0.2), 0.18)
    tween.tween_property(mesh_instance, "transparency", 1.0, 0.2)
    tween.set_parallel(false)
    tween.tween_callback(holder.queue_free)

static func hit_flash(visual: Node3D, intensity: float = 1.0) -> void:
    if visual == null:
        return
    var base_scale := visual.scale
    var tween := visual.create_tween()
    tween.tween_property(visual, "scale", base_scale * (1.0 + minf(0.08, intensity * 0.025)), 0.045)
    tween.tween_property(visual, "scale", base_scale, 0.09)
