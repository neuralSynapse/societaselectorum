extends Node3D
class_name SpecialRoomRuntime

signal discovery_feedback(hook: String, room_id: String)
signal room_resolved(room_id: String, result: Dictionary)
signal reward_requested(pool: String, choices: int, room_id: String)

var room_data: Dictionary = {}
var resolver := BuildResolver.new()
var resolved := false

func configure(data: Dictionary) -> void:
    room_data = data.duplicate(true)
    resolved = false
    name = str(room_data.get("name", "SpecialRoomRuntime"))

func enter_room(run_state: Dictionary) -> Dictionary:
    if room_data.is_empty():
        return {"ok": false, "reason": "room_not_configured"}
    if resolved and bool(room_data.get("spawn_condition", {}).get("once_per_floor", true)):
        return {"ok": false, "reason": "room_already_resolved"}
    if not _pay_cost(room_data.get("cost", {}), run_state):
        return {"ok": false, "reason": "cannot_pay_entry_cost"}
    var room_id := str(room_data.get("id", ""))
    var visited := _ensure_array(run_state, "visited_rooms")
    if not visited.has(room_id):
        visited.append(room_id)
    var event := {
        "name": room_data.get("runtime_event", ""),
        "room_id": room_id,
        "risk": room_data.get("risk", {}).duplicate(true),
        "vfx_hook": room_data.get("vfx_hook", ""),
        "sfx_hook": room_data.get("sfx_hook", "")
    }
    _ensure_array(run_state, "run_events").append(event)
    var reward: Dictionary = room_data.get("reward", {})
    var pool := str(reward.get("pool", ""))
    var choices := int(reward.get("choices", 1))
    var candidates := _reward_candidates(pool, run_state, choices)
    if not candidates.is_empty():
        reward_requested.emit(pool, choices, room_id)
    discovery_feedback.emit(str(room_data.get("discovery_feedback", "")), room_id)
    resolved = true
    var result := {"ok": true, "event": event, "reward_pool": pool, "reward_candidates": candidates}
    room_resolved.emit(room_id, result)
    return result

func apply_reward(content_id: String, run_state: Dictionary) -> Dictionary:
    var entry := RogueliteContentService.get_entry(content_id)
    if entry.is_empty():
        return {"ok": false, "reason": "unknown_reward"}
    var context := {
        "owned_ids": run_state.get("inventory", []),
        "tags": run_state.get("build_tags", []),
        "resources": run_state.get("resources", {}),
        "active_effects": run_state.get("active_effects", {})
    }
    var result := resolver.resolve(entry, context)
    if not result["blocked_by"].is_empty():
        return {"ok": false, "reason": "reward_blocked", "resolution": result}
    _apply_state_changes(result["state_changes"], run_state)
    var inventory := _ensure_array(run_state, "inventory")
    if bool(result.get("consumed", false)) and not inventory.has(content_id):
        inventory.append(content_id)
    var build_tags := _ensure_array(run_state, "build_tags")
    for tag in entry.get("tags", []):
        if not build_tags.has(tag):
            build_tags.append(tag)
    _ensure_array(run_state, "run_events").append_array(result["events"])
    return {"ok": true, "resolution": result}

func _pay_cost(cost: Dictionary, run_state: Dictionary) -> bool:
    var resource := str(cost.get("resource", "none"))
    var amount := float(cost.get("amount", 0))
    if resource == "none" or amount <= 0:
        return true
    var resources := _ensure_dictionary(run_state, "resources")
    if float(resources.get(resource, 0)) < amount:
        return false
    resources[resource] = float(resources.get(resource, 0)) - amount
    return true

func _reward_candidates(pool: String, run_state: Dictionary, choices: int) -> Array:
    var candidates: Array = []
    if pool == "tarot":
        candidates = RogueliteContentService.catalogs.get("tarot", []).duplicate()
    elif RogueliteContentService.by_pool.has(pool):
        candidates = RogueliteContentService.get_pool(pool)
    else:
        _ensure_array(run_state, "run_events").append({"name": "room.reward_event", "pool": pool})
        return []
    candidates.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
    return candidates.slice(0, min(max(choices, 1), candidates.size()))

func _apply_state_changes(changes: Dictionary, run_state: Dictionary) -> void:
    var resources := _ensure_dictionary(run_state, "resources")
    var stats := _ensure_dictionary(run_state, "stats")
    var active := _ensure_dictionary(run_state, "active_effects")
    for key in changes:
        var value = changes[key]
        var text := str(key)
        if text.begins_with("resource_delta:"):
            var resource := text.substr("resource_delta:".length())
            resources[resource] = float(resources.get(resource, 0)) + float(value)
        elif text.begins_with("resource_multiplier:"):
            var resource := text.substr("resource_multiplier:".length())
            resources[resource] = float(resources.get(resource, 0)) * float(value)
        elif text.begins_with("stat_delta:"):
            var stat := text.substr("stat_delta:".length())
            stats[stat] = float(stats.get(stat, 0)) + float(value)
        elif text.begins_with("active_effect:"):
            active[text.substr("active_effect:".length())] = int(value)

func _ensure_array(state: Dictionary, key: String) -> Array:
    if not state.has(key) or not (state[key] is Array):
        state[key] = []
    return state[key]

func _ensure_dictionary(state: Dictionary, key: String) -> Dictionary:
    if not state.has(key) or not (state[key] is Dictionary):
        state[key] = {}
    return state[key]
