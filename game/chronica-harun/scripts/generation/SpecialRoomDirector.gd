extends RefCounted
class_name SpecialRoomDirector

const MAX_SECRET_ROOMS = 2
const LEGACY_POST_BOSS_ALIASES := {"solar_benediction":"pneumatic", "chthonic_pact":"chthonic"}

var definitions: Array = []

func _init() -> void:
    definitions = ContentRegistry.all("special_rooms") if Engine.is_editor_hint() == false and ContentRegistry != null else _load_definitions()
    if definitions.is_empty(): definitions = _load_definitions()

func _load_definitions() -> Array:
    var file := FileAccess.open("res://data/roguelite/special_rooms.json", FileAccess.READ)
    if file == null: return []
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Array else []

func eligible_rooms(stage_index: int, cycle: int, context: Dictionary) -> Array:
    var out: Array = []
    for room in definitions:
        if stage_index < int(room.get("min_stage",0)): continue
        var eligibility: Dictionary = room.get("eligibility",{})
        if eligibility.has("stage_id") and String(eligibility.stage_id) != String(context.get("stage_id","")): continue
        if int(context.get("rooms_cleared",0)) < int(eligibility.get("min_rooms_cleared",0)): continue
        if cycle < int(eligibility.get("min_cycle",0)): continue
        if eligibility.get("requires_secret_found",false) and not context.get("secret_found",false): continue
        if eligibility.has("requires_codex_entries") and int(context.get("codex_entries",0)) < int(eligibility.requires_codex_entries): continue
        if eligibility.get("requires_no_hostile_echo",false) and context.get("hostile_echo",false): continue
        if String(room.get("exclusive_group", "")) == "postboss_path" and not String(context.get("post_boss_choice","")).is_empty(): continue
        out.append(room)
    return out

func roll_floor_rooms(stage_index: int, cycle: int, context: Dictionary, seed: int) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed + stage_index * 1009 + cycle * 9176
    var rolled: Array = []
    for room in eligible_rooms(stage_index, cycle, context):
        if String(room.get("exclusive_group", "")) == "postboss_path" or room.id == "initiation": continue
        var chance := float(room.get("base_chance",0.0))
        if room.id == "secret": chance = minf(.95, chance + cycle*.025)
        if room.id == "super_secret" and context.get("secret_found",false): chance += .08
        if rng.randf() <= chance:
            rolled.append(room)
    # Prevent special-room soup. Cap ordinary opportunities by stage depth.
    var cap := 2 + mini(3, stage_index / 4) + (1 if cycle >= 4 else 0)
    rolled.shuffle()
    return rolled.slice(0, mini(cap, rolled.size()))

func choose_post_boss_room(context: Dictionary, seed: int) -> StringName:
    if not String(context.get("post_boss_choice", "")).is_empty(): return &""
    var candidates: Array = []
    for room in eligible_rooms(int(context.get("stage_index", 0)), int(context.get("cycle", 0)), context):
        if String(room.get("exclusive_group", "")) == "postboss_path": candidates.append(room)
    if candidates.is_empty(): return &""
    var rng := RandomNumberGenerator.new(); rng.seed = seed + 7331
    var total := 0.0
    for room in candidates: total += float(room.get("base_chance", .33))
    var roll := rng.randf() * maxf(total, .001)
    var acc := 0.0
    for room in candidates:
        acc += float(room.get("base_chance", .33))
        if roll <= acc: return StringName(room.get("id", ""))
    return StringName(candidates.back().get("id", ""))

func record_post_boss_choice(room_id: StringName) -> bool:
    if room_id not in [&"pneumatic", &"chthonic", &"pact_table"]: return false
    if not String(GameState.route_state.get("post_boss_choice","")).is_empty(): return false
    GameState.route_state["post_boss_choice"] = String(room_id)
    GameState.run_stats["post_boss_choice"] = String(room_id)
    return true

func can_open_secret(room_id: StringName, resource_id: StringName, context: Dictionary) -> bool:
    if room_id == &"secret":
        return resource_id == &"rupture_charge" and int(context.get("rupture_charges",0)) >= 1
    if room_id == &"super_secret":
        return resource_id == &"rupture_charge" and int(context.get("rupture_charges",0)) >= 1 and context.get("secret_found",false) and int(context.get("cycle",0)) >= 1
    return false
