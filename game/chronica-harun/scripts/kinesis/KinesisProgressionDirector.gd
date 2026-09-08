extends Node
class_name KinesisProgressionDirector

signal node_unlocked(node_id: StringName)
signal ability_equipped(ability_id: StringName, slot: int)
signal ability_used(ability_id: StringName, payload: Dictionary)

const LIBRI_PATH := "res://data/kinesis/nine_libri_progression.json"
const ABILITIES_PATH := "res://data/kinesis/kinetic_disciplines.json"
const MAX_LOADOUT := 3
var libri: Array = []
var abilities: Array = []
var cooldowns: Dictionary = {}

func _ready() -> void:
    libri = _load_array(LIBRI_PATH)
    abilities = _load_array(ABILITIES_PATH)

func unlock_node(node_id: StringName) -> bool:
    if not _node_exists(node_id): return false
    var state := _state()
    var unlocked: Array = state.get("unlocked_nodes", [])
    if not unlocked.has(String(node_id)): unlocked.append(String(node_id))
    state["unlocked_nodes"] = unlocked
    GameState.meta_progression["kinesis"] = state
    node_unlocked.emit(node_id)
    return true

func equip_ability(ability_id: StringName, slot := -1) -> bool:
    var ability := _ability(ability_id)
    if ability.is_empty() or not _ability_unlocked(ability): return false
    var loadout: Array = GameState.run_build.get("kinesis_loadout", [])
    loadout.erase(String(ability_id))
    if slot >= 0 and slot < MAX_LOADOUT:
        while loadout.size() <= slot: loadout.append("")
        loadout[slot] = String(ability_id)
    else:
        if loadout.size() >= MAX_LOADOUT: loadout.pop_front()
        loadout.append(String(ability_id))
    GameState.run_build["kinesis_loadout"] = loadout
    ability_equipped.emit(ability_id, loadout.find(String(ability_id)))
    return true

func use_ability(ability_id: StringName, player: PlayerController = null, context: Dictionary = {}) -> Dictionary:
    var ability := _ability(ability_id)
    if ability.is_empty() or String(ability_id) not in current_loadout(): return {}
    if float(cooldowns.get(String(ability_id), 0.0)) > 0.0: return {}
    var cost: Dictionary = ability.get("ability", {}).get("cost", {})
    if String(cost.get("resource", "")) == "focus" and player != null:
        if not player.spend_focus(float(cost.get("amount", 0.0))): return {}
    cooldowns[String(ability_id)] = float(ability.get("ability", {}).get("cooldown", 0.0))
    var payload: Dictionary = ability.get("ability", {}).duplicate(true)
    payload["id"] = String(ability_id)
    payload["combat_hooks"] = ability.get("combat_hooks", []).duplicate(true)
    payload["context"] = context
    ability_used.emit(ability_id, payload)
    return payload

func tick(delta: float) -> void:
    for key in cooldowns.keys(): cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)

func current_loadout() -> Array:
    return GameState.run_build.get("kinesis_loadout", []).duplicate(true)

func _ability_unlocked(ability: Dictionary) -> bool:
    var node := String(ability.get("unlock", {}).get("node", ""))
    return node in _state().get("unlocked_nodes", [])

func _node_exists(node_id: StringName) -> bool:
    for liber in libri:
        for node in liber.get("progression_tree", {}).get("nodes", []):
            if String(node.get("id", "")) == String(node_id): return true
    return false

func _ability(id: StringName) -> Dictionary:
    if abilities.is_empty(): abilities = _load_array(ABILITIES_PATH)
    for row in abilities:
        if String(row.get("id", "")) == String(id): return row
    return {}

func _state() -> Dictionary:
    return GameState.meta_progression.get("kinesis", {"unlocked_nodes": [], "mastery": {}}).duplicate(true)

func _load_array(path: String) -> Array:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return []
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Array else []
