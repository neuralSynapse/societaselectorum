class_name SpecialRoomDirector
extends RefCounted

const CONTRACT_PATH := "res://data/game_contract.json"

func known_room_ids() -> Array:
    if not FileAccess.file_exists(CONTRACT_PATH):
        return []
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
    if typeof(parsed) != TYPE_DICTIONARY:
        return []
    return parsed.get("special_rooms", [])
