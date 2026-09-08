extends Node
class_name StoryCodexService

signal entry_unlocked(entry_id: StringName, entry: Dictionary)

const CODEX_PATH := "res://data/codex/story_codex.json"

var entries: Dictionary = {}

func _ready() -> void:
    _load_entries()

func unlock(entry_id: StringName) -> bool:
    if entries.is_empty():
        _load_entries()
    var key := String(entry_id)
    if not entries.has(key):
        return false
    var unlocked: Array = GameState.meta_progression.get("story_codex", [])
    if not unlocked.has(key):
        unlocked.append(key)
        GameState.meta_progression["story_codex"] = unlocked
        SaveService.save_campaign(GameState.to_save_data())
        entry_unlocked.emit(entry_id, entries[key].duplicate(true))
    return true

func is_unlocked(entry_id: StringName) -> bool:
    var unlocked: Array = GameState.meta_progression.get("story_codex", [])
    return unlocked.has(String(entry_id))

func entry(entry_id: StringName) -> Dictionary:
    if entries.is_empty():
        _load_entries()
    return entries.get(String(entry_id), {}).duplicate(true)

func all_unlocked() -> Array:
    if entries.is_empty():
        _load_entries()
    var result: Array = []
    for id in GameState.meta_progression.get("story_codex", []):
        if entries.has(String(id)):
            result.append(entries[String(id)].duplicate(true))
    return result

func unlock_by_key(unlock_key: String) -> bool:
    if entries.is_empty():
        _load_entries()
    for id in entries:
        if String(entries[id].get("unlock_key", "")) == unlock_key:
            return unlock(StringName(id))
    return false

func _load_entries() -> void:
    entries.clear()
    var file := FileAccess.open(CODEX_PATH, FileAccess.READ)
    if file == null:
        push_error("StoryCodexService: story codex unavailable")
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is not Array:
        push_error("StoryCodexService: invalid story codex")
        return
    for row in parsed:
        entries[String(row.get("id", ""))] = row
