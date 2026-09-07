extends Node
class_name StageDirector

signal stage_completed(stage_id: StringName, summary: Dictionary)
signal special_reward_spawned(room_id: StringName, category: StringName, item_id: StringName)

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PICKUP_SCENE := preload("res://scenes/pickups/WorldPickup.tscn")
const BOSS_SCENE := preload("res://scenes/bosses/BossBase.tscn")

var special_rooms := SpecialRoomDirector.new()
var vision_director: VisionDirector
var meta_director: MetaRunDirector
var daimon_runtime: DaimonRuntime
var transformation_director: TransformationDirector
var floor_instance: Node3D
var room_director: RoomDirector
var player: PlayerController
var hud: HUDController
var stage_data: Dictionary = {}
var journey: Array = []
var room_spawned: Dictionary = {}
var active_enemies: Array[Node] = []
var boss: DataBossController
var world_root: Node3D
var ui_root: CanvasLayer
var rupture_charges := 1
var primary_damage := 22.0
var world_expansion: WorldExpansionRuntime

func configure(next_world_root: Node3D, next_ui_root: CanvasLayer) -> void:
    world_root = next_world_root
    ui_root = next_ui_root
    journey = ContentRegistry.get_student_journey()
    if journey.is_empty():
        push_error("Student journey is empty")
        return
    stage_data = journey[clampi(GameState.stage_index, 0, journey.size() - 1)]
    GameState.current_stage_id = StringName(stage_data.get("id", "o_olho"))
    if not GameState.run_stats.has("rupture_charges"):
        GameState.run_stats["rupture_charges"] = 1
    rupture_charges = int(GameState.run_stats.get("rupture_charges", 1))
    _ensure_runtime_directors()
    floor_instance = StageFloorBuilder.build(stage_data, GameState.run_seed, GameState.cycle, _special_context())
    world_root.add_child(floor_instance)
    room_director = floor_instance.get_node("RoomDirector") as RoomDirector
    _register_rooms()
    player = PLAYER_SCENE.instantiate() as PlayerController
    world_root.add_child(player)
    var threshold := _room("threshold")
    player.global_position = threshold.global_position + Vector3(0, 0.15, 0)
    hud = HUD_SCENE.instantiate() as HUDController
    ui_root.add_child(hud)
    hud.bind_player(player)
    hud.set_objective("%s · %s" % [stage_data.get("title", "JORNADA"), stage_data.get("subtitle", "PROVA")])
    _connect_runtime()
    _refresh_transformations()
    daimon_runtime.on_floor_started(_special_context())

func attach_world_expansion(runtime: WorldExpansionRuntime) -> void:
    world_expansion = runtime
    if player:
        player.camera_mode_requested.connect(_on_camera_mode_requested)
        player.kinesis_slot_requested.connect(_on_kinesis_slot_requested)
        world_expansion.camera_modes.mode_changed.connect(func(mode): hud.set_camera_mode(mode))
        hud.set_camera_mode(world_expansion.camera_modes.mode)
        if world_expansion.kinesis.current_loadout().is_empty():
            world_expansion.kinesis.unlock_node(&"liber_vis_psychicae:kinetic_focus")
            world_expansion.kinesis.equip_ability(&"telekinesis", 0)
            world_expansion.kinesis.equip_ability(&"electrokinesis", 1)
            world_expansion.kinesis.equip_ability(&"pyrokinesis", 2)
        hud.set_kinesis_loadout(world_expansion.kinesis.current_loadout())

func _on_camera_mode_requested() -> void:
    if world_expansion and world_expansion.camera_modes:
        world_expansion.camera_modes.toggle_mode()

func _on_kinesis_slot_requested(slot: int) -> void:
    if world_expansion == null: return
    var loadout := world_expansion.kinesis.current_loadout()
    if slot < 0 or slot >= loadout.size() or String(loadout[slot]).is_empty(): return
    var ability_id := StringName(loadout[slot])
    var payload := world_expansion.kinesis.use_ability(ability_id, player, {"stage_id":String(GameState.current_stage_id)})
    if payload.is_empty():
        hud.show_message("KINESIS INDISPONÍVEL")
        return
    _apply_kinesis(ability_id, payload)

