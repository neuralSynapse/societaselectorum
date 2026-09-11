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

func mark_doorway_open(wall_name: String) -> void:
    var open_doorways: Array = get_meta("open_doorways", [])
    if wall_name not in open_doorways:
        open_doorways.append(wall_name)
        set_meta("open_doorways", open_doorways)
    if not is_node_ready():
        return
    var arches := get_node_or_null("GothicDressing/DoorArches") as Node3D
    if arches == null:
        return
    var wall_mesh := get_node_or_null(wall_name + "/Mesh") as MeshInstance3D
    var stone: Material = wall_mesh.material_override if wall_mesh != null else null
    var bronze := StandardMaterial3D.new()
    bronze.albedo_color = Color(0.24, 0.135, 0.045, 1.0)
    bronze.metallic = 0.76
    bronze.roughness = 0.35
    bronze.emission_enabled = true
    bronze.emission = Color(0.40, 0.12, 0.018, 1.0)
    bronze.emission_energy_multiplier = 0.65
    _add_door_arch_for_wall(arches, wall_name, stone, bronze)

func set_locked(value: bool) -> void:
    locked = value
    set_meta("locked", value)
    var open_doorways: Array = get_meta("open_doorways", [])
    var door_set := get_node_or_null("DoorSet")
    if door_set:
        for child in door_set.get_children():
            if child is StaticBody3D:
                var wall_name := _wall_name_for_door(String(child.name))
                var should_block := value and wall_name in open_doorways
                child.collision_layer = 2 if should_block else 0
                child.visible = should_block

func _wall_name_for_door(door_name: String) -> String:
    match door_name:
        "NorthDoor": return "NorthWall"
        "SouthDoor": return "SouthWall"
        "EastDoor": return "EastWall"
        "WestDoor": return "WestWall"
        _: return ""

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
    stone.albedo_color = Color(0.082, 0.064, 0.058, 1.0)
    stone.metallic = 0.08
    stone.roughness = 0.86

    var dark_stone := StandardMaterial3D.new()
    dark_stone.albedo_color = Color(0.032, 0.027, 0.031, 1.0)
    dark_stone.metallic = 0.04
    dark_stone.roughness = 0.92

    var bronze := StandardMaterial3D.new()
    bronze.albedo_color = Color(0.24, 0.135, 0.045, 1.0)
    bronze.metallic = 0.76
    bronze.roughness = 0.35
    bronze.emission_enabled = true
    bronze.emission = Color(0.16, 0.070, 0.014, 1.0)
    bronze.emission_energy_multiplier = 0.18

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

    var reliefs := Node3D.new()
    reliefs.name = "WallReliefs"
    dressing.add_child(reliefs)
    _add_wall_reliefs(reliefs, dark_stone, bronze)

    var statues := Node3D.new()
    statues.name = "BlindStatues"
    dressing.add_child(statues)
    _add_blind_statues(statues, stone, dark_stone, bronze)

    var debris := Node3D.new()
    debris.name = "RuinDebris"
    dressing.add_child(debris)
    _add_ruin_debris(debris, stone, dark_stone)

    var candles := Node3D.new()
    candles.name = "RitualCandles"
    dressing.add_child(candles)
    _add_ritual_candles(candles)

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
    var open_doorways: Array = get_meta("open_doorways", [])
    for wall_name in open_doorways:
        _add_door_arch_for_wall(parent, String(wall_name), stone, bronze)

func _add_door_arch_for_wall(parent: Node3D, wall_name: String, stone: Material, bronze: Material) -> void:
    var node_name := wall_name + "Arch"
    if parent.get_node_or_null(node_name) != null:
        return
    var arch := Node3D.new()
    arch.name = node_name
    parent.add_child(arch)
    match wall_name:
        "NorthWall": _add_arch_on_z(arch, -4.74, stone, bronze)
        "SouthWall": _add_arch_on_z(arch, 4.74, stone, bronze)
        "EastWall": _add_arch_on_x(arch, 4.74, stone, bronze)
        "WestWall": _add_arch_on_x(arch, -4.74, stone, bronze)
        _: return
    _add_doorway_beacon(arch, wall_name)

