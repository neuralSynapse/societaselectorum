extends RefCounted
class_name MetaRunDirector

func select_route(route_id: String, run_state: Dictionary) -> Dictionary:
    var route := RogueliteContentService.get_entry(route_id)
    if route.is_empty() or str(route.get("pool", "")) != "routes": return {"ok":false,"reason":"unknown_route"}
    var current := str(run_state.get("route_id", ""))
    if current != "" and current != route_id: return {"ok":false,"reason":"route_already_selected","current":current}
    if current == route_id: return {"ok":true,"unchanged":true,"route":route.duplicate(true)}
    run_state["route_id"] = route_id; _merge_tags(run_state, route.get("tags", [])); _append_event(run_state, {"name":"meta.route_selected","route_id":route_id})
    return {"ok":true,"route":route.duplicate(true)}

func apply_curse(curse_id: String, run_state: Dictionary) -> Dictionary:
    return _apply_unique_meta(curse_id, "curses", "curses", run_state, "meta.curse_applied")

func apply_blessing(blessing_id: String, run_state: Dictionary) -> Dictionary:
    return _apply_unique_meta(blessing_id, "blessings", "blessings", run_state, "meta.blessing_applied")

func evaluate_transformations(run_state: Dictionary) -> Array:
    var build_tags: Array = run_state.get("build_tags", []); var active: Array = run_state.get_or_add("transformations", []); var unlocked: Array = []
    for transformation in RogueliteContentService.get_pool("transformations"):
        var effect: Dictionary = transformation.get("effect", {}); var required: Array = effect.get("required_tags", []); var threshold := int(effect.get("threshold", required.size())); var matches := 0
        for tag in required:
            if build_tags.has(tag): matches += 1
        var transformation_id := str(transformation.get("id", ""))
        if matches >= threshold and not active.has(transformation_id):
            active.append(transformation_id); _merge_tags(run_state, transformation.get("tags", [])); _append_event(run_state, {"name":"meta.transformation_unlocked","transformation_id":transformation_id,"visual_hook":effect.get("visual_hook", "")}); unlocked.append(transformation.duplicate(true))
    return unlocked

func record_completion(character_id: String, challenge_id: String, run_state: Dictionary) -> Dictionary:
    var all_marks: Dictionary = run_state.get_or_add("completion_marks", {}); var character_marks: Dictionary = all_marks.get(character_id, {}); var already := bool(character_marks.get(challenge_id, false)); character_marks[challenge_id] = true; all_marks[character_id] = character_marks
    if not already: _append_event(run_state, {"name":"meta.completion_mark","character_id":character_id,"challenge_id":challenge_id})
    return {"ok":true,"new":not already,"character_id":character_id,"challenge_id":challenge_id}

func start_gauntlet(gauntlet_id: String, run_state: Dictionary) -> Dictionary:
    var gauntlet := RogueliteContentService.get_entry(gauntlet_id)
    if gauntlet.is_empty() or str(gauntlet.get("pool", "")) != "gauntlets": return {"ok":false,"reason":"unknown_gauntlet"}
    var current: Dictionary = run_state.get("gauntlet", {})
    if bool(current.get("active", false)): return {"ok":false,"reason":"gauntlet_already_active"}
    run_state["gauntlet"] = {"active":true,"id":gauntlet_id,"rooms_cleared":0,"modifiers":gauntlet.get("effect", {}).get("modifiers", {}).duplicate(true)}; _append_event(run_state, {"name":"meta.gauntlet_started","gauntlet_id":gauntlet_id})
    return {"ok":true,"gauntlet":run_state["gauntlet"].duplicate(true)}

func record_gauntlet_room_clear(run_state: Dictionary) -> Dictionary:
    var current: Dictionary = run_state.get("gauntlet", {})
    if not bool(current.get("active", false)): return {"ok":false,"reason":"no_active_gauntlet"}
    current["rooms_cleared"] = int(current.get("rooms_cleared", 0)) + 1; var target := int(current.get("modifiers", {}).get("room_chain", 1)); var completed := int(current["rooms_cleared"]) >= target
    if completed: current["active"] = false; _append_event(run_state, {"name":"meta.gauntlet_completed","gauntlet_id":current.get("id", "")})
    run_state["gauntlet"] = current; return {"ok":true,"completed":completed,"rooms_cleared":current["rooms_cleared"],"target":target}

func _apply_unique_meta(content_id: String, pool: String, state_key: String, run_state: Dictionary, event_name: String) -> Dictionary:
    var entry := RogueliteContentService.get_entry(content_id)
    if entry.is_empty() or str(entry.get("pool", "")) != pool: return {"ok":false,"reason":"unknown_meta_content"}
    var active: Array = run_state.get_or_add(state_key, [])
    if active.has(content_id): return {"ok":true,"unchanged":true,"entry":entry.duplicate(true)}
    active.append(content_id); _merge_tags(run_state, entry.get("tags", [])); _append_event(run_state, {"name":event_name,"content_id":content_id,"effect":entry.get("effect", {}).duplicate(true)}); return {"ok":true,"entry":entry.duplicate(true)}

func _merge_tags(run_state: Dictionary, new_tags: Array) -> void:
    var build_tags: Array = run_state.get_or_add("build_tags", [])
    for tag in new_tags:
        if not build_tags.has(tag): build_tags.append(tag)

func _append_event(run_state: Dictionary, event: Dictionary) -> void:
    run_state.get_or_add("run_events", []).append(event.duplicate(true))