func _apply_kinesis(ability_id: StringName, payload: Dictionary) -> void:
    var magnitude := float(payload.get("magnitude", 1.0))
    match String(ability_id):
        "telekinesis", "aerokinesis":
            for enemy in active_enemies:
                if is_instance_valid(enemy):
                    var d := enemy.global_position - player.global_position; d.y = 0.0
                    if d.length() <= 7.0 and enemy is CharacterBody3D: (enemy as CharacterBody3D).velocity += d.normalized() * (4.0 + magnitude * 3.0)
        "electrokinesis":
            var hits := 0
            for enemy in active_enemies:
                if is_instance_valid(enemy) and hits < 4:
                    enemy.apply_damage(12.0 + magnitude * 10.0, &"electrokinesis"); hits += 1
        "pyrokinesis":
            for enemy in active_enemies:
                if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) <= 6.0: enemy.apply_damage(18.0 + magnitude * 12.0, &"pyrokinesis")
        "geokinesis": player.shield += 12.0 + magnitude * 8.0
        "cryokinesis", "hydrokinesis":
            for enemy in active_enemies:
                if is_instance_valid(enemy) and enemy.get("move_speed") != null: enemy.set("move_speed", maxf(.8, float(enemy.get("move_speed")) * .55))
        "biokinesis": player.heal(10.0 + magnitude * 8.0); player.stamina = player.max_stamina
        "sonokinesis":
            for enemy in active_enemies:
                if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) <= 8.0: enemy.apply_damage(8.0 + magnitude * 6.0, &"sonokinesis")
        "luminokinesis":
            var target := player.get_aim_target()
            if target and target.has_method("apply_damage"): target.apply_damage(28.0 + magnitude * 12.0, &"luminokinesis")
        "technokinesis":
            GameState.run_stats["rupture_charges"] = int(GameState.run_stats.get("rupture_charges", 0)) + 1
    hud.show_message(String(ability_id).replace("_", " ").to_upper())
    AudioDirector.play_ui(&"power_reveal")

func _ensure_runtime_directors() -> void:
    vision_director = VisionDirector.new()
    vision_director.name = "VisionDirector"
    add_child(vision_director)
    meta_director = MetaRunDirector.new()
    meta_director.name = "MetaRunDirector"
    add_child(meta_director)
    daimon_runtime = DaimonRuntime.new()
    daimon_runtime.name = "DaimonRuntime"
    add_child(daimon_runtime)
    transformation_director = TransformationDirector.new()
    transformation_director.name = "TransformationDirector"
    add_child(transformation_director)

func _connect_runtime() -> void:
    room_director.room_entered.connect(_on_room_entered)
    room_director.room_cleared.connect(_on_room_cleared)
    room_director.secret_opened.connect(_on_secret_opened)
    player.primary_attack_requested.connect(_on_primary_attack)
    player.power_requested.connect(_on_power_requested)
    player.instrument_requested.connect(_on_instrument_requested)
    player.consume_requested.connect(_on_consume_requested)
    player.rupture_charge_requested.connect(_on_rupture_charge_requested)
    player.died.connect(_on_player_died)
    RogueliteContentService.build_changed.connect(func(_build): _refresh_transformations(); hud.refresh_build())
    RogueliteContentService.effect_requested.connect(_on_content_effect)
    daimon_runtime.daimon_action.connect(_on_daimon_action)
    vision_director.vision_requested.connect(func(entry): hud.show_message("VISÃO · %s" % entry.get("name", "PRESENÇA"), 3.5))

func _register_rooms() -> void:
    var rooms := floor_instance.get_node("Rooms")
    for child in rooms.get_children():
        if child is RoomShell:
            room_director.register_room(child)

func _room(id: String) -> RoomShell:
    var direct := floor_instance.get_node_or_null("Rooms/" + id) as RoomShell
    if direct:
        return direct
    return floor_instance.get_node_or_null("Rooms/special_" + id) as RoomShell

func _on_room_entered(room_id: StringName) -> void:
    var id := String(room_id)
    if id.begins_with("combat_") and not room_spawned.has(id):
        _spawn_combat_room(id)
    elif id == "trial" and not room_spawned.has(id):
        _spawn_elite_room(id)
    elif id == "boss" and boss == null:
        _spawn_boss()
    elif ContentRegistry.get_item("special_rooms", room_id):
        _activate_special_room(room_id)

