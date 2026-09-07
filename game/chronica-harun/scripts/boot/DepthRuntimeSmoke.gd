extends Node
class_name DepthRuntimeSmoke

const SMOKE_SAVE_PATH := "user://depth_runtime_smoke.json"

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_smoke")

func _run_smoke() -> void:
    GameState.reset_run(93093)
    if not RogueliteContentService.load_all():
        _fail("content service failed: %s" % ", ".join(RogueliteContentService.load_errors))
    _prime_resources()
    _exercise_buildcraft()
    _exercise_secret_and_special_room()
    _exercise_meta_run()
    _exercise_save_load()
    if failures.is_empty():
        print("DEPTH_RUNTIME_SMOKE_OK")
        get_tree().quit(0)
        return
    for failure in failures:
        push_error("DEPTH_RUNTIME_SMOKE_FAILURE: %s" % failure)
    get_tree().quit(1)

func _prime_resources() -> void:
    var resources: Dictionary = GameState.run_state.get("resources", {})
    for key in ["hp", "max_hp", "focus", "essence", "rupture", "coins", "matter", "blood", "memory"]:
        resources[key] = 9999.0
    GameState.run_state["resources"] = resources

func _exercise_buildcraft() -> void:
    var resolver := BuildResolver.new()
    for pool_name in ["tarot", "sigilla", "instrumenta"]:
        var entries := RogueliteContentService.get_pool(pool_name)
        if entries.is_empty():
            _fail("missing runtime pool: %s" % pool_name)
            continue
        var entry: Dictionary = entries[0]
        var cost: Dictionary = entry.get("cost", {})
        var resources: Dictionary = GameState.run_state.get("resources", {}).duplicate(true)
        var cost_resource := str(cost.get("resource", "none"))
        var cost_amount := float(cost.get("amount", 0))
        if cost_resource != "none":
            resources[cost_resource] = max(float(resources.get(cost_resource, 0)), cost_amount + 100.0)
        var context := {
            "owned_ids": GameState.run_state.get("inventory", []).duplicate(),
            "tags": GameState.run_state.get("build_tags", []).duplicate(),
            "resources": resources,
            "active_effects": GameState.run_state.get("active_effects", {}).duplicate(true)
        }
        var resolution := resolver.resolve(entry, context)
        var blocked: Array = resolution.get("blocked_by", [])
        if not blocked.is_empty():
            _fail("%s did not dispatch: %s" % [pool_name, str(blocked)])

func _exercise_secret_and_special_room() -> void:
    var director := SpecialRoomDirector.new()
    var rooms := RogueliteContentService.get_pool("special_rooms")
    var secret_room: Dictionary = {}
    var playable_room: Dictionary = {}
    for room in rooms:
        var role := str(room.get("room_role", "special"))
        if secret_room.is_empty() and ["secret", "super_secret"].has(role):
            secret_room = room
        if playable_room.is_empty() and not ["secret", "super_secret", "postboss", "initiation"].has(role):
            playable_room = room
    if secret_room.is_empty():
        _fail("no secret room available")
    else:
        var accepted: Array = secret_room.get("entry", {}).get("accepted_openers", [])
        var opener := ""
        for candidate in ["ritual_bomb", "rupture_charge", "wall_break"]:
            if accepted.has(candidate):
                opener = candidate
                break
        if opener == "":
            _fail("secret room has no physical opener")
        else:
            var opened := director.open_secret(secret_room, [opener], GameState.run_state)
            if not bool(opened.get("ok", false)):
                _fail("open_secret rejected physical opener")
    if playable_room.is_empty():
        _fail("no playable special room available")
        return
    _fund_entry_cost(playable_room)
    var runtime := SpecialRoomRuntime.new()
    add_child(runtime)
    runtime.configure(playable_room)
    var entered := runtime.enter_room(GameState.run_state)
    if not bool(entered.get("ok", false)):
        _fail("enter_room failed: %s" % str(entered.get("reason", "unknown")))
    runtime.queue_free()

func _exercise_meta_run() -> void:
    var meta := MetaRunDirector.new()
    var routes := RogueliteContentService.get_pool("routes")
    if routes.is_empty():
        _fail("routes pool is empty")
    else:
        var route_result := meta.select_route(str(routes[0].get("id", "")), GameState.run_state)
        if not bool(route_result.get("ok", false)):
            _fail("route selection failed")
    var curses := RogueliteContentService.get_pool("curses")
    if not curses.is_empty():
        var curse_result := meta.apply_curse(str(curses[0].get("id", "")), GameState.run_state)
        if not bool(curse_result.get("ok", false)):
            _fail("curse application failed")
    var blessings := RogueliteContentService.get_pool("blessings")
    if not blessings.is_empty():
        var blessing_result := meta.apply_blessing(str(blessings[0].get("id", "")), GameState.run_state)
        if not bool(blessing_result.get("ok", false)):
            _fail("blessing application failed")
    var transformations := RogueliteContentService.get_pool("transformations")
    if transformations.is_empty():
        _fail("transformations pool is empty")
    else:
        var transformation: Dictionary = transformations[0]
        var effect: Dictionary = transformation.get("effect", {})
        var required: Array = effect.get("required_tags", [])
        for tag in required:
            GameState.add_build_tag(str(tag))
        var unlocked := meta.evaluate_transformations(GameState.run_state)
        var threshold := int(effect.get("threshold", required.size()))
        if threshold <= required.size() and unlocked.is_empty():
            _fail("evaluate_transformations did not unlock an eligible transformation")
    var completion := meta.record_completion("harun", "depth_runtime_smoke", GameState.run_state)
    if not bool(completion.get("ok", false)):
        _fail("completion mark failed")
    var gauntlets := RogueliteContentService.get_pool("gauntlets")
    if not gauntlets.is_empty():
        var gauntlet_result := meta.start_gauntlet(str(gauntlets[0].get("id", "")), GameState.run_state)
        if not bool(gauntlet_result.get("ok", false)):
            _fail("gauntlet start failed")

func _exercise_save_load() -> void:
    GameState.run_state["stage_index"] = 3
    var expected_stage := int(GameState.run_state["stage_index"])
    if not GameState.save_run(SMOKE_SAVE_PATH):
        _fail("save_run failed")
        return
    GameState.run_state["stage_index"] = 999
    if not GameState.load_run(SMOKE_SAVE_PATH):
        _fail("load_run failed")
        return
    if int(GameState.run_state.get("stage_index", -1)) != expected_stage:
        _fail("save/load roundtrip did not restore stage_index")

func _fund_entry_cost(room: Dictionary) -> void:
    var cost: Dictionary = room.get("cost", {})
    var resource := str(cost.get("resource", "none"))
    if resource == "none":
        return
    var amount := float(cost.get("amount", 0))
    var resources: Dictionary = GameState.run_state.get("resources", {})
    resources[resource] = max(float(resources.get(resource, 0)), amount + 100.0)
    GameState.run_state["resources"] = resources

func _fail(message: String) -> void:
    failures.append(message)
