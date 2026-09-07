extends RefCounted
class_name BuildResolver

const SUPPORTED_EFFECT_KINDS := [
    "adjustment", "aeon", "analysis_engine", "anchor", "anchor_stance", "armor_break", "art",
    "balanced_exchange", "belial_ground", "black_flame", "blessing", "blindspot_trade", "bond_pair",
    "break_the_map", "broken_crown", "chain_strike", "chariot", "choice_of_cups", "combo_engine",
    "command", "command_wave", "communion", "cone_fire", "craft_triangle", "curse", "curse_cleanse",
    "daimon_action", "dash_break", "death", "decan_modifier", "devil", "dominate", "door_cut", "dual_mark",
    "echo_card", "echo_instrument", "equitable_return", "fecundity", "feint", "fire_overflow", "flow_engine",
    "focus_spring", "focus_well", "formation_chain", "fortify", "fortress", "fortune", "grounding", "heal_link",
    "hermit", "ignite_seed", "investment", "lilith_veil", "line_beam", "line_of_truth", "lust", "manifest_field",
    "mark_reveal", "material_seed", "matrix_power", "matter_engine", "matter_overflow", "memory_recovery", "moon",
    "multiply_essence", "mutation_hook", "overdrive_risk", "overflow_heal", "pharmakon", "phase", "phosphoros_ember",
    "pleroma_balance", "precision", "precision_wager", "quiet_blade", "recovery_circle", "red_path", "reflect",
    "reflect_rule", "reroll", "resource_aura", "return", "reveal_all", "reveal_edge", "room_event", "route",
    "rupture_triangle", "saturn_cycle", "scarcity_alchemy", "secret_sight", "severance", "sigillum_contract", "silence",
    "slow_cut", "solar_burst", "split_will", "star", "still_pool", "suit_finisher", "sun", "suspension", "syzygy",
    "tempo_shift", "thoth_inscription", "threshold_gambit", "threshold_reset", "time_stop", "tower", "tradition",
    "transformation", "transmute_hurt", "universe", "velocity_engine", "victory_resonance", "war_stance", "ward",
    "will_culmination", "wound_to_focus"
]

func resolve(entry: Dictionary, context: Dictionary) -> Dictionary:
    var result := {"content_id":str(entry.get("id", "")),"state_changes":{},"events":[],"synergies_triggered":[],"blocked_by":[],"consumed":false}
    if entry.is_empty():
        result["blocked_by"].append("missing_entry")
        return result
    var effect: Dictionary = entry.get("effect", {})
    var kind: String = str(effect.get("kind", ""))
    if not SUPPORTED_EFFECT_KINDS.has(kind):
        result["blocked_by"].append("unsupported_effect:%s" % kind)
        return result
    var owned_ids: Array = context.get("owned_ids", [])
    var tags: Array = context.get("tags", [])
    for exclusion in entry.get("exclusions", []):
        var ref := str(exclusion)
        if ref.begins_with("tag:") and tags.has(ref.substr(4)): result["blocked_by"].append(ref)
        elif owned_ids.has(ref): result["blocked_by"].append(ref)
    if not result["blocked_by"].is_empty(): return result
    if not _can_pay(entry.get("cost", {}), context.get("resources", {})):
        result["blocked_by"].append("insufficient_cost")
        return result
    _record_cost(entry.get("cost", {}), result)
    _resolve_synergies(entry, owned_ids, tags, result)
    _resolve_stacking(entry, context.get("active_effects", {}), result)
    if not result["blocked_by"].is_empty(): return result
    _dispatch_effect(entry, effect, context, result)
    result["events"].append({"name":"effect.%s" % kind,"content_id":entry.get("id", ""),"effect":effect.duplicate(true),"vfx_hook":entry.get("vfx_hook", ""),"sfx_hook":entry.get("sfx_hook", "")})
    result["consumed"] = entry.get("save_state", {}).get("scope", "run") != "none"
    return result

func _can_pay(cost: Dictionary, resources: Dictionary) -> bool:
    var resource := str(cost.get("resource", "none")); var amount := float(cost.get("amount", 0))
    if resource == "none" or amount <= 0: return true
    return float(resources.get(resource, 0)) >= amount

