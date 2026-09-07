extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://chronica_harun_save_v1.json"

func save_local(state: Dictionary) -> Error:
    var payload := state.duplicate(true)
    payload["save_version"] = SAVE_VERSION
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(payload))
    return OK

func load_local() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    if int(parsed.get("save_version", -1)) != SAVE_VERSION:
        return {}
    return parsed
