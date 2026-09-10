extends Node3D
class_name RoomShell

signal player_entered(room_id: StringName)

@export var room_id: StringName = &"room"
@export var room_role: StringName = &"combat"
var locked := false
var cleared := false

func _ready() -> void:
    _build_gothic_dressing()
    _apply_role_lighting()
    var trigger := get_node_or_null("EncounterTrigger") as Area3D
    if trigger:
        trigger.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body is PlayerController:
        player_entered.emit(room_id)

func set_locked(value: bool) -> void:
    locked = value
    set_meta("locked", value)
    var door_set := get_node_or_null("DoorSet")
    if door_set:
        for child in door_set.get_children():
            if child is StaticBody3D:
                child.collision_layer = 2 if value else 0
                child.visible = value

func mark_cleared() -> void:
    cleared = true
    set_locked(false)

func _build_gothic_dressing() -> void:
    if has_node("GothicDressing"):
        return
    var dressing := Node3D.new()
    dressing.name = "GothicDressing"
    add_child(dressing)

    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.045, 0.035, 0.032, 1.0)
    stone.metallic = 0.16
    stone.roughness = 0.78

    var bronze := StandardMaterial3D.new()
    bronze.albedo_color = Color(0.20, 0.075, 0.024, 1.0)
    bronze.metallic = 0.82
    bronze.roughness = 0.30
    bronze.emission_enabled = true
    bronze.emission = Color(0.16, 0.025, 0.006, 1.0)
    bronze.emission_energy_multiplier = 0.32

    for position in [Vector3(-4.15, 2.0, -4.15), Vector3(4.15, 2.0, -4.15), Vector3(-4.15, 2.0, 4.15), Vector3(4.15, 2.0, 4.15)]:
        _add_pillar(dressing, position, stone, bronze)

    for x in [-3.05, 0.0, 3.05]:
        _add_wall_rib(dressing, Vector3(x, 3.0, -4.78), Vector3(0.26, 2.25, 0.18), stone)
        _add_wall_rib(dressing, Vector3(x, 3.0, 4.78), Vector3(0.26, 2.25, 0.18), stone)
    for z in [-3.05, 0.0, 3.05]:
        _add_wall_rib(dressing, Vector3(-4.78, 3.0, z), Vector3(0.18, 2.25, 0.26), stone)
        _add_wall_rib(dressing, Vector3(4.78, 3.0, z), Vector3(0.18, 2.25, 0.26), stone)

    var vault_ribs := Node3D.new()
    vault_ribs.name = "VaultRibs"
    dressing.add_child(vault_ribs)
    _add_vault_ribs(vault_ribs, stone, bronze)

    var door_arches := Node3D.new()
    door_arches.name = "DoorArches"
    dressing.add_child(door_arches)
    _add_door_arches(door_arches, stone, bronze)

    var lanterns := Node3D.new()
    lanterns.name = "RitualLanterns"
    dressing.add_child(lanterns)
    _add_ritual_lanterns(lanterns)

    _add_ritual_spires(dressing, bronze)

func _add_pillar(parent: Node3D, position: Vector3, stone: Material, bronze: Material) -> void:
    var shaft := MeshInstance3D.new()
    shaft.position = position
    var shaft_mesh := CylinderMesh.new()
    shaft_mesh.top_radius = 0.24
    shaft_mesh.bottom_radius = 0.31
    shaft_mesh.height = 3.85
    shaft_mesh.radial_segments = 8
    shaft.mesh = shaft_mesh
    shaft.material_override = stone
    parent.add_child(shaft)

    for y in [-1.72, 1.72]:
        var collar := MeshInstance3D.new()
        collar.position = position + Vector3(0, y, 0)
        var collar_mesh := CylinderMesh.new()
        collar_mesh.top_radius = 0.38
        collar_mesh.bottom_radius = 0.38
        collar_mesh.height = 0.16
        collar_mesh.radial_segments = 8
        collar.mesh = collar_mesh
        collar.material_override = bronze
        parent.add_child(collar)

func _add_wall_rib(parent: Node3D, position: Vector3, size: Vector3, material: Material) -> void:
    var rib := MeshInstance3D.new()
    rib.position = position
    var mesh := BoxMesh.new()
    mesh.size = size
    rib.mesh = mesh
    rib.material_override = material
    parent.add_child(rib)

func _add_vault_ribs(parent: Node3D, stone: Material, bronze: Material) -> void:
    var crown := Vector3(0, 4.02, 0)
    for corner in [Vector3(-4.0, 3.35, -4.0), Vector3(4.0, 3.35, -4.0), Vector3(-4.0, 3.35, 4.0), Vector3(4.0, 3.35, 4.0)]:
        _add_beam_between(parent, corner, crown, stone, 0.16)
    _add_beam_between(parent, Vector3(-4.15, 3.72, 0), Vector3(4.15, 3.72, 0), stone, 0.12)
    _add_beam_between(parent, Vector3(0, 3.72, -4.15), Vector3(0, 3.72, 4.15), stone, 0.12)

    var crown_mark := MeshInstance3D.new()
    crown_mark.name = "VaultCrown"
    crown_mark.position = crown + Vector3(0, -0.08, 0)
    var crown_mesh := CylinderMesh.new()
    crown_mesh.top_radius = 0.38
    crown_mesh.bottom_radius = 0.38
    crown_mesh.height = 0.10
    crown_mesh.radial_segments = 12
    crown_mark.mesh = crown_mesh
    crown_mark.material_override = bronze
    parent.add_child(crown_mark)

