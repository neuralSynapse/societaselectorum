extends Node
class_name CosmogonyPrologueDirector

signal scene_started(scene_id: StringName, scene: Dictionary)
signal narration_requested(lines: Array, duration_seconds: float)
signal visual_requested(payload: Dictionary)
signal audio_requested(payload: Dictionary)
signal prologue_finished(next_sequence: StringName)
signal completion_persist_requested(key: StringName, value)
signal skip_rejected(reason: String)

const STORY_PATH := "res://data/narrative/chronica_story_bible.json"

var story_state: Dictionary = {}
var scenes: Array = []
var index := -1
var running := false
var prologue_completed := false
var skip_unlocked := false

func configure(state: Dictionary = {}) -> void:
    story_state = state
    prologue_completed = bool(story_state.get("prologue_completed", false))
    skip_unlocked = bool(story_state.get("skip_unlocked", prologue_completed))
    var story := _load_story()
    var all_scenes: Array = story.get("prologue", [])
    scenes = all_scenes.slice(0, 10)

func start() -> bool:
    if scenes.is_empty():
        configure(story_state)
    if scenes.is_empty():
        return false
    index = 0
    running = true
    _emit_current()
    return true

func advance() -> bool:
    if not running:
        return false
    index += 1
    if index >= scenes.size():
        running = false
        mark_completed()
        prologue_finished.emit(&"harun_origin")
        return true
    _emit_current()
    return true

func skip() -> bool:
    if not skip_unlocked:
        skip_rejected.emit("O salto do prólogo libera somente após a primeira conclusão.")
        return false
    running = false
    prologue_finished.emit(&"harun_origin")
    return true

func current_scene() -> Dictionary:
    if index < 0 or index >= scenes.size():
        return {}
    return scenes[index].duplicate(true)

func mark_completed() -> void:
    prologue_completed = true
    skip_unlocked = true
    story_state["prologue_completed"] = true
    story_state["skip_unlocked"] = true
    completion_persist_requested.emit(&"prologue_completed", true)
    completion_persist_requested.emit(&"skip_unlocked", true)

func _emit_current() -> void:
    var scene := current_scene()
    if scene.is_empty():
        return
    scene_started.emit(StringName(scene.get("id", "")), scene)
    narration_requested.emit(scene.get("voiceover", []), float(scene.get("duration_seconds", 30.0)))
    visual_requested.emit(scene.get("visual", {}))
    audio_requested.emit(scene.get("audio", {}))

func _load_story() -> Dictionary:
    var file := FileAccess.open(STORY_PATH, FileAccess.READ)
    if file == null:
        push_error("CosmogonyPrologueDirector: story bible unavailable")
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
