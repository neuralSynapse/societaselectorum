extends RefCounted
class_name StageFloorBuilder

const ROOM_SCENE := preload("res://scenes/rooms/RoomShell.tscn")
const ROOM_DIRECTOR_SCRIPT := preload("res://scripts/generation/RoomDirector.gd")

const BASE_LAYOUT := [
    {"id":"threshold","role":"threshold","pos":Vector3(0,0,0)},
    {"id":"combat_1","role":"combat","pos":Vector3(14,0,0)},
    {"id":"reward_1","role":"reward","pos":Vector3(28,0,0)},
    {"id":"combat_2","role":"combat","pos":Vector3(28,0,14)},
    {"id":"sanctuary","role":"sanctuary","pos":Vector3(14,0,14)},
    {"id":"combat_3","role":"combat","pos":Vector3(0,0,14)},
    {"id":"boss","role":"boss","pos":Vector3(0,0,28)}
]

static func build(stage_data: Dictionary, seed: int, cycle: int, context: Dictionary = {}) -> Node3D:
    var root := Node3D.new()
    root.name = "StageFloor_%s" % stage_data.get("id", "stage")
    root.set_meta("stage_id", String(stage_data.get("id", "")))
    root.set_meta("seed", seed)
    root.set_meta("cycle", cycle)
    var room_director := RoomDirector.new()
    room_director.name = "RoomDirector"
    root.add_child(room_director)
    var rooms := Node3D.new()
    rooms.name = "Rooms"
    root.add_child(rooms)
    var corridors := Node3D.new()
    corridors.name = "Corridors"
    root.add_child(corridors)
    var theme := _theme(StringName(stage_data.get("id", "o_olho")))
    var layout: Array = BASE_LAYOUT.duplicate(true)
    if cycle >= 2:
        layout.insert(5, {"id":"trial","role":"elite","pos":Vector3(14,0,28)})
    if cycle >= 6:
        layout.insert(layout.size() - 1, {"id":"combat_4","role":"combat","pos":Vector3(-14,0,14)})
    var by_id: Dictionary = {}
    for row in layout:
        var room := _spawn_room(rooms, String(row.id), String(row.role), row.pos, theme)
        by_id[String(row.id)] = room
    _connect_base_layout(by_id, corridors, theme)

    var special_director := SpecialRoomDirector.new()
    var special_context := context.duplicate(true)
    special_context["stage_id"] = stage_data.get("id", "")
    var selected := special_director.roll_floor_rooms(int(stage_data.get("index", 0)), cycle, special_context, seed)
    var special_ids: Array[String] = []
    for index in range(selected.size()):
        var definition: Dictionary = selected[index]
        var room := spawn_special_room(rooms, definition, index, by_id, corridors, theme)
        if room:
            special_ids.append(String(definition.id))
    root.set_meta("special_room_ids", special_ids)
    root.set_meta("theme", theme)
    return root

static func spawn_special_room(rooms: Node3D, definition: Dictionary, index: int, by_id: Dictionary = {}, corridors: Node3D = null, theme: Dictionary = {}) -> RoomShell:
    var room: RoomShell = ROOM_SCENE.instantiate()
    var id := String(definition.get("id", "special"))
    room.name = "special_%s" % id
    room.room_id = StringName(id)
    room.room_role = &"special"
    var attachment_ids := ["combat_1", "reward_1", "combat_2", "sanctuary", "combat_3", "threshold"]
    var host_id: String = String(attachment_ids[index % attachment_ids.size()])
    var host := by_id.get(host_id) as RoomShell
    if host:
        var side := -1.0 if index % 2 == 0 else 1.0
        room.position = host.position + Vector3(0, 0, side * 14.0)
    else:
        room.position = Vector3(14 + (index / 2) * 14, 0, (-1 if index % 2 == 0 else 1) * 42)
    room.set_meta("special_definition", definition.duplicate(true))
    room.set_meta("access", definition.get("access", "door_after_clear"))
    room.set_meta("telegraph", definition.get("telegraph", ""))
    room.set_meta("risk", definition.get("risk", "low"))
    rooms.add_child(room)
    _apply_theme(room, theme)
    if id in ["secret", "super_secret"]:
        room.visible = false
        room.process_mode = Node.PROCESS_MODE_DISABLED
    if host and corridors:
        if room.position.z < host.position.z:
            _open_pair(host, "NorthWall", room, "SouthWall")
        else:
            _open_pair(host, "SouthWall", room, "NorthWall")
        _add_corridor(corridors, host.position, room.position, theme)
    return room