func _spawn_combat_room(room_id: String) -> void:
    room_spawned[room_id] = true
    var room := _room(room_id)
    if room == null:
        return
    var index := maxi(0, int(room_id.trim_prefix("combat_")) - 1)
    var budgets: Array = stage_data.get("room_budget", [1, 2, 3])
    var base_budget := int(budgets[mini(index, budgets.size() - 1)])
    var modifiers := meta_director.apply_floor_modifiers()
    var budget := clampi(base_budget + int(modifiers.get("enemy_budget_delta", 0)) + GameState.cycle / 4, 1, 5)
    var ids: Array = stage_data.get("common_enemy_ids", [])
    var anchors := room.get_node("SpawnAnchors").get_children()
    for i in range(budget):
        var enemy_id := StringName(ids[(i + index) % ids.size()])
        var enemy := EnemyFactory.spawn(enemy_id, room, (anchors[i % anchors.size()] as Marker3D).position, player)
        if enemy == null:
            continue
        enemy.identified.connect(_on_enemy_identified)
        enemy.died.connect(func(_source = &""): _on_enemy_killed(enemy))
        room_director.register_enemy(StringName(room_id), enemy)
        active_enemies.append(enemy)

func _spawn_elite_room(room_id: String) -> void:
    room_spawned[room_id] = true
    var room := _room(room_id)
    if room == null:
        return
    var anchor := room.get_node("SpawnAnchors/Spawn2") as Marker3D
    var enemy := EnemyFactory.spawn(StringName(stage_data.get("elite_id", "")), room, anchor.position, player)
    if enemy:
        enemy.role = "elite"
        enemy.identified.connect(_on_enemy_identified)
        enemy.died.connect(func(_source = &""): _on_enemy_killed(enemy))
        room_director.register_enemy(StringName(room_id), enemy)
        active_enemies.append(enemy)

func _spawn_boss() -> void:
    var room := _room("boss")
    if room == null:
        return
    boss = BOSS_SCENE.instantiate() as DataBossController
    boss.configure(StringName(stage_data.get("boss_id", "blind_observer")), player)
    room.add_child(boss)
    boss.position = Vector3(0, 0.1, 0)
    boss.phase_changed.connect(_on_boss_phase)
    boss.boss_defeated.connect(_on_boss_defeated)
    room_director.register_enemy(&"boss", boss)
    hud.show_boss(boss.display_name, 1.0, 1)

func _on_primary_attack() -> void:
    if player.primary_cooldown > 0.0:
        return
    player.primary_cooldown = 0.32
    var target := player.get_aim_target()
    if target == null or not target.has_method("apply_damage"):
        return
    var hp_ratio := 1.0
    if target.get("health") is Health:
        hp_ratio = (target.get("health") as Health).ratio()
    var damage := PowerMutationRuntime.modify_damage(primary_damage, {"target_hp_ratio": hp_ratio, "revealed": target.has_meta("revealed_until")})
    target.apply_damage(damage, &"player_primary")

func _on_power_requested() -> void:
    var power_id := StringName(stage_data.get("power_id", ""))
    if power_id == &"":
        return
    if not player.spend_focus(20.0):
        hud.show_message("FOCO INSUFICIENTE")
        return
    var power := ContentRegistry.get_power(power_id)
    _apply_power(String(power.get("effect_id", power_id)))

func _apply_power(effect_id: String) -> void:
    match effect_id:
        "revelatory_eye", "revelatory_eye_base":
            for enemy in active_enemies:
                if is_instance_valid(enemy): enemy.set_meta("revealed_until", Time.get_ticks_msec() + 6000)
            hud.show_message("OLHO REVELATÓRIO · O OCULTO SE TORNA LEGÍVEL")
        "black_flame_matrix_base":
            for enemy in active_enemies:
                if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) <= 5.5:
                    enemy.apply_damage(20.0, &"black_flame")
        _:
            hud.show_message(String(effect_id).replace("_", " ").to_upper())
    AudioDirector.play_ui(&"power_reveal")

func _on_instrument_requested() -> void:
    if RogueliteContentService.use_instrumentum({"player": player, "stage_id": String(GameState.current_stage_id)}):
        hud.show_message("INSTRUMENTUM ATIVADO")

