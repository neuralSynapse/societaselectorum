extends Area3D
class_name InitialWeaponPickup

signal collected(actor: Node)

@export var display_name := "Lâmina de Viagem"

var revealed := false
var consumed := false
var base_y := 0.0
var clock := 0.0

func _ready() -> void:
    base_y = position.y
    visible = false
    monitoring = false
    add_to_group("initial_weapon_pickup")

func _process(delta: float) -> void:
    if not revealed or consumed:
        return
    clock += delta
    rotation.y += delta * 0.42
    position.y = base_y + sin(clock * 1.8) * 0.045

func reveal() -> void:
    if consumed:
        return
    revealed = true
    visible = true
    monitoring = true

func is_revealed() -> bool:
    return revealed and not consumed

func interact(actor: Node) -> bool:
    if consumed or not revealed or actor == null or not actor.has_method("equip_initial_weapon"):
        return false
    consumed = true
    actor.call("equip_initial_weapon")
    collected.emit(actor)
    AudioDirector.play_ui(&"pickup")
    visible = false
    monitoring = false
    queue_free()
    return true
