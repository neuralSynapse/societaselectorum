extends Node
class_name CharacterSanctumDirector

signal character_selected(character_id: StringName, profile: Dictionary)

const DATA_PATH := "res://data/characters/playable_roster.json"
var roster: Array = []

func _ready() -> void:
    roster = _load_array(DATA_PATH)

func available_characters() -> Array:
    if roster.is_empty(): roster = _load_array(DATA_PATH)
    return roster.filter(func(row): return _unlocked(row.get("unlock", {})))

func select_character(character_id: StringName) -> bool:
    for row in available_characters():
        if String(row.get("id", "")) != String(character_id): continue
        GameState.selected_character_id = character_id
        GameState.run_build["character_start"] = row.get("starting_build", []).duplicate(true)
        character_selected.emit(character_id, row)
        return true
    return false

func _unlocked(rule: Dictionary) -> bool:
    match String(rule.get("kind", "")):
        "default": return true
        "stage_mark": return bool(GameState.completion_marks.get(String(rule.get("id", "")), false))
        "story_epilogue": return bool(GameState.meta_progression.get("story_epilogue_complete", false))
        "initiation_complete": return bool(GameState.meta_progression.get("student_initiation_completed", false))
        "theophany_mastery": return String(rule.get("id", "")) in GameState.meta_progression.get("theophany_mastery", [])
        "codex_threshold": return int(GameState.meta_progression.get("codex_entries", 0)) >= int(rule.get("count", 0))
        "precision_challenge": return bool(GameState.meta_progression.get("precision_challenge", false))
        "pact_refusal_chain": return int(GameState.meta_progression.get("pacts_refused", 0)) >= 3
        "fortune_mastery": return bool(GameState.meta_progression.get("fortune_mastery", false))
        "transformation_mastery": return int(GameState.meta_progression.get("transformations_unlocked", 0)) >= int(rule.get("count", 0))
        "archon_route_break": return bool(GameState.meta_progression.get("archon_route_break", false))
    return false

func _load_array(path: String) -> Array:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return []
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Array else []
