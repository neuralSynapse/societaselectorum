extends Node
class_name MetaRunDirector

signal meta_changed(state: Dictionary)

func set_route(route_id: StringName) -> bool:
    if ContentRegistry.get_item("routes",route_id).is_empty(): return false
    GameState.route_state["route"] = String(route_id)
    GameState.run_build["route"] = String(route_id)
    _changed(); return true

func add_curse(curse_id: StringName) -> bool:
    if ContentRegistry.get_item("curses",curse_id).is_empty(): return false
    var list: Array = GameState.route_state.get("curses",[])
    if not list.has(String(curse_id)): list.append(String(curse_id))
    GameState.route_state["curses"] = list; _changed(); return true

func add_blessing(blessing_id: StringName) -> bool:
    if ContentRegistry.get_item("blessings",blessing_id).is_empty(): return false
    var list: Array = GameState.route_state.get("blessings",[])
    if not list.has(String(blessing_id)): list.append(String(blessing_id))
    GameState.route_state["blessings"] = list; _changed(); return true

func record_completion_mark(mark_id: StringName, character_id: StringName = GameState.selected_character_id) -> void:
    var key := String(character_id)
    if not GameState.completion_marks_by_character.has(key): GameState.completion_marks_by_character[key] = {}
    GameState.completion_marks_by_character[key][String(mark_id)] = true
    _changed()

func unlock_gauntlet(gauntlet_id: StringName) -> bool:
    var row := ContentRegistry.get_item("gauntlets",gauntlet_id)
    if row.is_empty(): return false
    if not _conditions_met(row.get("unlock_conditions",{})): return false
    var unlocked: Array = GameState.meta_progression.get("unlocked_gauntlets",[])
    if not unlocked.has(String(gauntlet_id)): unlocked.append(String(gauntlet_id))
    GameState.meta_progression["unlocked_gauntlets"] = unlocked
    _changed(); return true

func start_gauntlet(gauntlet_id: StringName) -> bool:
    var row := ContentRegistry.get_item("gauntlets",gauntlet_id)
    if row.is_empty(): return false
    var current := String(GameState.route_state.get("gauntlet", ""))
    if bool(GameState.route_state.get("gauntlet_active", false)):
        return current == String(gauntlet_id)
    var unlocked: Array = GameState.meta_progression.get("unlocked_gauntlets", [])
    if not unlocked.has(String(gauntlet_id)) and not unlock_gauntlet(gauntlet_id):
        return false
    GameState.route_state["gauntlet"] = String(gauntlet_id)
    GameState.route_state["gauntlet_active"] = true
    GameState.route_state["gauntlet_rooms_cleared"] = 0
    GameState.run_stats["gauntlet_rooms_cleared"] = 0
    _changed()
    return true

func record_gauntlet_room_clear() -> int:
    if not bool(GameState.route_state.get("gauntlet_active", false)):
        return 0
    var count := int(GameState.route_state.get("gauntlet_rooms_cleared", 0)) + 1
    GameState.route_state["gauntlet_rooms_cleared"] = count
    GameState.run_stats["gauntlet_rooms_cleared"] = count
    _changed()
    return count

func complete_gauntlet() -> bool:
    if not bool(GameState.route_state.get("gauntlet_active", false)):
        return false
    var gauntlet_id := String(GameState.route_state.get("gauntlet", ""))
    var row := ContentRegistry.get_item("gauntlets", StringName(gauntlet_id))
    if row.is_empty(): return false
    var mark := String(row.get("completion_mark", ""))
    if not mark.is_empty():
        var character_key := String(GameState.selected_character_id)
        if not GameState.completion_marks_by_character.has(character_key):
            GameState.completion_marks_by_character[character_key] = {}
        GameState.completion_marks_by_character[character_key][mark] = true
    var completed: Array = GameState.meta_progression.get("completed_gauntlets", [])
    if not completed.has(gauntlet_id): completed.append(gauntlet_id)
    GameState.meta_progression["completed_gauntlets"] = completed
    GameState.meta_progression["gauntlets_completed"] = completed.size()
    GameState.route_state["gauntlet_active"] = false
    _changed()
    return true

func apply_floor_modifiers() -> Dictionary:
    var out := {"enemy_budget_delta":0,"telegraph_mult":1.0,"drop_mult":1.0,"map_hidden":false,"damage_mult":1.0}
    for curse_id in GameState.route_state.get("curses",[]):
        match String(curse_id):
            "scarcity": out.drop_mult *= .7
            "labyrinth": out.map_hidden = true
            "hostile_echo": out.enemy_budget_delta += 1
            "ritual_blindness": out.telegraph_mult *= .9
    for blessing_id in GameState.route_state.get("blessings",[]):
        match String(blessing_id):
            "lucifer_glow": out.damage_mult += .08
            "horus_eye": out.telegraph_mult *= 1.08
            "belial_order": out.enemy_budget_delta -= 1
    var gauntlet := String(GameState.route_state.get("gauntlet",""))
    if not gauntlet.is_empty() and bool(GameState.route_state.get("gauntlet_active", true)):
        var g := ContentRegistry.get_item("gauntlets",StringName(gauntlet))
        for modifier in g.get("modifiers",[]):
            if modifier == "elite_budget_plus_one": out.enemy_budget_delta += 1
            elif modifier == "no_map": out.map_hidden = true
            elif modifier == "boss_phase_speed_plus": out.telegraph_mult *= .88
    return out

func _conditions_met(conditions: Dictionary) -> bool:
    for key in conditions:
        var expected = conditions[key]
        var actual = GameState.meta_progression.get(key,GameState.route_state.get(key,null))
        if expected is bool:
            if bool(actual) != expected: return false
        elif expected is int or expected is float:
            if actual == null or float(actual) < float(expected): return false
        else:
            if String(actual) != String(expected): return false
    return true

func _changed() -> void:
    meta_changed.emit(GameState.to_save_data())
