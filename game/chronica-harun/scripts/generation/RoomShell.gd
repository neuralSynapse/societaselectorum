extends Node3D
class_name RoomShell

signal player_entered(room_id: StringName)

@export var room_id: StringName = &"room"
@export var room_role: StringName = &"combat"
var locked := false
var cleared := false

func _ready() -> void:
    _build_gothic_dressing()
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
