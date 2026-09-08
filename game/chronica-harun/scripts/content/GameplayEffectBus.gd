extends Node
class_name GameplayEffectBus

signal effect_dispatched(kind: StringName, payload: Dictionary)
signal effect_rejected(kind: StringName, reason: String)

const SUPPORTED_KINDS := [
    "arcana", "sigillum_contract", "pharmakon", "decan_modifier",
    "instrument_action", "matrix_power", "daimon_action", "relic_rule",
    "transformation", "curse", "blessing", "route", "room_event"
]

func dispatch(effect: Dictionary, context: Dictionary = {}) -> Dictionary:
    var kind := String(effect.get("kind", ""))
    if kind not in SUPPORTED_KINDS:
        effect_rejected.emit(StringName(kind), "unsupported_kind")
        return {}
    var payload := effect.duplicate(true)
    payload["context"] = context.duplicate(true)
    match kind:
        "arcana": payload["resolved_action"] = String(effect.get("effect_id", "arcana"))
        "sigillum_contract": payload["resolved_action"] = "apply_dominium_and_pretium"
        "pharmakon": payload["resolved_action"] = "apply_benefit_and_side_effect"
        "decan_modifier": payload["resolved_action"] = "apply_conditional_modifier"
        "instrument_action": payload["resolved_action"] = String(effect.get("action", effect.get("effect_id", "instrument")))
        "matrix_power": payload["resolved_action"] = "activate_power_matrix"
        "daimon_action": payload["resolved_action"] = "trigger_daimon_behavior"
        "relic_rule": payload["resolved_action"] = "alter_run_rule"
        "transformation": payload["resolved_action"] = "activate_transformation"
        "curse": payload["resolved_action"] = "apply_floor_curse"
        "blessing": payload["resolved_action"] = "apply_blessing"
        "route": payload["resolved_action"] = "commit_route"
        "room_event": payload["resolved_action"] = String(effect.get("event", "room_event"))
    effect_dispatched.emit(StringName(kind), payload)
    return payload
