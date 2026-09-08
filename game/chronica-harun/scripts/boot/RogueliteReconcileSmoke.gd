extends Node

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    _catalog_contract()
    _generation_eligibility_contract()
    _pickup_buildcraft_contract()
    _transformation_contract()
    _secret_physical_contract()
    _postboss_contract()
    _save_roundtrip_contract()
    if failures.is_empty():
        print("ROGUELITE_RECONCILE_SMOKE_OK")
        get_tree().quit(0)
    else:
        for failure in failures:
            push_error("C2_SMOKE: " + failure)
        get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _catalog_contract() -> void:
    _expect(ContentRegistry.all("tarot").size() == 78, "Tarot must be 78")
    _expect(ContentRegistry.all("sigilla").size() == 72, "Sigilla must be 72")
    _expect(ContentRegistry.all("pharmaka").size() == 21, "Pharmaka must be 21")
    _expect(ContentRegistry.all("talismans").size() == 36, "Talismans must be 36")
    _expect(ContentRegistry.all("instrumenta").size() == 32, "Instrumenta must be 32")
    _expect(ContentRegistry.all("powers").size() == 15, "Power Matrices must be 15")
    var mutation_count := 0
    for power in ContentRegistry.all("powers"):
        mutation_count += power.get("mutations", []).size()
    _expect(mutation_count == 45, "Power mutations must be 45")
    _expect(ContentRegistry.all("daimones").size() == 7, "Daimones must be 7")
    var room_ids := ContentRegistry.all_ids("special_rooms")
    for id in ["arcana","reliquary","instrumentarium","laboratorium","sigillar","market","bibliotheca","speculum","planetary","trial","cursed","secret","super_secret","archon","theophany","historical","initiation","pneumatic","chthonic","pact_table"]:
        _expect(room_ids.has(id), "missing canonical special room: " + id)

func _generation_eligibility_contract() -> void:
    var director := SpecialRoomDirector.new()
    var context := {"stage_id":"o_olho", "rooms_cleared":0, "secret_found":false}
    var generation_ids: Array[String] = []
    for row in director.eligible_rooms(0, 0, context, true): generation_ids.append(String(row.get("id", "")))
    var runtime_ids: Array[String] = []
    for row in director.eligible_rooms(0, 0, context, false): runtime_ids.append(String(row.get("id", "")))
    _expect(generation_ids.has("arcana"), "min_rooms_cleared blocked Arcana generation")
    _expect(not runtime_ids.has("arcana"), "Arcana runtime eligibility ignored min_rooms_cleared")
    _expect(SpecialRoomDirector.MAX_SECRET_ROOMS == 2, "secret room max changed")

func _pickup_buildcraft_contract() -> void:
    GameState.start_new_campaign(777)
    RogueliteContentService.ensure_build()
    var tarot: Dictionary = ContentRegistry.all("tarot")[0]
    var pickup := PickupController.new()
    pickup.category = &"tarot"
    pickup.content_id = StringName(tarot.get("id", ""))
    add_child(pickup)
    _expect(pickup.interact(self), "physical pickup did not grant Tarot")
    _expect(String(GameState.run_build.get("arcana", "")) == String(tarot.get("id", "")), "pickup did not reach build slot")
    _expect(RogueliteContentService.use_arcana({"smoke":true}), "Arcana use failed")
    _expect(String(GameState.run_build.get("arcana", "")).is_empty(), "Arcana was not consumed")

    var pharmakon: Dictionary = ContentRegistry.all("pharmaka")[0]
    _expect(RogueliteContentService.grant("pharmaka", StringName(pharmakon.get("id", ""))), "Pharmakon grant failed")
    _expect(RogueliteContentService.use_pharmakon({"smoke":true}), "Pharmakon use failed")
    _expect(GameState.run_build.get("known_pharmaka", []).has(String(pharmakon.get("id", ""))), "Pharmakon discovery did not persist in build")

    var instrument: Dictionary = ContentRegistry.all("instrumenta")[0]
    _expect(RogueliteContentService.grant("instrumenta", StringName(instrument.get("id", ""))), "Instrumentum grant failed")
    var before := int(GameState.run_build.get("instrumentum", {}).get("charges", 0))
    _expect(before > 0, "Instrumentum has no charges")
    _expect(RogueliteContentService.use_instrumentum({"smoke":true}), "Instrumentum use failed")
    _expect(int(GameState.run_build.get("instrumentum", {}).get("charges", 0)) == before - 1, "Instrumentum charge was not consumed")
    RogueliteContentService.recharge_instrument(1)
    _expect(int(GameState.run_build.get("instrumentum", {}).get("charges", 0)) == before, "Instrumentum recharge failed")

    var talisman: Dictionary = ContentRegistry.all("talismans")[0]
    var relic: Dictionary = ContentRegistry.all("relics")[0]
    var daimon: Dictionary = ContentRegistry.all("daimones")[0]
    _expect(RogueliteContentService.grant("talismans", StringName(talisman.get("id", ""))), "Talisman grant failed")
    _expect(RogueliteContentService.grant("relics", StringName(relic.get("id", ""))), "Relic grant failed")
    _expect(RogueliteContentService.grant("daimones", StringName(daimon.get("id", ""))), "Daimon grant failed")
    var power: Dictionary = ContentRegistry.all("powers")[0]
    var mutation: Dictionary = power.get("mutations", [])[0]
    _expect(RogueliteContentService.add_mutation(StringName(mutation.get("id", ""))), "Mutation grant failed")
    _expect(PowerMutationRuntime.active_effects(GameState.run_build).has(String(mutation.get("effect_id", ""))), "Mutation did not reach runtime")

