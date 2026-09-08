extends Node
class_name EdenMortisDirector

signal entry_granted(room_id: StringName, visit_index: int)
signal fruit_chosen(fruit_id: StringName, effect: Dictionary)
signal entry_denied(room_id: StringName, reason: String)

const DATA_PATH := "res://data/world/eden_mortis.json"
var data: Dictionary = {}

func _ready() -> void:
    data = _load_json(DATA_PATH)

func request_entry(room_id: StringName, resources: Dictionary = {}) -> bool:
    if data.is_empty(): data = _load_json(DATA_PATH)
    var room: Dictionary = _room(room_id)
    if room.is_empty():
        entry_denied.emit(room_id, "unknown_room")
        return false
    var state := _state()
    var visits: Dictionary = state.get("visits", {})
    var count := int(visits.get(String(room_id), 0))
    if count == 0 and bool(room.get("first_entry_free", false)):
        pass
    else:
        var cost: Dictionary = room.get("repeat_entry_cost", {})
        var resource := String(cost.get("resource", ""))
        var amount := int(cost.get("amount", 0))
        if amount > 0:
            var available := int(resources.get(resource, state.get(resource, 0)))
            if available < amount:
                entry_denied.emit(room_id, "missing_%s" % resource)
                return false
            if resources.has(resource): resources[resource] = available - amount
            else: state[resource] = available - amount
    visits[String(room_id)] = count + 1
    state["visits"] = visits
    GameState.meta_progression["eden_mortis"] = state
    entry_granted.emit(room_id, count + 1)
    return true

func available_fruits(room_id: StringName) -> Array:
    if data.is_empty(): data = _load_json(DATA_PATH)
    var room: Dictionary = _room(room_id)
    var tree := String(room.get("tree", ""))
    var out: Array = []
    for fruit in data.get("fruits", []):
        if String(fruit.get("tree", "")) == tree:
            out.append(fruit)
    return out

func choose_fruit(fruit_id: StringName) -> Dictionary:
    if data.is_empty(): data = _load_json(DATA_PATH)
    for fruit in data.get("fruits", []):
        if String(fruit.get("id", "")) != String(fruit_id): continue
        var state := _state()
        var chosen: Array = state.get("chosen_fruits", [])
        if chosen.has(String(fruit_id)): return {}
        chosen.append(String(fruit_id))
        state["chosen_fruits"] = chosen
        GameState.meta_progression["eden_mortis"] = state
        var build_fruits: Array = GameState.run_build.get("eden_mortis_fruits", [])
        build_fruits.append(String(fruit_id))
        GameState.run_build["eden_mortis_fruits"] = build_fruits
        var effect: Dictionary = fruit.get("effect", {}).duplicate(true)
        fruit_chosen.emit(fruit_id, effect)
        return effect
    return {}

func _room(room_id: StringName) -> Dictionary:
    if String(room_id) == String(data.get("eden", {}).get("id", "")): return data.get("eden", {})
    if String(room_id) == String(data.get("arbor_mortis", {}).get("id", "")): return data.get("arbor_mortis", {})
    return {}

func _state() -> Dictionary:
    return GameState.meta_progression.get("eden_mortis", {"visits": {}, "chosen_fruits": [], "eden_key": 0, "mortis_key": 0}).duplicate(true)

func _load_json(path: String) -> Dictionary:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return {}
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Dictionary else {}
