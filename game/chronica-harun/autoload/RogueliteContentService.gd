extends Node

signal effect_requested(effect_id: StringName, payload: Dictionary)
signal build_changed(build: Dictionary)

func ensure_build() -> Dictionary:
    if GameState.run_build.is_empty():
        GameState.run_build = {
            "arcana":"", "pharmakon":"", "sigillum":"", "talismans":[],
            "instrumentum":{}, "relics":[], "daimon":"", "mutations":[],
            "transformations":[], "route":String(GameState.route_state.get("route","student")),
            "known_pharmaka":[], "flags":{}
        }
    return GameState.run_build

func grant(category: String, id: StringName) -> bool:
    var row := ContentRegistry.get_item(category, id)
    if row.is_empty():
        return false
    match category:
        "tarot": return set_arcana(id)
        "pharmaka": return set_pharmakon(id)
        "sigilla": return bind_sigillum(id)
        "instrumenta": return equip_instrumentum(id)
        "talismans": return equip_talisman(id)
        "relics": return equip_relic(id)
        "daimones": return set_daimon(id)
        "blessings":
            var list: Array = GameState.route_state.get("blessings", [])
            if not list.has(String(id)): list.append(String(id))
            GameState.route_state["blessings"] = list
            _changed(); return true
        "curses":
            var list: Array = GameState.route_state.get("curses", [])
            if not list.has(String(id)): list.append(String(id))
            GameState.route_state["curses"] = list
            _changed(); return true
        "routes": return set_route(id)
        "transformations":
            var list: Array = ensure_build().get("transformations", [])
            if not list.has(String(id)): list.append(String(id))
            ensure_build()["transformations"] = list
            _changed(); return true
    return false

func set_arcana(id: StringName) -> bool:
    if ContentRegistry.get_item("tarot", id).is_empty(): return false
    ensure_build()["arcana"] = String(id)
    _changed(); return true

func use_arcana(context: Dictionary = {}) -> bool:
    var build := ensure_build()
    var id := StringName(build.get("arcana", ""))
    if id == &"": return false
    var card := ContentRegistry.get_item("tarot", id)
    if card.is_empty(): return false
    _dispatch_arcana(StringName(card.get("effect_id", "")), card, context)
    build["arcana"] = ""
    _changed(); return true

func set_pharmakon(id: StringName) -> bool:
    if ContentRegistry.get_item("pharmaka", id).is_empty(): return false
    ensure_build()["pharmakon"] = String(id)
    _changed(); return true

func use_pharmakon(context: Dictionary = {}) -> bool:
    var build := ensure_build()
    var id := StringName(build.get("pharmakon", ""))
    if id == &"": return false
    var item := ContentRegistry.get_item("pharmaka", id)
    if item.is_empty(): return false
    effect_requested.emit(StringName(item.get("effect_id", "")), {
        "kind":"pharmakon", "benefit":item.get("benefit", ""),
        "side_effect":item.get("side_effect", ""), "magnitude":item.get("magnitude", 0),
        "context":context
    })
    var known: Array = build.get("known_pharmaka", [])
    if not known.has(String(id)): known.append(String(id))
    build["known_pharmaka"] = known
    build["pharmakon"] = ""
    _changed(); return true

func bind_sigillum(id: StringName, context: Dictionary = {}) -> bool:
    var item := ContentRegistry.get_item("sigilla", id)
    if item.is_empty(): return false
    ensure_build()["sigillum"] = String(id)
    effect_requested.emit(StringName(item.get("effect_id", "")), {
        "kind":"sigillum", "dominium":item.get("dominium", ""),
        "pretium":item.get("pretium", ""), "boon":item.get("boon_magnitude", 0),
        "cost":item.get("cost_magnitude", 0), "context":context
    })
    _changed(); return true

func equip_talisman(id: StringName) -> bool:
    if ContentRegistry.get_item("talismans", id).is_empty(): return false
    var build := ensure_build()
    var list: Array = build.get("talismans", [])
    if not list.has(String(id)):
        if list.size() >= 2: list.pop_front()
        list.append(String(id))
    build["talismans"] = list
    _changed(); return true

func equip_instrumentum(id: StringName) -> bool:
    var item := ContentRegistry.get_item("instrumenta", id)
    if item.is_empty(): return false
    var charges := int(item.get("charges", 2))
    ensure_build()["instrumentum"] = {"id":String(id), "charges":charges, "max_charges":charges}
    _changed(); return true

func use_instrumentum(context: Dictionary = {}) -> bool:
    var build := ensure_build()
    var slot: Dictionary = build.get("instrumentum", {})
    if slot.is_empty() or int(slot.get("charges", 0)) <= 0: return false
    var item := ContentRegistry.get_item("instrumenta", StringName(slot.get("id", "")))
    if item.is_empty(): return false
    slot["charges"] = int(slot.get("charges", 0)) - 1
    build["instrumentum"] = slot
    _dispatch_instrument(StringName(item.get("effect_id", "")), item, context)
    _changed(); return true

func recharge_instrument(amount := 1) -> void:
    var build := ensure_build()
    var slot: Dictionary = build.get("instrumentum", {})
    if slot.is_empty(): return
    slot["charges"] = mini(int(slot.get("max_charges", 0)), int(slot.get("charges", 0)) + amount)
    build["instrumentum"] = slot
    _changed()

func equip_relic(id: StringName) -> bool:
    if ContentRegistry.get_item("relics", id).is_empty(): return false
    var build := ensure_build()
    var list: Array = build.get("relics", [])
    if not list.has(String(id)): list.append(String(id))
    build["relics"] = list
    _changed(); return true

