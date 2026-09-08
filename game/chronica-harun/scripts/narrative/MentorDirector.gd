extends Node
class_name MentorDirector

signal mentor_started(entry: Dictionary)
signal mentor_objective_completed(stage_id: StringName, index: int)
signal mentor_mission_completed(stage_id: StringName, reward_hook: StringName)

const DATA_PATH := "res://data/narrative/stage_mentors.json"
var mentors: Array = []
var active: Dictionary = {}
var progress: Array[int] = []

func _ready() -> void:
    mentors = _load_array(DATA_PATH)

func begin_stage_mentor(stage_id: StringName) -> Dictionary:
    if mentors.is_empty(): mentors = _load_array(DATA_PATH)
    for row in mentors:
        if String(row.get("stage_id", "")) == String(stage_id):
            active = row
            progress.clear()
            mentor_started.emit(row)
            return row
    return {}

func complete_mentor_objective(index: int) -> bool:
    if active.is_empty(): return false
    var objectives: Array = active.get("mission", {}).get("objectives", [])
    if index < 0 or index >= objectives.size(): return false
    if not progress.has(index): progress.append(index)
    mentor_objective_completed.emit(StringName(active.get("stage_id", "")), index)
    return true

func complete_mentor_mission() -> bool:
    if active.is_empty(): return false
    var objectives: Array = active.get("mission", {}).get("objectives", [])
    if progress.size() < objectives.size(): return false
    var stage_id := String(active.get("stage_id", ""))
    var state: Dictionary = GameState.meta_progression.get("mentor_missions", {})
    state[stage_id] = {"completed": true, "mentor_id": active.get("mentor_id"), "reward_hook": active.get("reward_hook")}
    GameState.meta_progression["mentor_missions"] = state
    mentor_mission_completed.emit(StringName(stage_id), StringName(active.get("reward_hook", "")))
    active = {}
    progress.clear()
    return true

func _load_array(path: String) -> Array:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return []
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Array else []
