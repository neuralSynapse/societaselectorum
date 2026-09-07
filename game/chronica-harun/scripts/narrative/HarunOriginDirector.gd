extends Node
class_name HarunOriginDirector

signal origin_scene_started(scene_id: StringName, scene: Dictionary)
signal fragment_registered(fragment_id: StringName, current: int, required: int)
signal title_revealed(title: String)
signal command_revealed(command: StringName, index: int)
signal origin_finished(target_stage: StringName)
signal story_state_persist_requested(state: Dictionary)

const STORY_PATH := "res://data/narrative/chronica_story_bible.json"
const GRIMORIUM_TITLE := "GRIMORIUM ASCENSIONIS"

var story_state: Dictionary = {}
var scenes: Array = []
var index := -1
var fragment_ids: Array = []
var found_fragments: Array = []
var reveal_requires_all := true
var title_has_been_revealed := false

func configure(state: Dictionary = {}) -> void:
    story_state = state
    found_fragments = story_state.get("grimorium_fragments", []).duplicate(true)
    title_has_been_revealed = bool(story_state.get("grimorium_title_revealed", false))
    var story := _load_story()
    var all_scenes: Array = story.get("prologue", [])
    scenes = all_scenes.slice(10, 13)
    if not scenes.is_empty():
        var final_scene: Dictionary = scenes[-1]
        var grimoire: Dictionary = final_scene.get("grimoire", {})
        fragment_ids = grimoire.get("fragment_ids", []).duplicate(true)
        reveal_requires_all = bool(grimoire.get("reveal_requires_all", true))

func begin_origin_sequence() -> bool:
    if scenes.is_empty():
        configure(story_state)
    if scenes.is_empty():
        return false
    index = 0
    _emit_scene()
    return true

func register_fragment(fragment_id: StringName) -> bool:
    var key := String(fragment_id)
    if not fragment_ids.has(key):
        return false
    if not found_fragments.has(key):
        found_fragments.append(key)
        story_state["grimorium_fragments"] = found_fragments.duplicate(true)
        story_state_persist_requested.emit(story_state.duplicate(true))
    fragment_registered.emit(fragment_id, found_fragments.size(), fragment_ids.size())
    return true

func can_reveal_title() -> bool:
    if not reveal_requires_all:
        return not found_fragments.is_empty()
    for id in fragment_ids:
        if not found_fragments.has(id):
            return false
    return not fragment_ids.is_empty()

func reveal_title() -> bool:
    if title_has_been_revealed:
        return true
    if not can_reveal_title():
        return false
    title_has_been_revealed = true
    story_state["grimorium_title_revealed"] = true
    title_revealed.emit(GRIMORIUM_TITLE)
    story_state_persist_requested.emit(story_state.duplicate(true))
    return true

func advance() -> bool:
    if index < 0:
        return false
    if index == 1 and not can_reveal_title():
        return false
    if index == 1:
        reveal_title()
    index += 1
    if index >= scenes.size():
        var commands := ["VER", "GOVERNAR", "FAZER"]
        for i in commands.size():
            command_revealed.emit(StringName(commands[i]), i)
        origin_finished.emit(&"o_olho")
        return true
    _emit_scene()
    return true

func current_scene() -> Dictionary:
    if index < 0 or index >= scenes.size():
        return {}
    return scenes[index].duplicate(true)

func _emit_scene() -> void:
    var scene := current_scene()
    if not scene.is_empty():
        origin_scene_started.emit(StringName(scene.get("id", "")), scene)

func _load_story() -> Dictionary:
    var file := FileAccess.open(STORY_PATH, FileAccess.READ)
    if file == null:
        push_error("HarunOriginDirector: story bible unavailable")
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