func _on_consume_requested() -> void:
    var build := RogueliteContentService.ensure_build()
    if not String(build.get("pharmakon", "")).is_empty():
        if RogueliteContentService.use_pharmakon({"player": player}): hud.show_message("PHARMAKON CONSUMIDO")
    elif not String(build.get("arcana", "")).is_empty():
        var card := StringName(build.get("arcana", ""))
        if RogueliteContentService.use_arcana({"player": player, "stage_id": String(GameState.current_stage_id)}):
            daimon_runtime.on_arcana_used(card, {})
            hud.show_message("ARCANO ATIVADO")

func _on_rupture_charge_requested() -> void:
    if rupture_charges <= 0:
        hud.show_message("SEM CARGAS DE RUPTURA")
        return
    var opened := false
    for id in [&"secret", &"super_secret"]:
        var secret := _room(String(id))
        if secret == null or secret.visible:
            continue
        if player.global_position.distance_to(secret.global_position) <= 9.0 and open_secret(id, rupture_charges):
            rupture_charges -= 1
            GameState.run_stats["rupture_charges"] = rupture_charges
            room_director.open_secret(id, &"rupture_charge")
            AudioDirector.play_3d(&"secret_break", player.global_position)
            opened = true
            break
    if not opened:
        hud.show_message("A RUPTURA NÃO ENCONTROU UMA FENDA")

func _on_room_cleared(room_id: StringName) -> void:
    GameState.run_stats["rooms_cleared"] = int(GameState.run_stats.get("rooms_cleared", 0)) + 1
    if world_expansion:
        var expansion_result := world_expansion.on_room_cleared(room_id, _special_context())
        if bool(expansion_result.get("quantum_hint", false)): hud.show_message("UM PADRÃO IMPOSSÍVEL INSISTE EM SE REPETIR", 3.0)
    var mutation := PowerMutationRuntime.on_room_cleared({"damage_taken": float(GameState.run_stats.get("damage_taken", 0.0)) > 0.0})
    player.heal(float(mutation.get("heal", 0.0)))
    player.restore_focus(float(mutation.get("focus", 0.0)))
    player.add_essence(int(mutation.get("essence", 0)))
    if int(mutation.get("charges", 0)) > 0:
        RogueliteContentService.recharge_instrument(int(mutation.get("charges", 0)))
    if String(room_id) == "combat_1":
        _spawn_pickup(_room("reward_1"), "tarot")
    elif String(room_id) == "combat_2":
        _spawn_pickup(_room("sanctuary"), "instrumenta")
    elif String(room_id) == "combat_3":
        _spawn_pickup(_room("combat_3"), "relics")

func _activate_special_room(room_id: StringName) -> void:
    var definition := ContentRegistry.get_item("special_rooms", room_id)
    if definition.is_empty(): return
    var id := String(room_id)
    if id == "theophany":
        var entries := vision_director.eligible_theophanies(_vision_context())
        if not entries.is_empty(): vision_director.trigger_theophany(StringName(entries[0].id), _vision_context())
    elif id == "historical_echo":
        var entries := vision_director.eligible_historical_echoes(_vision_context())
        if not entries.is_empty(): vision_director.trigger_historical_echo(StringName(entries[0].id), _vision_context())
    elif id in ["pneumatic", "chthonic", "pact_table"]:
        if special_rooms.record_post_boss_choice(room_id):
            var category := "blessings" if id == "pneumatic" else ("sigilla" if id == "pact_table" else "curses")
            _spawn_pickup(_room(id), category)
    elif id in ["eden", "arbor_mortis"] and world_expansion:
        if world_expansion.eden_mortis.request_entry(room_id, {"eden_key":int(GameState.meta_progression.get("eden_key",0)), "mortis_key":int(GameState.meta_progression.get("mortis_key",0))}):
            var fruits := world_expansion.eden_mortis.available_fruits(room_id)
            hud.show_choice(definition.get("name", id).to_upper(), fruits.map(func(f): return String(f.get("name", f.get("id","FRUTO")))), func(index): _choose_tree_fruit(fruits, index))
    elif id == "liminal_laboratory" and world_expansion:
        if world_expansion.quantum.open_lab(_special_context()):
            var branches := world_expansion.quantum.enter_superposition(GameState.run_seed + GameState.stage_index, _special_context())
            hud.show_choice("CORREDOR DOS POSSÍVEIS", branches.map(func(b): return String(b.get("kind","possibilidade")).replace("_"," ").to_upper()), func(index): _choose_quantum_branch(branches,index))
        else: hud.show_message("O LABORATORIUM AINDA NÃO RECONHECE VOCÊ")
    elif id == "sacrifice":
        if player.health.current_health > 20.0:
            player.apply_damage(12.0, &"sacrifice_room")
            player.add_essence(8)
            hud.show_message("O SACRIFÍCIO FOI ACEITO")
        else: hud.show_message("O ALTAR RECUSA UM PREÇO QUE SERIA APENAS MORTE")
    else:
        spawn_special_reward(room_id)

