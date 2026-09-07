extends RefCounted
class_name PowerMutationRuntime

const EFFECTS := {
"revealed_crit":"damage","projectile_vision":"projectile","secret_map":"passive","ember_corpse":"kill","hurt_fuels_flame":"hurt","chain_flame":"damage","shockwave":"damage","break_armor_secret":"passive","elite_stamina":"kill","first_mark_crit":"damage","fear_immunity":"projectile","choice_shield":"room","hp_to_focus":"hurt","focus_to_shield":"hurt","balance_cleanse":"passive","projectile_dash":"dodge","unstoppable_action":"projectile","execute_low":"damage","still_defense":"passive","block_attack":"passive","calm_focus":"room","combo_recharge":"damage","perfect_dodge_charge":"dodge","no_damage_speed":"room","telegraph_reveal":"passive","visual_cleanse":"passive","route_marker":"passive","hurt_to_focus":"hurt","curse_to_buff":"passive","overflow_to_essence":"room","room_heal":"room","perfect_dodge_stamina":"dodge","low_hp_speed":"passive","temporary_ward":"room","virtual_charge":"room","break_fragment":"kill","reward_reroll":"passive","essence_rare_room":"passive","pact_refund":"passive","push_wave":"passive","silence_ranged":"projectile","temporary_dominate":"damage","first_card_free":"passive","instrument_charge_memory":"room","build_trait_memory":"passive"}

static func active_effects(build: Dictionary = GameState.run_build) -> Array[String]:
    var out: Array[String] = []
    var active: Array = build.get("mutations",[])
    for power in ContentRegistry.all("powers"):
        for mutation in power.get("mutations",[]):
            if active.has(String(mutation.id)): out.append(String(mutation.effect_id))
    return out

static func modify_damage(base_damage: float, context: Dictionary = {}) -> float:
    var value := base_damage
    for effect in active_effects():
        if EFFECTS.get(effect) != "damage": continue
        if effect == "revealed_crit" and not context.get("revealed",false): continue
        if effect == "execute_low" and float(context.get("target_hp_ratio",1.0)) > .2: continue
        value *= 1.08
    return value

static func on_player_damaged(amount: float, _context: Dictionary = {}) -> Dictionary:
    var out := {"focus_gain":0.0,"shield_gain":0.0,"next_flame_bonus":0.0}
    for effect in active_effects():
        if effect == "hurt_fuels_flame": out.next_flame_bonus += amount*.45
        elif effect in ["hp_to_focus","hurt_to_focus"]: out.focus_gain += amount*.34
        elif effect == "focus_to_shield": out.shield_gain += amount*.15
    return out

static func on_room_cleared(context: Dictionary = {}) -> Dictionary:
    var out := {"heal":0.0,"focus":0.0,"charges":0,"essence":0,"speed_duration":0.0}
    for effect in active_effects():
        if effect == "room_heal": out.heal += 8
        elif effect == "calm_focus": out.focus += 12
        elif effect in ["virtual_charge","instrument_charge_memory"]: out.charges += 1
        elif effect == "overflow_to_essence": out.essence += 1
        elif effect == "no_damage_speed" and not context.get("damage_taken",false): out.speed_duration = 8.0
    return out

static func on_dodge(perfect: bool, _context: Dictionary = {}) -> Dictionary:
    var out := {"charges":0,"stamina":0.0,"projectile_invulnerability":false}
    for effect in active_effects():
        if effect == "projectile_dash": out.projectile_invulnerability = true
        elif effect == "perfect_dodge_charge" and perfect: out.charges += 1
        elif effect == "perfect_dodge_stamina" and perfect: out.stamina += 24
    return out

static func on_enemy_killed(context: Dictionary = {}) -> Dictionary:
    var out := {"ember":false,"fragment":false,"stamina":0.0}
    for effect in active_effects():
        if effect == "ember_corpse": out.ember = true
        elif effect == "break_fragment": out.fragment = true
        elif effect == "elite_stamina" and context.get("elite",false): out.stamina += 18
    return out

static func on_projectile_about_to_hit(context: Dictionary = {}) -> Dictionary:
    var out := {"visible":false,"ignore":false,"silence_source":false}
    for effect in active_effects():
        if effect == "projectile_vision": out.visible = true
        elif effect == "fear_immunity" and context.get("fear",false): out.ignore = true
        elif effect == "unstoppable_action" and context.get("interrupt",false): out.ignore = true
        elif effect == "silence_ranged": out.silence_source = true
    return out
