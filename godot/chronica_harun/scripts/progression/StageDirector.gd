class_name StageDirector
extends RefCounted

const JOURNEY_PATH := "res://data/stages/student_journey.json"

var entries: Array = []

func _init() -> void:
    reload_journey()

func reload_journey() -> bool:
    if not FileAccess.file_exists(JOURNEY_PATH):
        entries = []
        return false
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(JOURNEY_PATH))
    if typeof(parsed) != TYPE_DICTIONARY:
        entries = []
        return false
    entries = parsed.get("entries", [])
    return entries.size() == 16

func stage_at(index: int) -> Dictionary:
    if index < 0 or index >= entries.size():
        return {}
    return entries[index]

func next_stage_index(current_index: int) -> int:
    return clampi(current_index + 1, 0, 15)

func is_initiation(index: int) -> bool:
    return index == 15