func _transformation_contract() -> void:
    var transformation: Dictionary = ContentRegistry.all("transformations")[0]
    var probe := RogueliteContentService.ensure_build().duplicate(true)
    var flags: Dictionary = probe.get("flags", {}).duplicate(true)
    for requirement in transformation.get("requires", []): flags[String(requirement)] = true
    probe["flags"] = flags
    var eligible := BuildResolver.eligible_transformations(probe)
    _expect(eligible.has(String(transformation.get("id", ""))), "satisfied transformation requirements never reach runtime")
    var resolved := BuildResolver.resolve(probe)
    _expect(resolved.get("transformations", []).has(String(transformation.get("id", ""))), "resolved build omits eligible transformation")

func _secret_physical_contract() -> void:
    var stage := {"id":"o_olho", "index":0}
    var floor := StageFloorBuilder.build(stage, 445566, 0, {"rooms_cleared":0, "secret_found":false})
    add_child(floor)
    var rooms := floor.get_node("Rooms") as Node3D
    var corridors := floor.get_node("Corridors") as Node3D
    var secret := rooms.get_node_or_null("special_secret") as RoomShell
    if secret == null:
        var by_id: Dictionary = {}
        for child in rooms.get_children():
            if child is RoomShell: by_id[String(child.room_id)] = child
        secret = StageFloorBuilder.spawn_special_room(rooms, ContentRegistry.get_item("special_rooms", &"secret"), 99, by_id, corridors, floor.get_meta("theme", {}))
    _expect(secret != null, "Secret was not physically materialized")
    if secret == null:
        floor.queue_free()
        return
    _expect(not secret.visible, "Secret is visible before rupture")
    _expect(bool(secret.get_meta("secret_connection_pending", false)), "Secret connection is not pending before rupture")
    var corridors_before := corridors.get_child_count()
    var room_director := floor.get_node("RoomDirector") as RoomDirector
    room_director.register_room(secret)
    _expect(room_director.open_secret(&"secret", &"rupture_charge"), "Secret rupture failed")
    _expect(secret.visible, "Secret remained hidden after rupture")
    _expect(not bool(secret.get_meta("secret_connection_pending", true)), "Secret connection remained pending after rupture")
    _expect(corridors.get_child_count() == corridors_before + 1, "Secret corridor did not materialize on rupture")
    var special_director := SpecialRoomDirector.new()
    _expect(not special_director.can_open_secret(&"super_secret", &"rupture_charge", {"rupture_charges":1,"secret_found":false,"cycle":1}), "Super Secret opened without prior Secret")
    _expect(not special_director.can_open_secret(&"super_secret", &"rupture_charge", {"rupture_charges":1,"secret_found":true,"cycle":0}), "Super Secret opened before required cycle")
    _expect(special_director.can_open_secret(&"super_secret", &"rupture_charge", {"rupture_charges":1,"secret_found":true,"cycle":1}), "Super Secret rejected valid rupture")
    floor.queue_free()

func _postboss_contract() -> void:
    GameState.route_state["post_boss_choice"] = ""
    var director := SpecialRoomDirector.new()
    _expect(director.record_post_boss_choice(&"pneumatic"), "Pneumatic post-boss choice rejected")
    _expect(not director.record_post_boss_choice(&"chthonic"), "post-boss mutual exclusivity failed")
    _expect(String(GameState.route_state.get("post_boss_choice", "")) == "pneumatic", "post-boss choice was not persisted")

func _save_roundtrip_contract() -> void:
    GameState.run_stats["secret_found"] = true
    GameState.run_stats["rupture_charges"] = 2
    GameState.route_state["route"] = "route_eye"
    var snapshot := GameState.snapshot_run()
    GameState.run_stats["secret_found"] = false
    GameState.run_stats["rupture_charges"] = 0
    GameState.route_state["route"] = "student"
    _expect(GameState.restore_run(snapshot), "run restore failed")
    _expect(bool(GameState.run_stats.get("secret_found", false)), "secret discovery did not survive restore")
    _expect(int(GameState.run_stats.get("rupture_charges", 0)) == 2, "rupture charges did not survive restore")
    _expect(String(GameState.route_state.get("route", "")) == "route_eye", "alternate route did not survive restore")
