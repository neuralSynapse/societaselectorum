extends Node

const MANIFEST_PATH := "res://data/roguelite/catalog_manifest.json"

var manifest: Dictionary = {}

func _ready() -> void:
    manifest = load_json(MANIFEST_PATH)

func load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return parsed

func expected_counts() -> Dictionary:
    return manifest.get("expected_counts", {}).duplicate(true)

func recovered_catalogs() -> Array[String]:
    var recovered: Array[String] = []
    for entry in manifest.get("catalogs", []):
        if str(entry.get("status", "")) == "recovered":
            recovered.append(str(entry.get("id", "")))
    return recovered
