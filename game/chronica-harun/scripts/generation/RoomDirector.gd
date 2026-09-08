extends Node
class_name RoomDirector

signal room_entered(room_id: StringName)
signal room_locked(room_id: StringName)
signal room_cleared(room_id: StringName)
signal secret_opened(room_id: StringName)

var active_room: StringName = &""
var rooms: Dictionary = {}
var enemies_by_room: Dictionary = {}
var secret_state: Dictionary = {}

func register_room(room: RoomShell) -> void:
    rooms[room.room_id] = room
    if not room.player_entered.is_connected(activate_room):
        room.player_entered.connect(activate_room)

func register_enemy(room_id: StringName, enemy: Node) -> void:
    if not enemies_by_room.has(room_id):
        enemies_by_room[room_id] = []
    enemies_by_room[room_id].append(enemy)
    if enemy.has_signal("died"):
        enemy.died.connect(func(_source_id = &""): _on_enemy_died(room_id, enemy))

func activate_room(room_id: StringName) -> void:
    active_room = room_id
    room_entered.emit(room_id)
    var room := rooms.get(room_id) as RoomShell
    if room and String(room.room_role) in ["combat", "elite", "boss", "trial", "archon"]:
        lock_room(room_id)

func lock_room(room_id: StringName) -> void:
    var room := rooms.get(room_id) as RoomShell
    if room:
        room.set_locked(true)
    room_locked.emit(room_id)

func clear_room(room_id: StringName) -> void:
    var room := rooms.get(room_id) as RoomShell
    if room:
        room.mark_cleared()
    room_cleared.emit(room_id)

func open_secret(room_id: StringName, damage_kind: StringName = &"rupture_charge") -> bool:
    if damage_kind != &"rupture_charge" or secret_state.get(room_id, false):
        return false
    var room := rooms.get(room_id) as RoomShell
    if room == null:
        return false
    if bool(room.get_meta("secret_connection_pending", false)) and not StageFloorBuilder.open_secret_connection(room):
        return false
    secret_state[room_id] = true
    room.visible = true
    room.process_mode = Node.PROCESS_MODE_INHERIT
    room.set_locked(false)
    secret_opened.emit(room_id)
    return true

func _on_enemy_died(room_id: StringName, enemy: Node) -> void:
    if not enemies_by_room.has(room_id):
        return
    enemies_by_room[room_id].erase(enemy)
    if enemies_by_room[room_id].is_empty():
        clear_room(room_id)
