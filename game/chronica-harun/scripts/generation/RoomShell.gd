extends Node3D
class_name RoomShell

signal player_entered(room_id: StringName)

@export var room_id: StringName = &"room"
@export var room_role: StringName = &"combat"
var locked := false
var cleared := false

func _ready() -> void:
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

func set_portal_gate_locked(door_name: StringName, value: bool) -> void:
    locked = value
    set_meta("locked", value)
    var door := get_node_or_null("DoorSet/%s" % String(door_name)) as StaticBody3D
    if door:
        door.collision_layer = 2 if value else 0
        door.visible = value

func mark_cleared() -> void:
    cleared = true
    set_locked(false)