func _choose_tree_fruit(fruits: Array, index: int) -> void:
    if world_expansion == null or index < 0 or index >= fruits.size(): return
    var fruit: Dictionary = fruits[index]
    var effect := world_expansion.eden_mortis.choose_fruit(StringName(fruit.get("id", "")))
    if not effect.is_empty():
        GameState.run_build["eden_mortis_effects"] = GameState.run_build.get("eden_mortis_effects", [])
        GameState.run_build["eden_mortis_effects"].append(effect)
        hud.show_message("%s · INCORPORADO" % String(fruit.get("name", "FRUTO")).to_upper(), 3.0)

func _choose_quantum_branch(branches: Array, index: int) -> void:
    if world_expansion == null or index < 0 or index >= branches.size(): return
    var branch: Dictionary = branches[index]
    var measured := world_expansion.quantum.measure_branch(StringName(branch.get("id", "")))
    if measured.is_empty(): return
    var kind := String(measured.get("kind", ""))
    match kind:
        "arsenal_vault": player.add_essence(10)
        "future_reward": player.add_essence(6); RogueliteContentService.recharge_instrument(1)
        "eden_fragment": GameState.meta_progression["eden_key"] = int(GameState.meta_progression.get("eden_key",0)) + 1
        "mortis_debt":
            GameState.route_state["curses"] = GameState.route_state.get("curses", [])
            if not GameState.route_state["curses"].has("fog"):
                GameState.route_state["curses"].append("fog")
        "timeline_secret": GameState.meta_progression["observation_fragments"] = int(GameState.meta_progression.get("observation_fragments",0)) + 1
        "mentor_echo": GameState.meta_progression["mentor_echoes"] = int(GameState.meta_progression.get("mentor_echoes",0)) + 1
        "combat_shortcut": GameState.run_stats["quantum_shortcut"] = true
    world_expansion.quantum.exit_branch_corridor()
    hud.show_message("MEDIÇÃO CONCLUÍDA · %s" % kind.replace("_"," ").to_upper(), 3.0)

func spawn_special_reward(room_id: StringName) -> Dictionary:
    var definition := ContentRegistry.get_item("special_rooms", room_id)
    if definition.is_empty():
        return {}
    var pool: Array = definition.get("reward_pool", [])
    var room := _room(String(room_id))
    for category_value in pool:
        var category := _category_catalog(String(category_value))
        if category in ["codex", "insight", "initiation", "mixed", "rare"]:
            continue
        var ids := ContentRegistry.all_ids(category)
        if ids.is_empty():
            continue
        var index := abs(GameState.run_seed + int(GameState.run_stats.get("rooms_cleared", 0)) + String(room_id).hash() + category.hash()) % ids.size()
        var item_id := StringName(ids[index])
        _spawn_pickup(room, category, item_id)
        special_reward_spawned.emit(room_id, StringName(category), item_id)
        return {"category": category, "id": String(item_id)}
    if String(room_id) == "bibliotheca":
        GameState.meta_progression["codex_entries"] = int(GameState.meta_progression.get("codex_entries", 0)) + 1
        hud.show_message("BIBLIOTHECA · UMA ENTRADA DO CODEX FOI ABERTA")
        return {"event":"codex"}
    return {}