func _add_door_arches(parent: Node3D, stone: Material, bronze: Material) -> void:
    _add_arch_on_z(parent, -4.74, stone, bronze)
    _add_arch_on_z(parent, 4.74, stone, bronze)
    _add_arch_on_x(parent, -4.74, stone, bronze)
    _add_arch_on_x(parent, 4.74, stone, bronze)

func _add_arch_on_z(parent: Node3D, z: float, stone: Material, bronze: Material) -> void:
    var left_low := Vector3(-1.35, 0.25, z)
    var left_high := Vector3(-1.35, 2.55, z)
    var right_low := Vector3(1.35, 0.25, z)
    var right_high := Vector3(1.35, 2.55, z)
    var apex := Vector3(0, 3.48, z)
    _add_beam_between(parent, left_low, left_high, stone, 0.15)
    _add_beam_between(parent, right_low, right_high, stone, 0.15)
    _add_beam_between(parent, left_high, apex, stone, 0.15)
    _add_beam_between(parent, right_high, apex, stone, 0.15)
    _add_arch_cap(parent, apex, bronze)

func _add_arch_on_x(parent: Node3D, x: float, stone: Material, bronze: Material) -> void:
    var left_low := Vector3(x, 0.25, -1.35)
    var left_high := Vector3(x, 2.55, -1.35)
    var right_low := Vector3(x, 0.25, 1.35)
    var right_high := Vector3(x, 2.55, 1.35)
    var apex := Vector3(x, 3.48, 0)
    _add_beam_between(parent, left_low, left_high, stone, 0.15)
    _add_beam_between(parent, right_low, right_high, stone, 0.15)
    _add_beam_between(parent, left_high, apex, stone, 0.15)
    _add_beam_between(parent, right_high, apex, stone, 0.15)
    _add_arch_cap(parent, apex, bronze)

func _add_arch_cap(parent: Node3D, position: Vector3, material: Material) -> void:
    var cap := MeshInstance3D.new()
    cap.position = position
    var mesh := SphereMesh.new()
    mesh.radius = 0.13
    mesh.height = 0.26
    cap.mesh = mesh
    cap.material_override = material
    parent.add_child(cap)

func _add_beam_between(parent: Node3D, start: Vector3, finish: Vector3, material: Material, thickness: float) -> void:
    var direction := finish - start
    var length := direction.length()
    if length <= 0.001:
        return
    var beam := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(thickness, thickness, length)
    beam.mesh = mesh
    beam.material_override = material
    parent.add_child(beam)
    beam.position = (start + finish) * 0.5
    beam.look_at(parent.to_global(finish), Vector3.UP)

func _add_ritual_lanterns(parent: Node3D) -> void:
    var flame_color := Color(1.0, 0.20, 0.045, 1.0)
    if room_role in [&"reward", &"sanctuary"]:
        flame_color = Color(0.92, 0.55, 0.16, 1.0)
    elif room_role == &"threshold":
        flame_color = Color(0.46, 0.12, 0.82, 1.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = flame_color.darkened(0.46)
    material.emission_enabled = true
    material.emission = flame_color
    material.emission_energy_multiplier = 1.6 if room_role == &"boss" else 1.0
    material.roughness = 0.35

    var points := [Vector3(-3.55, 2.3, 0), Vector3(3.55, 2.3, 0)]
    if room_role == &"boss":
        points.append(Vector3(0, 2.3, -3.55))
        points.append(Vector3(0, 2.3, 3.55))
    for point in points:
        var cage := MeshInstance3D.new()
        cage.position = point
        var cage_mesh := CylinderMesh.new()
        cage_mesh.top_radius = 0.11
        cage_mesh.bottom_radius = 0.16
        cage_mesh.height = 0.36
        cage_mesh.radial_segments = 8
        cage.mesh = cage_mesh
        cage.material_override = material
        parent.add_child(cage)

        var light := OmniLight3D.new()
        light.position = point
        light.light_color = flame_color
        light.light_energy = 0.72 if room_role == &"boss" else 0.42
        light.omni_range = 3.6
        light.omni_attenuation = 1.8
        light.shadow_enabled = false
        parent.add_child(light)

func _add_ritual_spires(parent: Node3D, bronze: Material) -> void:
    var points := [Vector3(-3.45, 0.62, 0), Vector3(3.45, 0.62, 0), Vector3(0, 0.62, -3.45), Vector3(0, 0.62, 3.45)]
    for point in points:
        var spire := MeshInstance3D.new()
        spire.position = point
        var cone := CylinderMesh.new()
        cone.top_radius = 0.02
        cone.bottom_radius = 0.16
        cone.height = 1.05
        cone.radial_segments = 8
        spire.mesh = cone
        spire.material_override = bronze
        parent.add_child(spire)

func _apply_role_lighting() -> void:
    var warm := get_node_or_null("WarmKeyLight") as OmniLight3D
    var violet := get_node_or_null("VioletRimLight") as OmniLight3D
    var floor_sigil := get_node_or_null("FloorSigil") as Node3D
    if warm == null or violet == null:
        return

    if room_role == &"boss":
        warm.light_energy = 1.95
        warm.omni_range = 8.4
        violet.light_energy = 1.18
        violet.omni_range = 7.2
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 1.18
    elif room_role in [&"elite", &"trial", &"archon"]:
        warm.light_energy = 1.65
        violet.light_energy = 0.88
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 1.07
    elif room_role in [&"reward", &"sanctuary"]:
        warm.light_energy = 1.12
        warm.light_color = Color(1.0, 0.56, 0.20, 1.0)
        violet.light_energy = 0.30
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 0.88
    elif room_role == &"threshold":
        warm.light_energy = 0.72
        violet.light_energy = 0.92
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 0.82
    else:
        warm.light_energy = 1.42
        violet.light_energy = 0.62