func _record_cost(cost: Dictionary, result: Dictionary) -> void:
    var resource := str(cost.get("resource", "none")); var amount := float(cost.get("amount", 0))
    if resource != "none" and amount > 0: result["state_changes"]["resource_delta:%s" % resource] = -amount

func _resolve_synergies(entry: Dictionary, owned_ids: Array, tags: Array, result: Dictionary) -> void:
    for synergy in entry.get("synergies", []):
        var ref := str(synergy)
        if ref.begins_with("tag:") and tags.has(ref.substr(4)): result["synergies_triggered"].append(ref)
        elif owned_ids.has(ref): result["synergies_triggered"].append(ref)

func _resolve_stacking(entry: Dictionary, active_effects: Dictionary, result: Dictionary) -> void:
    var content_id := str(entry.get("id", "")); var stacking: Dictionary = entry.get("stacking", {})
    var mode := str(stacking.get("mode", "none")); var max_stacks := int(stacking.get("max_stacks", 1)); var current := int(active_effects.get(content_id, 0))
    if mode in ["none", "unique_transform"] and current > 0:
        result["blocked_by"].append("stacking:%s" % mode); return
    var next_stack := 1
    if mode in ["additive", "multiplicative", "charges"]: next_stack = min(current + 1, max_stacks)
    elif mode == "refresh": next_stack = max(1, current)
    result["state_changes"]["active_effect:%s" % content_id] = next_stack

func _dispatch_effect(entry: Dictionary, effect: Dictionary, context: Dictionary, result: Dictionary) -> void:
    var kind := str(effect.get("kind", ""))
    match kind:
        "focus_spring": result["state_changes"]["resource_delta:focus"] = float(effect.get("focus_gain", 0))
        "material_seed":
            result["state_changes"]["stat_delta:armor"] = float(effect.get("armor", 0)); result["state_changes"]["resource_delta:essence"] = float(effect.get("essence", 0))
        "precision", "reveal_edge": result["state_changes"]["stat_delta:precision"] = float(effect.get("magnitude", effect.get("precision", 0.12)))
        "fortify", "fortress": result["state_changes"]["stat_delta:armor"] = float(effect.get("magnitude", effect.get("barrier_value", 6)))
        "focus_well": result["state_changes"]["resource_delta:focus"] = 25.0
        "multiply_essence": result["state_changes"]["resource_multiplier:essence"] = 1.0 + float(effect.get("magnitude", 0.25))
        "curse_cleanse": result["events"].append({"name":"meta.cleanse_curse","amount":1})
        "reveal_all", "secret_sight", "break_the_map": result["events"].append({"name":"map.reveal","scope":"all" if kind == "reveal_all" else "secrets"})
        "door_cut": result["events"].append({"name":"room.secret_open_request","opener":"wall_break"})
        "red_path": result["events"].append({"name":"route.affinity","tag":"route:draconic"})
        "sigillum_contract": result["events"].append({"name":"sigillum.contract","dominium":effect.get("dominium"),"trigger":effect.get("trigger"),"benefit":effect.get("benefit"),"pretium":effect.get("pretium")})
        "pharmakon": result["events"].append({"name":"pharmakon.consume","principle":effect.get("principle"),"planet":effect.get("planet"),"benefit":effect.get("benefit"),"liability":effect.get("liability"),"magnitude":effect.get("magnitude")})
        "decan_modifier": result["events"].append({"name":"talisman.modifier","stat":effect.get("stat"),"condition":effect.get("condition"),"magnitude":effect.get("magnitude")})
        "mutation_hook": result["events"].append({"name":"mutation.bind","hook":effect.get("hook"),"operation":effect.get("operation"),"magnitude":effect.get("magnitude")})
        "daimon_action": result["events"].append({"name":"daimon.bind","action":effect.get("action"),"cooldown_sec":effect.get("cooldown_sec"),"magnitude":effect.get("magnitude")})
        "matrix_power": result["events"].append({"name":effect.get("runtime_event", "power.activate"),"focus_cost":effect.get("cost_focus"),"cooldown_sec":effect.get("cooldown_sec")})
        "route", "curse", "blessing", "transformation", "room_event": result["events"].append({"name":"meta.%s" % kind,"payload":effect.duplicate(true)})
        _: result["events"].append({"name":"gameplay.dispatch","kind":kind,"payload":effect.duplicate(true),"context_tags":context.get("tags", []).duplicate()})