func _spawn_pickup(room: RoomShell, category: String, forced_id: StringName = &"") -> void:
    if room == null:
        return
    var ids := ContentRegistry.all_ids(category)
    if ids.is_empty():
        return
    var item_id := forced_id if forced_id != &"" else StringName(ids[abs(GameState.run_seed + room.name.hash()) % ids.size()])
    var data := ContentRegistry.get_item(category, item_id)
    var pickup := PICKUP_SCENE.instantiate() as PickupController
    room.add_child(pickup)
    pickup.position = (room.get_node("PickupAnchor") as Marker3D).position
    pickup.category = StringName(category)
    pickup.content_id = item_id
    pickup.display_name = String(data.get("name", data.get("display_name", item_id)))
    pickup.effect_summary = String(data.get("effect_text", data.get("effect_id", "")))
    pickup.collected.connect(func(_category, _id, _actor): hud.show_message("%s ADQUIRIDO" % pickup.display_name.to_upper()))

func _on_enemy_identified(_enemy_id: StringName, display_name: String, role: String, attack_name: String) -> void:
    hud.show_identification(display_name, role, attack_name)

func _on_enemy_killed(enemy: Node) -> void:
    active_enemies.erase(enemy)
    var mutation := PowerMutationRuntime.on_enemy_killed({"elite": String(enemy.get("role")) == "elite"})
    if int(mutation.get("fragment", false)) > 0: player.add_essence(1)
    daimon_runtime.on_enemy_killed({"elite": String(enemy.get("role")) == "elite"})

func _on_boss_phase(index: int) -> void:
    if boss: hud.show_boss(boss.display_name, boss.health.ratio(), index)

func _on_boss_defeated(defeated_boss_id: StringName, reward_id: StringName) -> void:
    hud.hide_boss()
    GameState.completion_marks[String(GameState.current_stage_id)] = true
    var summary := GameState.run_stats.duplicate(true)
    summary["boss_id"] = String(defeated_boss_id)
    summary["reward_id"] = String(reward_id)
    var post_boss := handle_post_boss()
    summary["post_boss_offer"] = String(post_boss)
    GameState.complete_stage(StringName(stage_data.get("id", "")))
    SaveService.save_campaign(GameState.to_save_data())
    stage_completed.emit(StringName(stage_data.get("id", "")), summary)
    hud.show_message("%s · CONCLUÍDO" % stage_data.get("title", "ETAPA"), 5.0)

func handle_post_boss() -> StringName:
    var choice := special_rooms.choose_post_boss_room(_special_context(), GameState.run_seed + GameState.stage_index)
    if choice == &"":
        return &""
    var rooms := floor_instance.get_node("Rooms") as Node3D
    var by_id: Dictionary = {}
    for child in rooms.get_children():
        if child is RoomShell: by_id[String(child.room_id)] = child
    var definition := ContentRegistry.get_item("special_rooms", choice)
    StageFloorBuilder.spawn_special_room(rooms, definition, 98, by_id, floor_instance.get_node("Corridors") as Node3D, floor_instance.get_meta("theme", {}))
    var new_room := _room(String(choice))
    if new_room: room_director.register_room(new_room)
    return choice

func open_secret(room_id: StringName, available_charges: int) -> bool:
    var context := _special_context()
    context["rupture_charges"] = available_charges
    context["cycle"] = GameState.cycle
    if not special_rooms.can_open_secret(room_id, &"rupture_charge", context):
        return false
    GameState.run_stats["secret_found"] = true
    if room_id == &"super_secret": GameState.run_stats["super_secret_found"] = true
    return true

func _on_secret_opened(room_id: StringName) -> void:
    _spawn_pickup(_room(String(room_id)), "pharmaka")

func _on_player_died(source_id: StringName) -> void:
    GameState.record_death(String(source_id))
    SaveService.save_campaign(GameState.to_save_data())
    hud.show_message("A RUN TERMINOU · RETORNO À ETAPA ATUAL", 4.0)

func _refresh_transformations() -> void:
    if player == null:
        return
    var resolved := BuildResolver.resolve(GameState.run_build)
    transformation_director.reconcile(player, resolved.get("transformations", []))

func _on_daimon_action(effect_id: StringName, payload: Dictionary) -> void:
    match String(effect_id):
        "corpse_essence": player.add_essence(int(payload.get("essence", 1)))
        "curse_purge":
            var curses: Array = GameState.route_state.get("curses", [])
            if not curses.is_empty(): curses.pop_front(); GameState.route_state["curses"] = curses
        "reveal_secret":
            for id in ["secret", "super_secret"]:
                var room := _room(id)
                if room: room.set_meta("daimon_revealed", true)