func _add_doorway_beacon(parent: Node3D, wall_name: String) -> void:
    var glow := StandardMaterial3D.new()
    glow.albedo_color = Color(0.42, 0.18, 0.035, 1.0)
    glow.emission_enabled = true
    glow.emission = Color(1.0, 0.28, 0.035, 1.0)
    glow.emission_energy_multiplier = 1.45
    glow.roughness = 0.32
    var marker := MeshInstance3D.new()
    marker.name = "PassageMarker"
    var mesh := BoxMesh.new()
    var light_position := Vector3.ZERO
    match wall_name:
        "NorthWall":
            mesh.size = Vector3(1.65, 0.035, 0.34)
            marker.position = Vector3(0, 0.13, -4.30)
            light_position = Vector3(0, 1.45, -4.18)
        "SouthWall":
            mesh.size = Vector3(1.65, 0.035, 0.34)
            marker.position = Vector3(0, 0.13, 4.30)
            light_position = Vector3(0, 1.45, 4.18)
        "EastWall":
            mesh.size = Vector3(0.34, 0.035, 1.65)
            marker.position = Vector3(4.30, 0.13, 0)
            light_position = Vector3(4.18, 1.45, 0)
        "WestWall":
            mesh.size = Vector3(0.34, 0.035, 1.65)
            marker.position = Vector3(-4.30, 0.13, 0)
            light_position = Vector3(-4.18, 1.45, 0)
        _:
            return
    marker.mesh = mesh
    marker.material_override = glow
    parent.add_child(marker)
    var light := OmniLight3D.new()
    light.name = "PassageLight"
    light.position = light_position
    light.light_color = Color(1.0, 0.30, 0.055, 1.0)
    light.light_energy = 0.82
    light.omni_range = 3.2
    light.omni_attenuation = 1.45
    light.shadow_enabled = false
    parent.add_child(light)

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
    var direction_normalized := direction / length
    var safe_up := Vector3.UP
    if absf(direction_normalized.dot(Vector3.UP)) > 0.98:
        safe_up = Vector3.FORWARD
    var beam := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(thickness, thickness, length)
    beam.mesh = mesh
    beam.material_override = material
    parent.add_child(beam)
    beam.position = (start + finish) * 0.5
    beam.look_at(parent.to_global(finish), safe_up)

func _add_wall_reliefs(parent: Node3D, dark_stone: Material, bronze: Material) -> void:
    var panels := [
        {"position": Vector3(-2.95, 1.8, -4.66), "rotation": Vector3.ZERO},
        {"position": Vector3(2.95, 1.8, -4.66), "rotation": Vector3.ZERO},
        {"position": Vector3(-2.95, 1.8, 4.66), "rotation": Vector3.ZERO},
        {"position": Vector3(2.95, 1.8, 4.66), "rotation": Vector3.ZERO},
        {"position": Vector3(-4.66, 1.8, -2.95), "rotation": Vector3(0, PI * 0.5, 0)},
        {"position": Vector3(4.66, 1.8, 2.95), "rotation": Vector3(0, PI * 0.5, 0)}
    ]
    for spec in panels:
        var relief := Node3D.new()
        relief.position = spec["position"]
        relief.rotation = spec["rotation"]
        parent.add_child(relief)

        var slab := MeshInstance3D.new()
        var slab_mesh := BoxMesh.new()
        slab_mesh.size = Vector3(1.05, 1.65, 0.075)
        slab.mesh = slab_mesh
        slab.material_override = dark_stone
        relief.add_child(slab)

        var halo := MeshInstance3D.new()
        halo.position = Vector3(0, 0.24, -0.065)
        var halo_mesh := TorusMesh.new()
        halo_mesh.inner_radius = 0.24
        halo_mesh.outer_radius = 0.285
        halo_mesh.rings = 20
        halo_mesh.ring_segments = 6
        halo.mesh = halo_mesh
        halo.material_override = bronze
        relief.add_child(halo)

        _add_wall_rib(relief, Vector3(0, -0.20, -0.065), Vector3(0.055, 0.75, 0.045), bronze)
        _add_wall_rib(relief, Vector3(0, -0.20, -0.065), Vector3(0.52, 0.055, 0.045), bronze)

