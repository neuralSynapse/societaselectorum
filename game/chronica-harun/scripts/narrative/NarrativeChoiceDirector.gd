extends Node
class_name NarrativeChoiceDirector

signal choice_requested(stage_id: StringName, choice: Dictionary)
signal choice_resolved(stage_id: StringName, choice_id: StringName, option: Dictionary)
signal consequence_requested(external_hook: StringName, payload: Dictionary)
signal story_state_persist_requested(state: Dictionary)

const STORY_PATH := "res://data/narrative/chronica_story_bible.json"

var choices_by_stage: Dictionary = {}
var story_state: Dictionary = {}
var active_stage: StringName = &""
var active_choice: Dictionary = {}

func configure(next_story_state: Dictionary) -> void:
    story_state = next_story_state.duplicate(true)
    if not story_state.has("narrative_choices"):
        story_state["narrative_choices"] = {}
    _load_choices()

func present_stage_choice(stage_id: StringName) -> bool:
    if choices_by_stage.is_empty():
        _load_choices()
    var key := String(stage_id)
    if not choices_by_stage.has(key):
        return false
    var resolved: Dictionary = story_state.get("narrative_choices", {})
    if resolved.has(key):
        return false
    active_stage = stage_id
    active_choice = choices_by_stage[key].duplicate(true)
    choice_requested.emit(stage_id, active_choice.duplicate(true))
    return true

func choose(option_id: StringName) -> bool:
    if active_choice.is_empty() or active_stage == &"":
        return false
    var selected: Dictionary = {}
    for option in active_choice.get("options", []):
        if String(option.get("id", "")) == String(option_id):
            selected = option.duplicate(true)
            break
    if selected.is_empty():
        return false
    var resolved: Dictionary = story_state.get("narrative_choices", {})
    resolved[String(active_stage)] = {
        "choice_id": String(active_choice.get("id", "")),
        "option_id": String(option_id),
        "story_consequence": String(selected.get("story_consequence", "")),
        "external_hook": String(selected.get("external_hook", ""))
    }
    story_state["narrative_choices"] = resolved
    var stage := active_stage
    var choice_id := StringName(active_choice.get("id", ""))
    var hook := StringName(selected.get("external_hook", ""))
    story_state_persist_requested.emit(story_state.duplicate(true))
    choice_resolved.emit(stage, choice_id, selected.duplicate(true))
    consequence_requested.emit(hook, {
        "stage_id": String(stage),
        "choice_id": String(choice_id),
        "option_id": String(option_id),
        "immediate_cost": selected.get("immediate_cost", ""),
        "story_consequence": selected.get("story_consequence", "")
    })
    active_choice.clear()
    active_stage = &""
    return true

func _load_choices() -> void:
    choices_by_stage.clear()
    var file := FileAccess.open(STORY_PATH, FileAccess.READ)
    if file == null:
        push_error("NarrativeChoiceDirector: story bible unavailable")
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return
    for stage in parsed.get("student_journey", []):
        var choice: Dictionary = stage.get("choice_event", {})
        if not choice.is_empty():
            choices_by_stage[String(stage.get("stage_id", ""))] = choice.duplicate(true)
