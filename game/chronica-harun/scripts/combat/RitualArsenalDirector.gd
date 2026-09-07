extends Node
class_name RitualArsenalDirector

signal weapon_unlocked(weapon_id: StringName)
signal weapon_equipped(weapon_id: StringName)

const DATA_PATH := "res://data/combat/ritual_arsenal.json"
var arsenal: Array = []

func _ready() -> void:
    arsenal = _load_array(DATA_PATH)

func unlock_weapon(weapon_id: StringName) -> bool:
    if _weapon(weapon_id).is_empty(): return false
    var unlocked: Array = GameState.meta_progression.get("ritual_arsenal", [])
    if not unlocked.has(String(weapon_id)): unlocked.append(String(weapon_id))
    GameState.meta_progression["ritual_arsenal"] = unlocked
    weapon_unlocked.emit(weapon_id)
    return true

func equip_weapon(weapon_id: StringName) -> bool:
    if String(weapon_id) not in GameState.meta_progression.get("ritual_arsenal", []): return false
    GameState.run_build["ritual_weapon"] = String(weapon_id)
    weapon_equipped.emit(weapon_id)
    return true

func primary_attack_profile() -> Dictionary:
    var id := StringName(GameState.run_build.get("ritual_weapon", ""))
    var row := _weapon(id)
    return row.get("combat_profile", {}).duplicate(true) if not row.is_empty() else {}

func _weapon(id: StringName) -> Dictionary:
    if arsenal.is_empty(): arsenal = _load_array(DATA_PATH)
    for row in arsenal:
        if String(row.get("id", "")) == String(id): return row
    return {}

func _load_array(path: String) -> Array:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return []
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Array else []
