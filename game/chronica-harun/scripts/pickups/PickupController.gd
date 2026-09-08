extends Area3D
class_name PickupController

signal collected(category: StringName, content_id: StringName, actor: Node)

@export var category: StringName = &"tarot"
@export var content_id: StringName = &""
@export var display_name := "Recompensa"
@export var effect_summary := ""
var consumed := false
var base_y := 0.0
var clock := 0.0

func _ready() -> void:
    base_y = position.y
    add_to_group("pickups")

func _process(delta: float) -> void:
    clock += delta
    rotation.y += delta * 0.55
    position.y = base_y + sin(clock * 2.0) * 0.06

func interact(actor: Node) -> bool:
    if consumed:
        return false
    if not RogueliteContentService.grant(String(category), content_id):
        return false
    consumed = true
    VFXDirector.emit_feedback(&"pickup", global_position, Vector3.UP, {"category":String(category), "content_id":String(content_id)})
    AudioDirector.play_3d(&"pickup", global_position)
    collected.emit(category, content_id, actor)
    visible = false
    monitoring = false
    queue_free()
    return true