func _on_content_effect(_effect_id: StringName, payload: Dictionary) -> void:
    var action := String(payload.get("action", ""))
    match action:
        "reveal_secrets":
            for id in ["secret", "super_secret"]:
                var room := _room(id)
                if room: room.set_meta("revealed", true)
            hud.show_message("FENDAS OCULTAS REVELADAS")
        "ritual_explosion":
            var damage := float(payload.get("damage", 48.0))
            for enemy in active_enemies:
                if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) <= 6.0:
                    enemy.apply_damage(damage, &"ritual_effect")
        "freeze_room":
            for enemy in active_enemies:
                if is_instance_valid(enemy): enemy.set_room_active(false)
            var timer := get_tree().create_timer(2.0)
            timer.timeout.connect(func():
                for enemy in active_enemies:
                    if is_instance_valid(enemy): enemy.set_room_active(true))
        "dominate":
            if not active_enemies.is_empty():
                var enemy = active_enemies[0]
                if is_instance_valid(enemy): enemy.set_room_active(false); enemy.set_meta("dominated_until", Time.get_ticks_msec() + 5000)
        "heal_and_reward":
            player.heal(float(payload.get("heal", 18.0)))
            player.add_essence(int(payload.get("essence", 1)))
        "restore_focus": player.restore_focus(28.0)
        "return_last_clear": player.global_position = (_room("threshold") as RoomShell).global_position + Vector3(0,0.15,0)
        "interrupt_and_guard":
            player.shield += 20.0
            for enemy in active_enemies:
                if is_instance_valid(enemy) and enemy.get("attack_sm") is AttackStateMachine: (enemy.get("attack_sm") as AttackStateMachine).cancel()
        "heal_reveal_room_damage":
            player.heal(float(payload.get("heal", 30.0)))
            for enemy in active_enemies:
                if is_instance_valid(enemy): enemy.apply_damage(float(payload.get("damage", 46.0)), &"sun")
        "minor_arcana":
            var suit := String(payload.get("suit", "")); var magnitude := float(payload.get("magnitude", 10.0))
            if suit == "cups": player.heal(magnitude)
            elif suit == "disks": player.add_essence(maxi(1, int(magnitude / 8.0)))
            elif suit == "wands": primary_damage += magnitude * 0.18
            elif suit == "swords": player.restore_focus(magnitude)
        _:
            hud.show_message(action.replace("_", " ").to_upper())

func grant_reward_direct(category: String, item_id: StringName) -> bool:
    return RogueliteContentService.grant(category, item_id)

func _special_context() -> Dictionary:
    return {
        "stage_id": String(GameState.current_stage_id),
        "rooms_cleared": int(GameState.run_stats.get("rooms_cleared", 0)),
        "secret_found": GameState.run_stats.get("secret_found", false),
        "super_secret_found": GameState.run_stats.get("super_secret_found", false),
        "codex_entries": int(GameState.meta_progression.get("codex_entries", 0)),
        "post_boss_choice": String(GameState.route_state.get("post_boss_choice", "")),
        "curse_count": GameState.route_state.get("curses", []).size(),
        "theophanies_seen": int(GameState.meta_progression.get("theophanies_seen", 0)),
        "hostile_echo": GameState.route_state.get("curses", []).has("hostile_echo"),
        "stage_index": GameState.stage_index,
        "cycle": GameState.cycle,
        "observation_fragments": int(GameState.meta_progression.get("observation_fragments", 0))
    }

func _vision_context() -> Dictionary:
    var context := GameState.meta_progression.duplicate(true)
    context["route"] = String(GameState.route_state.get("route", "student"))
    context["stage"] = String(GameState.current_stage_id)
    context["curse_count"] = GameState.route_state.get("curses", []).size()
    context["sigillum"] = String(GameState.run_build.get("sigillum", ""))
    return context

func _category_catalog(category: String) -> String:
    var map := {"tarot":"tarot", "relics":"relics", "instrumenta":"instrumenta", "pharmaka":"pharmaka", "sigilla":"sigilla", "talismans":"talismans", "transformations":"transformations", "blessings":"blessings"}
    return String(map.get(category, category))