func set_daimon(id: StringName) -> bool:
    if ContentRegistry.get_item("daimones", id).is_empty(): return false
    ensure_build()["daimon"] = String(id)
    _changed(); return true

func add_mutation(id: StringName) -> bool:
    var exists := false
    for power in ContentRegistry.all("powers"):
        for mutation in power.get("mutations", []):
            if String(mutation.get("id", "")) == String(id):
                exists = true
                break
        if exists: break
    if not exists: return false
    var list: Array = ensure_build().get("mutations", [])
    if not list.has(String(id)): list.append(String(id))
    ensure_build()["mutations"] = list
    _changed(); return true

func set_route(id: StringName) -> bool:
    if ContentRegistry.get_item("routes", id).is_empty(): return false
    GameState.route_state["route"] = String(id)
    ensure_build()["route"] = String(id)
    _changed(); return true

func _dispatch_arcana(effect: StringName, card: Dictionary, context: Dictionary) -> void:
    match String(effect):
        "threshold_reset": effect_requested.emit(effect, {"action":"return_last_clear", "focus":18, "card":card, "context":context})
        "echo_instrument": effect_requested.emit(effect, {"action":"double_next_instrument", "card":card, "context":context})
        "secret_sight": effect_requested.emit(effect, {"action":"reveal_secrets", "card":card, "context":context})
        "fecundity": effect_requested.emit(effect, {"action":"heal_and_reward", "heal":24, "essence":2, "card":card, "context":context})
        "command": effect_requested.emit(effect, {"action":"interrupt_and_guard", "duration":3.0, "card":card, "context":context})
        "tradition": effect_requested.emit(effect, {"action":"codex_to_guard", "card":card, "context":context})
        "syzygy": effect_requested.emit(effect, {"action":"fuse_talisman_instrument", "card":card, "context":context})
        "chariot": effect_requested.emit(effect, {"action":"invulnerable_dash", "duration":1.2, "card":card, "context":context})
        "adjustment": effect_requested.emit(effect, {"action":"rebalance_resources_cleanse", "card":card, "context":context})
        "hermit": effect_requested.emit(effect, {"action":"open_hidden_choice", "card":card, "context":context})
        "fortune": effect_requested.emit(effect, {"action":"reroll_reward", "essence":2, "card":card, "context":context})
        "lust": effect_requested.emit(effect, {"action":"aggression_streak", "duration":10.0, "card":card, "context":context})
        "suspension": effect_requested.emit(effect, {"action":"phase_then_slow", "duration":2.2, "card":card, "context":context})
        "death": effect_requested.emit(effect, {"action":"execute_and_weaken", "threshold":0.28, "card":card, "context":context})
        "art": effect_requested.emit(effect, {"action":"fuse_consumable_instrument", "card":card, "context":context})
        "devil": effect_requested.emit(effect, {"action":"max_hp_for_damage", "max_hp_cost":12, "damage_mult":1.28, "card":card, "context":context})
        "tower": effect_requested.emit(effect, {"action":"ritual_explosion", "damage":72, "break_secrets":true, "card":card, "context":context})
        "star": effect_requested.emit(effect, {"action":"reveal_goal_precision", "duration":12.0, "card":card, "context":context})
        "moon": effect_requested.emit(effect, {"action":"reveal_secret_add_threat", "card":card, "context":context})
        "sun": effect_requested.emit(effect, {"action":"heal_reveal_room_damage", "heal":30, "damage":46, "card":card, "context":context})
        "aeon": effect_requested.emit(effect, {"action":"alter_floor_rule", "card":card, "context":context})
        "universe": effect_requested.emit(effect, {"action":"open_exceptional_connection", "heal":18, "essence":3, "card":card, "context":context})
        _:
            effect_requested.emit(effect, {"action":"minor_arcana", "magnitude":card.get("magnitude", 10), "suit":card.get("suit", ""), "card":card, "context":context})

func _dispatch_instrument(effect: StringName, item: Dictionary, context: Dictionary) -> void:
    var actions := {
        "cone_fire":"damage_cone", "chain_strike":"chain_damage", "solar_burst":"heal_and_reward",
        "tempo_shift":"speed_recharge", "dash_break":"dash_armor_break", "black_flame":"ritual_explosion",
        "focus_well":"restore_focus", "phase":"temporary_intangibility", "heal_link":"heal_and_daimon",
        "transmute_hurt":"damage_memory_to_focus", "curse_cleanse":"remove_curse_then_slow", "return":"return_last_clear",
        "armor_break":"heavy_front_hit", "mark_reveal":"mark_and_reveal_attack", "line_beam":"line_damage",
        "silence":"silence_ranged", "slow_cut":"damage_and_slow", "door_cut":"open_eligible_or_heavy_hit",
        "fortify":"fortify", "ward":"ward", "reroll":"reroll_reward", "anchor":"anchor",
        "multiply_essence":"multiply_essence", "grounding":"grounding", "reflect":"reflect_next_projectile",
        "reveal_all":"reveal_secrets", "command_wave":"interrupt_and_guard", "time_stop":"freeze_room",
        "dominate":"dominate", "precision":"precision", "echo_card":"repeat_last_arcana", "red_path":"open_draconis_connection"
    }
    var action := String(actions.get(String(effect), "instrument_unknown"))
    effect_requested.emit(effect, {"action":action, "item":item, "context":context})

func _changed() -> void:
    build_changed.emit(GameState.run_build.duplicate(true))