func _add_blind_statues(parent: Node3D, stone: Material, dark_stone: Material, bronze: Material) -> void:
    var positions := [Vector3(-3.55, 0, -3.1), Vector3(3.55, 0, 3.1)]
    if room_role == &"boss":
        positions.append(Vector3(3.55, 0, -3.1))
        positions.append(Vector3(-3.55, 0, 3.1))
    for index in range(positions.size()):
        var statue := Node3D.new()
        statue.name = "BlindWitness_%d" % index
        statue.position = positions[index]
        statue.rotation.y = (-0.55 if positions[index].x < 0.0 else 2.58)
        parent.add_child(statue)

        var robe := MeshInstance3D.new()
        robe.position = Vector3(0, 0.78, 0)
        var robe_mesh := CylinderMesh.new()
        robe_mesh.top_radius = 0.20
        robe_mesh.bottom_radius = 0.42
        robe_mesh.height = 1.48
        robe_mesh.radial_segments = 8
        robe.mesh = robe_mesh
        robe.material_override = stone
        statue.add_child(robe)

        var shoulders := MeshInstance3D.new()
        shoulders.position = Vector3(0, 1.44, 0)
        var shoulder_mesh := BoxMesh.new()
        shoulder_mesh.size = Vector3(0.72, 0.17, 0.30)
        shoulders.mesh = shoulder_mesh
        shoulders.material_override = dark_stone
        statue.add_child(shoulders)

        var head := MeshInstance3D.new()
        head.position = Vector3(0, 1.72, -0.015)
        var head_mesh := SphereMesh.new()
        head_mesh.radius = 0.22
        head_mesh.height = 0.43
        head.mesh = head_mesh
        head.material_override = stone
        statue.add_child(head)

        var blindfold := MeshInstance3D.new()
        blindfold.position = Vector3(0, 1.75, -0.20)
        var blindfold_mesh := BoxMesh.new()
        blindfold_mesh.size = Vector3(0.46, 0.095, 0.075)
        blindfold.mesh = blindfold_mesh
        blindfold.material_override = bronze
        statue.add_child(blindfold)

func _add_ruin_debris(parent: Node3D, stone: Material, dark_stone: Material) -> void:
    var fragments := [
        [Vector3(-4.08, 0.16, -2.65), Vector3(0.58, 0.24, 0.34), 0.22],
        [Vector3(-3.72, 0.10, 2.82), Vector3(0.36, 0.16, 0.62), -0.48],
        [Vector3(4.10, 0.13, -2.55), Vector3(0.50, 0.20, 0.28), 0.70],
        [Vector3(3.76, 0.17, 2.62), Vector3(0.28, 0.26, 0.74), -0.32],
        [Vector3(-2.80, 0.11, -4.05), Vector3(0.72, 0.17, 0.31), 0.42],
        [Vector3(2.70, 0.13, -4.10), Vector3(0.40, 0.21, 0.65), -0.58],
        [Vector3(-2.60, 0.12, 4.06), Vector3(0.55, 0.19, 0.34), 0.66],
        [Vector3(2.85, 0.10, 4.10), Vector3(0.68, 0.15, 0.27), -0.18],
        [Vector3(-4.00, 0.24, 0.92), Vector3(0.32, 0.42, 0.31), 0.35],
        [Vector3(4.04, 0.22, -0.88), Vector3(0.30, 0.38, 0.34), -0.40]
    ]
    for index in range(fragments.size()):
        var fragment := MeshInstance3D.new()
        fragment.name = "Rubble_%02d" % index
        fragment.position = fragments[index][0]
        fragment.rotation = Vector3(0.10 * (index % 3), fragments[index][2], 0.08 * ((index + 1) % 2))
        var mesh := BoxMesh.new()
        mesh.size = fragments[index][1]
        fragment.mesh = mesh
        fragment.material_override = stone if index % 2 == 0 else dark_stone
        parent.add_child(fragment)

