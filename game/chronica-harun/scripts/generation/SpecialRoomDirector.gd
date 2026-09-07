extends RefCounted
class_name SpecialRoomDirector

const MAX_SECRET_ROOMS := 2
const PHYSICAL_SECRET_OPENERS := ["ritual_bomb", "rupture_charge", "wall_break"]

func build_floor_rooms(context: Dictionary, layout_secret_capacity: int, rng_seed: int = 0) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = rng_seed if rng_seed != 0 else int(context.get("seed", 1))
    var tagged := context.duplicate(true)
    tagged["tags"] = _context_tags(context)
    var all_rooms: Array = RogueliteContentService.eligible_entries("special_rooms", tagged)
    var regular: Array = []
    var secrets: Array = []
    for room in all_rooms:
        var role := str(room.get("room_role", "special"))
        if role in ["secret", "super_secret"]: secrets.append(room)
        elif role not in ["postboss", "initiation"]: regular.append(room)
    var selected_regular := _weighted_without_replacement(regular, int(context.get("max_special_rooms", 2)), rng)
    var secret_limit := min(layout_secret_capacity, MAX_SECRET_ROOMS)
    var selected_secrets: Array = []
    if secret_limit > 0:
        var ordered := secrets.duplicate()
        ordered.sort_custom(func(a, b): return float(a["spawn_condition"]["weight"]) > float(b["spawn_condition"]["weight"]))
        for room in ordered:
            if selected_secrets.size() >= secret_limit: break
            if rng.randf() <= float(room["spawn_condition"].get("weight", 0.0)): selected_secrets.append(_as_hidden_room(room))
    return {"special_rooms":selected_regular,"secret_rooms":selected_secrets,"postboss_rooms":choose_postboss_options(tagged),"secret_count":selected_secrets.size()}

func choose_postboss_options(context: Dictionary) -> Array:
    if bool(context.get("postboss_choice_taken", false)): return []
    var tagged := context.duplicate(true); tagged["tags"] = _context_tags(context)
    if not tagged["tags"].has("postboss:cleared"): return []
    var result: Array = []
    for room in RogueliteContentService.eligible_entries("special_rooms", tagged):
        if bool(room.get("postboss", false)) and str(room.get("exclusive_group", "")) == "postboss_path": result.append(room)
    return result

func commit_postboss_choice(room_id: String, run_state: Dictionary) -> Dictionary:
    if bool(run_state.get("postboss_choice_taken", false)): return {"ok":false,"reason":"postboss_choice_already_taken"}
    var room := RogueliteContentService.get_entry(room_id)
    if room.is_empty() or not bool(room.get("postboss", false)): return {"ok":false,"reason":"invalid_postboss_room"}
    var eligible_ids: Array = choose_postboss_options(run_state).map(func(item): return str(item.get("id", "")))
    if not eligible_ids.has(room_id): return {"ok":false,"reason":"postboss_room_not_eligible"}
    run_state["postboss_choice_taken"] = true; run_state["postboss_choice_id"] = room_id
    run_state.get_or_add("visited_rooms", []).append(room_id)
    return {"ok":true,"room":room.duplicate(true)}

func can_open_secret(room: Dictionary, opener_tags: Array) -> bool:
    if str(room.get("room_role", "")) not in ["secret", "super_secret"]: return false
    var accepted: Array = room.get("entry", {}).get("accepted_openers", [])
    for opener in opener_tags:
        if accepted.has(opener) and PHYSICAL_SECRET_OPENERS.has(opener): return true
    return false

func open_secret(room: Dictionary, opener_tags: Array, run_state: Dictionary) -> Dictionary:
    if not can_open_secret(room, opener_tags): return {"ok":false,"reason":"physical_opener_required"}
    var room_id := str(room.get("id", "")); var discovered: Array = run_state.get_or_add("discovered_secrets", [])
    if not discovered.has(room_id): discovered.append(room_id)
    return {"ok":true,"room_id":room_id,"feedback":room.get("discovery_feedback", ""),"map_icon":room.get("map_icon", ""),"event":"room.secret_opened"}

func _context_tags(context: Dictionary) -> Array:
    var tags: Array = context.get("tags", []).duplicate()
    if bool(context.get("postboss_cleared", false)) and not tags.has("postboss:cleared"): tags.append("postboss:cleared")
    if str(context.get("journey_state", "")) == "ready_for_initiation" and not tags.has("journey:ready_for_initiation"): tags.append("journey:ready_for_initiation")
    for blessing in context.get("blessings", []):
        var tag := "blessing:%s" % str(blessing).trim_prefix("blessing_")
        if not tags.has(tag): tags.append(tag)
    return tags

func _weighted_without_replacement(records: Array, count: int, rng: RandomNumberGenerator) -> Array:
    var available := records.duplicate(); var result: Array = []
    while not available.is_empty() and result.size() < max(0, count):
        var total := 0.0
        for record in available: total += max(0.0, float(record.get("spawn_condition", {}).get("weight", 0.0)))
        if total <= 0.0: break
        var roll := rng.randf() * total; var cursor := 0.0; var chosen_index := 0
        for index in range(available.size()):
            cursor += max(0.0, float(available[index].get("spawn_condition", {}).get("weight", 0.0)))
            if roll <= cursor: chosen_index = index; break
        result.append(available[chosen_index]); available.remove_at(chosen_index)
    return result

func _as_hidden_room(room: Dictionary) -> Dictionary:
    var hidden := room.duplicate(true)
    hidden["map_visible"] = false; hidden["door_label"] = ""; hidden["discovered"] = false
    return hidden
