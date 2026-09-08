extends Node
class_name TemporalRiftDirector

signal rift_opened(rift: Dictionary)
signal objective_completed(rift_id: StringName, objective_index: int)
signal rift_returned(rift_id: StringName, completed: bool)

const DATA_PATH := "res://data/narrative/temporal_rifts.json"
var rifts: Array = []
var active_rift_id: StringName = &""
var completed_objectives: Array[int] = []

func _ready() -> void:
    rifts = _load_array(DATA_PATH)

func open_rift(rift_id: StringName, context: Dictionary = {}) -> bool:
    if rifts.is_empty(): rifts = _load_array(DATA_PATH)
    var row := _find(rift_id)
    if row.is_empty() or not _requirements_met(row.get("ritual", {}).get("requirements", []), context): return false
    active_rift_id = rift_id
    completed_objectives.clear()
    var state := _state()
    state["active"] = String(rift_id)
    GameState.meta_progression["temporal_rifts"] = state
    rift_opened.emit(row)
    return true

func complete_objective(objective_index: int) -> bool:
    if active_rift_id == &"": return false
    var row := _find(active_rift_id)
    var objectives: Array = row.get("mission", {}).get("objectives", [])
    if objective_index < 0 or objective_index >= objectives.size(): return false
    if not completed_objectives.has(objective_index): completed_objectives.append(objective_index)
    objective_completed.emit(active_rift_id, objective_index)
    return true

func return_from_rift(force_retreat := false) -> bool:
    if active_rift_id == &"": return false
    var row := _find(active_rift_id)
    var total: int = row.get("mission", {}).get("objectives", []).size()
    var completed: bool = completed_objectives.size() >= total and not force_retreat
    var state := _state()
    var visited: Array = state.get("visited", [])
    if not visited.has(String(active_rift_id)): visited.append(String(active_rift_id))
    if completed:
        var cleared: Array = state.get("cleared", [])
        if not cleared.has(String(active_rift_id)): cleared.append(String(active_rift_id))
        state["cleared"] = cleared
    state["visited"] = visited
    state["active"] = ""
    GameState.meta_progression["temporal_rifts"] = state
    var id := active_rift_id
    active_rift_id = &""
    completed_objectives.clear()
    rift_returned.emit(id, completed)
    return true

func _requirements_met(requirements: Array, context: Dictionary) -> bool:
    for requirement in requirements:
        var token := String(requirement)
        if ":" not in token:
            if not bool(context.get(token, GameState.meta_progression.get(token, false))): return false
            continue
        var parts := token.split(":", false, 1)
        var key := parts[0]
        var value := parts[1]
        match key:
            "stage":
                if String(GameState.current_stage_id) != value: return false
            "focus":
                if float(context.get("focus", 0.0)) < float(value): return false
            "grimorium_fragment":
                if int(GameState.meta_progression.get("grimorium_fragments", 0)) < int(value): return false
            "story":
                if not bool(GameState.meta_progression.get("story_%s" % value, false)): return false
            "quantum_observation":
                if int(GameState.meta_progression.get("quantum_observations", 0)) < int(value): return false
            _:
                if String(context.get(key, GameState.meta_progression.get(key, ""))) != value: return false
    return true

func _find(id: StringName) -> Dictionary:
    for row in rifts:
        if String(row.get("id", "")) == String(id): return row
    return {}

func _state() -> Dictionary:
    return GameState.meta_progression.get("temporal_rifts", {"visited": [], "cleared": [], "active": ""}).duplicate(true)

func _load_array(path: String) -> Array:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return []
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Array else []
