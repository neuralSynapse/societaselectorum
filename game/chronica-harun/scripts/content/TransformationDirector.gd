extends Node
class_name TransformationDirector

var active: Dictionary = {}

func reconcile(target: Node3D, transformation_ids: Array) -> void:
    var desired := {}
    for id in transformation_ids: desired[String(id)] = true
    for existing in active.keys():
        if not desired.has(existing):
            var node = active[existing]
            if is_instance_valid(node): node.queue_free()
            active.erase(existing)
    for id in desired:
        if active.has(id): continue
        var row := ContentRegistry.get_item("transformations",StringName(id))
        if row.is_empty(): continue
        active[id] = _create_manifestation(target,row)

func _create_manifestation(target: Node3D, row: Dictionary) -> Node3D:
    var profile: Dictionary = row.get("visual_profile",{})
    var root := Node3D.new(); root.name = "Transformation_%s" % row.id
    root.set_meta("mesh_overlay",profile.get("mesh_overlay","")); root.set_meta("material_shift",profile.get("material_shift","")); root.set_meta("vfx",profile.get("vfx",""))
    var mesh_overlay := MeshInstance3D.new(); mesh_overlay.name = "MeshOverlay"
    var mesh := TorusMesh.new(); mesh.inner_radius = .31; mesh.outer_radius = .35; mesh.rings = 12; mesh.ring_segments = 20; mesh_overlay.mesh = mesh; mesh_overlay.position = Vector3(0,1.7,0)
    var material_shift := StandardMaterial3D.new(); material_shift.albedo_color = _shift_color(String(profile.get("material_shift",""))); material_shift.roughness = .72; material_shift.metallic = .08; material_shift.emission_enabled = false
    mesh_overlay.material_override = material_shift
    root.add_child(mesh_overlay)
    var vfx := OmniLight3D.new(); vfx.name = "VFX_%s" % profile.get("vfx","subtle"); vfx.light_energy = minf(.35,float(profile.get("emission_cap",.34))); vfx.omni_range = 1.5; root.add_child(vfx)
    target.add_child(root)
    return root

func _shift_color(tag: String) -> Color:
    if "gold" in tag: return Color(0.55,0.43,0.22)
    if "violet" in tag: return Color(0.30,0.24,0.36)
    if "serpentine" in tag: return Color(0.22,0.31,0.22)
    if "obsidian" in tag: return Color(0.08,0.07,0.09)
    return Color(0.28,0.24,0.19)
