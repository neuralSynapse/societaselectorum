extends Node

const SAVE_PATH := "user://chronica_harun_campaign.json"
const CAMPAIGN_VERSION := 2

func has_campaign() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_campaign(snapshot: Dictionary) -> bool:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null: return false
    var data := snapshot.duplicate(true)
    data["campaign_version"] = CAMPAIGN_VERSION
    file.store_string(JSON.stringify(data))
    return true

func load_campaign() -> Dictionary:
    if not has_campaign(): return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null: return {}
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK: return {}
    var parsed = parser.data
    if not (parsed is Dictionary): return {}
    var data: Dictionary = parsed
    if int(data.get("campaign_version", -1)) != CAMPAIGN_VERSION: return {}
    if not data.has("run_seed"): return {}
    return data
