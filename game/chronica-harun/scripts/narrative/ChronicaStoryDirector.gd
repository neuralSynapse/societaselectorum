extends Node
class_name ChronicaStoryDirector

signal stage_story_started(stage_id: StringName, stage: Dictionary)
signal beat_started(stage_id: StringName, beat_id: StringName, beat: Dictionary)
signal stage_story_completed(stage_id: StringName, next_stage: StringName)
signal epilogue_started(epilogue: Dictionary)
signal epilogue_finished(continuity_target: StringName)
signal story_state_persist_requested(state: Dictionary)

const STORY_PATH := "res://data/narrative/chronica_story_bible.json"
const PEREGRINUS_IGNIS_GAME := "PEREGRINUS_IGNIS_GAME"

var story_state: Dictionary = {}
var journey: Array = []
var stages_by_id: Dictionary = {}
var epilogue: Dictionary = {}
var current_stage_id: StringName = &""
var triggered_beats: Dictionary = {}

func configure(state: Dictionary = {}) -> void:
    story_state = state
    triggered_beats = story_state.get("triggered_story_beats", {}).duplicate(true)
    var story := _load_story()
    journey = story.get("student_journey", []).duplicate(true)
    epilogue = story.get("epilogue", {}).duplicate(true)
    stages_by_id.clear()
    for row in journey:
        stages_by_id[String(row.get("stage_id", ""))] = row

func begin_stage(stage_id: StringName) -> bool:
    if stages_by_id.is_empty():
        configure(story_state)
    var key := String(stage_id)
    if not stages_by_id.has(key):
        return false
    current_stage_id = stage_id
    stage_story_started.emit(stage_id, stages_by_id[key].duplicate(true))
    return true

func trigger(stage_id: StringName, beat_id: StringName) -> bool:
    var key := String(stage_id)
    if not stages_by_id.has(key):
        return false
    var stage: Dictionary = stages_by_id[key]
    for beat in stage.get("beats", []):
        if String(beat.get("id", "")) != String(beat_id):
            continue
        var seen_key := key + ":" + String(beat_id)
        if triggered_beats.get(seen_key, false):
            return false
        triggered_beats[seen_key] = true
        story_state["triggered_story_beats"] = triggered_beats.duplicate(true)
        beat_started.emit(stage_id, beat_id, beat.duplicate(true))
        story_state_persist_requested.emit(story_state.duplicate(true))
        return true
    return false

func complete_stage(stage_id: StringName) -> bool:
    var key := String(stage_id)
    if not stages_by_id.has(key):
        return false
    var index := -1
    for i in journey.size():
        if String(journey[i].get("stage_id", "")) == key:
            index = i
            break
    if index < 0:
        return false
    var completed: Array = story_state.get("completed_story_stages", [])
    if not completed.has(key):
        completed.append(key)
    story_state["completed_story_stages"] = completed
    var next_stage := PEREGRINUS_IGNIS_GAME if index == journey.size() - 1 else String(journey[index + 1].get("stage_id", ""))
    if index == journey.size() - 1:
        story_state["journey_state"] = PEREGRINUS_IGNIS_GAME
    story_state_persist_requested.emit(story_state.duplicate(true))
    stage_story_completed.emit(stage_id, StringName(next_stage))
    return true

func begin_epilogue() -> bool:
    if epilogue.is_empty():
        configure(story_state)
    if epilogue.is_empty():
        return false
    epilogue_started.emit(epilogue.duplicate(true))
    return true

func finish_epilogue() -> void:
    story_state["chronica_epilogue_completed"] = true
    story_state_persist_requested.emit(story_state.duplicate(true))
    epilogue_finished.emit(StringName(epilogue.get("continuity_target", "")))

func _load_story() -> Dictionary:
    var file := FileAccess.open(STORY_PATH, FileAccess.READ)
    if file == null:
        push_error("ChronicaStoryDirector: story bible unavailable")
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
