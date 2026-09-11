extends RefCounted
class_name InitiaticProgressionService

const PATH_KEY := "initiatic_path"
const PHASE_PORTAL_0 := "PORTAL_0_ASPIRANTE"
const PHASE_STUDENT := "STUDENT"
const PHASE_DEGREE := "DEGREE"
const TREE_DRACONIS := "ARBOR_DRACONIS"

static func path() -> Dictionary:
    return ContentRegistry.get_initiatic_path()

static func phase_for_legacy_stage(stage_index: int) -> String:
    if stage_index <= 2:
        return PHASE_PORTAL_0
    if stage_index <= 14:
        return PHASE_STUDENT
    return "INITIATION_BRIDGE"

static func current_phase_label() -> String:
    if String(GameState.journey_state) == PHASE_DEGREE:
        var row := current_degree_row()
        if row.is_empty():
            return "GRAUS"
        return "GRAU %s · %s" % [String(row.get("roman", "")), String(row.get("title", ""))]
    var phase := phase_for_legacy_stage(GameState.stage_index)
    if phase == PHASE_PORTAL_0:
        return "PORTAL 0 · ASPIRANTE — INITIATIO LUCIFERI"
    if phase == PHASE_STUDENT:
        return "ESTUDANTE"
    return "CÂMARA DE INICIAÇÃO"

static func current_degree() -> int:
    return clampi(int(GameState.meta_progression.get("degree_current", 0)), 0, 33)

static func degree_completed() -> int:
    return clampi(int(GameState.meta_progression.get("degree_completed", 0)), 0, 33)

static func current_degree_row() -> Dictionary:
    var degree := current_degree()
    if degree <= 0:
        return {}
    return degree_row(degree)

static func degree_row(degree: int) -> Dictionary:
    for row_value in path().get("degrees", []):
        if row_value is Dictionary:
            var row: Dictionary = row_value
            if int(row.get("degree", 0)) == degree:
                return row
    return {}

static func visible_degrees() -> Array:
    var result: Array = []
    var completed := degree_completed()
    for row_value in path().get("degrees", []):
        if not (row_value is Dictionary):
            continue
        var row: Dictionary = row_value
        var hidden_until_degree := int(row.get("hidden_until_degree", 0))
        if String(row.get("tree", "")) == TREE_DRACONIS and completed < hidden_until_degree:
            continue
        result.append(row)
    return result

static func can_enter_degree(degree: int) -> bool:
    if degree < 1 or degree > 33:
        return false
    var row := degree_row(degree)
    if row.is_empty():
        return false
    var hidden_until_degree := int(row.get("hidden_until_degree", 0))
    if String(row.get("tree", "")) == TREE_DRACONIS and degree_completed() < hidden_until_degree:
        return false
    if degree == 1:
        return bool(GameState.meta_progression.get("student_initiation_completed", false))
    return degree_completed() >= degree - 1

static func begin_degree_path() -> bool:
    if not bool(GameState.meta_progression.get("student_initiation_completed", false)):
        return false
    GameState.journey_state = PHASE_DEGREE
    GameState.meta_progression["degree_current"] = maxi(1, int(GameState.meta_progression.get("degree_current", 1)))
    GameState.current_stage_id = StringName(degree_row(current_degree()).get("id", "grade_01_peregrinus_ignis"))
    return true

static func complete_current_degree() -> Dictionary:
    var degree := current_degree()
    if degree <= 0:
        return {}
    var row := degree_row(degree)
    if row.is_empty():
        return {}
    GameState.meta_progression["degree_completed"] = maxi(degree_completed(), degree)
    var scroll_unlock := int(row.get("scroll_unlock", 0))
    if scroll_unlock > 0:
        var unlocked: Array = GameState.meta_progression.get("advanced_scrolls", [])
        if not unlocked.has(scroll_unlock):
            unlocked.append(scroll_unlock)
        GameState.meta_progression["advanced_scrolls"] = unlocked
    if degree < 33:
        GameState.meta_progression["degree_current"] = degree + 1
        GameState.current_stage_id = StringName(degree_row(degree + 1).get("id", ""))
    else:
        GameState.meta_progression["initiatic_game_complete"] = true
    return {"degree": degree, "scroll_unlock": scroll_unlock, "tree": row.get("tree", "")}

static func build_degree_stage_data(degree: int) -> Dictionary:
    var row := degree_row(degree)
    if row.is_empty():
        return {}
    var enemy_ids := ContentRegistry.all_ids("enemies")
    var boss_ids := ContentRegistry.all_ids("bosses")
    var power_ids := ContentRegistry.all_ids("powers")
    if enemy_ids.is_empty() or boss_ids.is_empty():
        return {}
    var seed := degree * 7919
    var common: Array = []
    for offset in range(3):
        common.append(enemy_ids[abs(seed + offset * 97) % enemy_ids.size()])
    var elite_id := enemy_ids[abs(seed + 431) % enemy_ids.size()]
    var boss_id := boss_ids[abs(seed + 911) % boss_ids.size()]
    var power_id := ""
    if not power_ids.is_empty():
        power_id = String(power_ids[abs(seed + 3571) % power_ids.size()])
    var subtitle := String(row.get("tree", "")).replace("ARBOR_", "ARBOR ").replace("_", " ")
    return {
        "id": String(row.get("id", "grade_%02d" % degree)),
        "title": "GRAU %s · %s" % [String(row.get("roman", degree)), String(row.get("title", ""))],
        "subtitle": subtitle,
        "degree": degree,
        "tree": row.get("tree", ""),
        "room_theme": row.get("room_theme", "cathedral"),
        "enemy_family": row.get("enemy_family", "blind_archon"),
        "boss_family": row.get("boss_family", "blind_archon"),
        "character_encounter": row.get("character_encounter", ""),
        "scroll_unlock": int(row.get("scroll_unlock", 0)),
        "room_budget": row.get("room_budget", [3, 4, 5]),
        "common_enemy_ids": common,
        "elite_id": elite_id,
        "boss_id": boss_id,
        "power_id": power_id,
        "choice_event": {},
        "opening_image": "A arquitetura do Grau se fecha ao redor de Harun.",
        "stage_voiceover": ["Toda passagem cobra uma forma nova de presença."],
        "next_stage": String(degree_row(degree + 1).get("id", "GAME_COMPLETE")) if degree < 33 else "GAME_COMPLETE"
    }

static func journey_snapshot() -> Dictionary:
    return {
        "phase": current_phase_label(),
        "entry_chain": String(path().get("entry_chain", "Portal 0 · Aspirante — Initiatio Luciferi → Estudante → I · Peregrinus Ignis")),
        "legacy_stage_index": GameState.stage_index,
        "degree_current": current_degree(),
        "degree_completed": degree_completed(),
        "visible_degrees": visible_degrees(),
        "advanced_scrolls": GameState.meta_progression.get("advanced_scrolls", [])
    }