func _add_ritual_candles(parent: Node3D) -> void:
    var wax := StandardMaterial3D.new()
    wax.albedo_color = Color(0.44, 0.34, 0.24, 1.0)
    wax.roughness = 0.92

    var flame := StandardMaterial3D.new()
    flame.albedo_color = Color(0.94, 0.48, 0.12, 1.0)
    flame.emission_enabled = true
    flame.emission = Color(1.0, 0.32, 0.055, 1.0)
    flame.emission_energy_multiplier = 1.35
    flame.roughness = 0.35

    var points := [
        Vector3(-3.25, 0, -3.85), Vector3(-2.92, 0, -3.93),
        Vector3(3.18, 0, 3.86), Vector3(2.88, 0, 3.92),
        Vector3(-3.88, 0, 3.12), Vector3(3.87, 0, -3.06)
    ]
    if room_role == &"boss":
        points.append(Vector3(-1.20, 0, -3.82))
        points.append(Vector3(1.20, 0, -3.82))
    for index in range(points.size()):
        var candle := MeshInstance3D.new()
        candle.name = "Candle_%02d" % index
        candle.position = points[index] + Vector3(0, 0.14 + 0.025 * (index % 3), 0)
        var candle_mesh := CylinderMesh.new()
        candle_mesh.top_radius = 0.035
        candle_mesh.bottom_radius = 0.045
        candle_mesh.height = 0.26 + 0.05 * (index % 3)
        candle_mesh.radial_segments = 7
        candle.mesh = candle_mesh
        candle.material_override = wax
        parent.add_child(candle)

        var flame_mesh_instance := MeshInstance3D.new()
        flame_mesh_instance.position = points[index] + Vector3(0, 0.31 + 0.05 * (index % 3), 0)
        var flame_mesh := SphereMesh.new()
        flame_mesh.radius = 0.035
        flame_mesh.height = 0.09
        flame_mesh.radial_segments = 8
        flame_mesh.rings = 4
        flame_mesh_instance.mesh = flame_mesh
        flame_mesh_instance.material_override = flame
        parent.add_child(flame_mesh_instance)

func _add_ritual_lanterns(parent: Node3D) -> void:
    var flame_color := Color(1.0, 0.34, 0.08, 1.0)
    if room_role in [&"reward", &"sanctuary"]:
        flame_color = Color(0.92, 0.55, 0.16, 1.0)
    elif room_role == &"threshold":
        flame_color = Color(0.36, 0.12, 0.62, 1.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = flame_color.darkened(0.50)
    material.emission_enabled = true
    material.emission = flame_color
    material.emission_energy_multiplier = 1.10 if room_role == &"boss" else 0.78
    material.roughness = 0.42

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
        light.light_energy = 0.64 if room_role == &"boss" else 0.38
        light.omni_range = 4.1
        light.omni_attenuation = 1.7
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
        warm.light_energy = 1.72
        warm.omni_range = 8.8
        warm.light_color = Color(1.0, 0.40, 0.10, 1.0)
        violet.light_energy = 0.82
        violet.omni_range = 7.6
        violet.light_color = Color(0.32, 0.10, 0.58, 1.0)
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 1.18
    elif room_role in [&"elite", &"trial", &"archon"]:
        warm.light_energy = 1.45
        warm.light_color = Color(1.0, 0.43, 0.12, 1.0)
        violet.light_energy = 0.66
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 1.07
    elif room_role in [&"reward", &"sanctuary"]:
        warm.light_energy = 1.16
        warm.light_color = Color(1.0, 0.56, 0.20, 1.0)
        violet.light_energy = 0.26
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 0.88
    elif room_role == &"threshold":
        warm.light_energy = 0.78
        violet.light_energy = 0.66
        violet.light_color = Color(0.30, 0.10, 0.56, 1.0)
        if floor_sigil: floor_sigil.scale = Vector3.ONE * 0.82
    else:
        warm.light_energy = 1.24
        warm.light_color = Color(1.0, 0.41, 0.11, 1.0)
        violet.light_energy = 0.46
        violet.light_color = Color(0.30, 0.09, 0.54, 1.0)