static func _spawn_room(parent: Node3D, id: String, role: String, pos: Vector3, theme: Dictionary) -> RoomShell:
    var room: RoomShell = ROOM_SCENE.instantiate()
    room.name = id
    room.room_id = StringName(id)
    room.room_role = StringName(role)
    room.position = pos
    parent.add_child(room)
    _apply_theme(room, theme)
    return room

static func _connect_base_layout(by_id: Dictionary, corridors: Node3D, theme: Dictionary) -> void:
    _connect(by_id, corridors, "threshold", "combat_1", "EastWall", "WestWall", theme)
    _connect(by_id, corridors, "combat_1", "reward_1", "EastWall", "WestWall", theme)
    _connect(by_id, corridors, "reward_1", "combat_2", "SouthWall", "NorthWall", theme)
    _connect(by_id, corridors, "combat_2", "sanctuary", "WestWall", "EastWall", theme)
    _connect(by_id, corridors, "sanctuary", "combat_3", "WestWall", "EastWall", theme)
    _connect(by_id, corridors, "combat_3", "boss", "SouthWall", "NorthWall", theme)
    if by_id.has("trial"):
        _connect(by_id, corridors, "sanctuary", "trial", "SouthWall", "NorthWall", theme)
    if by_id.has("combat_4"):
        _connect(by_id, corridors, "combat_3", "combat_4", "WestWall", "EastWall", theme)

static func _connect(by_id: Dictionary, corridors: Node3D, a_id: String, b_id: String, a_wall: String, b_wall: String, theme: Dictionary) -> void:
    var a := by_id.get(a_id) as RoomShell
    var b := by_id.get(b_id) as RoomShell
    if a == null or b == null:
        return
    _open_pair(a, a_wall, b, b_wall)
    _add_corridor(corridors, a.position, b.position, theme)

static func _open_pair(a: RoomShell, wall_a: String, b: RoomShell, wall_b: String) -> void:
    _disable_wall(a, wall_a)
    _disable_wall(b, wall_b)

static func _disable_wall(room: RoomShell, wall_name: String) -> void:
    var wall := room.get_node_or_null(wall_name)
    if wall:
        wall.visible = false
        wall.process_mode = Node.PROCESS_MODE_DISABLED

static func _add_corridor(parent: Node3D, a: Vector3, b: Vector3, theme: Dictionary) -> void:
    var mid := (a + b) * 0.5
    var delta := b - a
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "Corridor_%d" % parent.get_child_count()
    var mesh := BoxMesh.new()
    if absf(delta.x) > absf(delta.z):
        mesh.size = Vector3(maxf(2.0, absf(delta.x) - 9.7), 0.14, 2.4)
    else:
        mesh.size = Vector3(2.4, 0.14, maxf(2.0, absf(delta.z) - 9.7))
    mesh_instance.mesh = mesh
    mesh_instance.position = mid + Vector3(0, -0.02, 0)
    mesh_instance.material_override = _material(String(theme.get("palette", ["#0c0b0a"])[0]), 0.95)
    parent.add_child(mesh_instance)

static func _theme(stage_id: StringName) -> Dictionary:
    var file := FileAccess.open("res://data/rooms/student_room_themes.json", FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Array:
        for row in parsed:
            if String(row.get("stage_id", "")) == String(stage_id):
                return row
    return {}

static func _apply_theme(room: RoomShell, theme: Dictionary) -> void:
    var palette: Array = theme.get("palette", ["#0b0a09", "#1c1814", "#4b4033", "#8e7148"])
    var floor_material := _material(String(palette[0]), 0.96)
    var wall_material := _material(String(palette[1]), 0.91)
    var ceiling_material := _material(String(palette[0]), 1.0)
    var floor_mesh := room.get_node_or_null("Floor/Mesh") as MeshInstance3D
    if floor_mesh: floor_mesh.material_override = floor_material
    var ceiling := room.get_node_or_null("Ceiling") as MeshInstance3D
    if ceiling: ceiling.material_override = ceiling_material
    for wall_name in ["NorthWall", "SouthWall", "EastWall", "WestWall"]:
        var wall_mesh := room.get_node_or_null(wall_name + "/Mesh") as MeshInstance3D
        if wall_mesh: wall_mesh.material_override = wall_material

static func _material(hex: String, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color.from_string(hex, Color(0.08, 0.07, 0.06))
    material.roughness = roughness
    material.metallic = 0.03
    material.emission_enabled = false
    return material
