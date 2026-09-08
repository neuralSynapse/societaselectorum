extends RefCounted
class_name BuildResolver

static func resolve(build: Dictionary) -> Dictionary:
    var out := {"damage_mult":1.0,"speed_mult":1.0,"damage_taken_mult":1.0,"crit_bonus":0.0,"secret_reveal":false,"transformations":[]}
    for relic_id in build.get("relics",[]):
        var relic := ContentRegistry.get_item("relics",StringName(relic_id))
        match String(relic.get("effect_id","")):
            "slow_damage_reduction": out.damage_taken_mult *= .78
            "knockback_immunity_melee": out.damage_mult += .12
            "secret_reveal_hp_hidden": out.secret_reveal = true
    for t_id in build.get("talismans",[]):
        var t := ContentRegistry.get_item("talismans",StringName(t_id))
        if String(t.get("effect_id","")).begins_with("precision"): out.crit_bonus += .06
    return out
