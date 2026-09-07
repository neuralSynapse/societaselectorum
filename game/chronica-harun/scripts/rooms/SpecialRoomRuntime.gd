extends Node
class_name SpecialRoomRuntime

signal room_resolved(room_id: StringName, result: Dictionary)
signal room_denied(room_id: StringName, reason: String)

var effect_bus: GameplayEffectBus
var visited: Dictionary = {}

func _ready() -> void:
    effect_bus = GameplayEffectBus.new()
    add_child(effect_bus)

func resolve_room(room_id: StringName, context: Dictionary = {}) -> Dictionary:
    var definition := ContentRegistry.get_item("special_rooms", room_id)
    if definition.is_empty():
        room_denied.emit(room_id, "unknown_room")
        return {}
    if String(definition.get("exclusive_group", "")) == "postboss_path":
        var chosen := String(GameState.route_state.get("post_boss_choice", ""))
        if not chosen.is_empty() and chosen != String(room_id):
            room_denied.emit(room_id, "postboss_path_already_chosen")
            return {}
        GameState.route_state["post_boss_choice"] = String(room_id)
    var effect: Dictionary = definition.get("effect", {}).duplicate(true)
    var payload := effect_bus.dispatch(effect, context)
    if payload.is_empty():
        room_denied.emit(room_id, "effect_rejected")
        return {}
    var result := {
        "room_id":String(room_id),
        "reward_pool":definition.get("reward_pool", []),
        "cost":definition.get("cost", {}),
        "risk":definition.get("risk", "medium"),
        "effect":payload
    }
    visited[String(room_id)] = int(visited.get(String(room_id),0)) + 1
    GameState.run_stats["special_rooms_resolved"] = GameState.run_stats.get("special_rooms_resolved", [])
    if String(room_id) not in GameState.run_stats["special_rooms_resolved"]:
        GameState.run_stats["special_rooms_resolved"].append(String(room_id))
    room_resolved.emit(room_id, result)
    return result
