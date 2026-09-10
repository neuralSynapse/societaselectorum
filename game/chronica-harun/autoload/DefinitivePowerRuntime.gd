extends Node

signal power_activated(power_id: StringName, effect_id: StringName)

const POWER_FOCUS_COST := 20.0
const POWER_COOLDOWN := 0.62

var stage_director: StageDirector
var player: PlayerController
var _bound_player_id := 0

func _ready() -> void:
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_scan_existing")

func _process(_delta: float) -> void:
    if stage_director == null or not is_instance_valid(stage_director):
        return
    if is_instance_valid(stage_director.player):
        var candidate := stage_director.player as PlayerController
        if player == null or not is_instance_valid(player) or candidate.get_instance_id() != _bound_player_id:
            _bind_player(candidate)

func _scan_existing() -> void:
    var scene := get_tree().current_scene
    if scene != null:
        _scan_node(scene)

func _scan_node(node: Node) -> void:
    if node is StageDirector:
        _bind_stage(node as StageDirector)
        return
    for child in node.get_children():
        _scan_node(child)
        if stage_director != null:
            return

func _on_node_added(node: Node) -> void:
    if node is StageDirector:
        call_deferred("_bind_stage", node)

func _bind_stage(next_stage: StageDirector) -> void:
    if next_stage == null or not is_instance_valid(next_stage):
        return
    stage_director = next_stage
    if is_instance_valid(stage_director.player):
        _bind_player(stage_director.player as PlayerController)

func _bind_player(next_player: PlayerController) -> void:
    if next_player == null or not is_instance_valid(next_player):
        return
    player = next_player
    _bound_player_id = player.get_instance_id()
    _replace_stage_power_handler(player)
    if not player.power_requested.is_connected(_on_power_requested):
        player.power_requested.connect(_on_power_requested)

func _replace_stage_power_handler(next_player: PlayerController) -> void:
    # StageDirector originally shipped with only two matrix power implementations.
    # Replace only that one callback, leaving VFX/audio observers and every other
    # gameplay connection untouched.
    for connection in next_player.get_signal_connection_list(&"power_requested"):
        var callback: Callable = connection.get("callable", Callable())
        if not callback.is_valid():
            continue
        if callback.get_object() == stage_director and String(callback.get_method()) == "_on_power_requested":
            next_player.power_requested.disconnect(callback)

func _on_power_requested() -> void:
    if player == null or not is_instance_valid(player) or stage_director == null or not is_instance_valid(stage_director):
        return
    if player.power_cooldown > 0.0:
        return
    var power_id := _current_power_id()
    if power_id == &"":
        return
    if not player.spend_focus(POWER_FOCUS_COST):
        if is_instance_valid(stage_director.hud):
            stage_director.hud.show_message("FOCO INSUFICIENTE")
        return
    player.power_cooldown = POWER_COOLDOWN
    var power := ContentRegistry.get_power(power_id)
    var effect_id := StringName(power.get("effect_id", power_id))
    _activate_power(effect_id, power_id, power)

func _current_power_id() -> StringName:
    var build := RogueliteContentService.ensure_build()
    var active := StringName(build.get("active_power", ""))
    if active != &"":
        return active
    if stage_director != null and not stage_director.stage_data.is_empty():
        return StringName(stage_director.stage_data.get("power_id", ""))
    return &""

func _activate_power(effect_id: StringName, power_id: StringName, power: Dictionary) -> void:
    match String(effect_id):
        "revelatory_eye", "revelatory_eye_base":
            _reveal_combatants(7000)
        "black_flame_matrix_base":
            _damage_radius(6.0, 28.0, &"black_flame")
        "foundation_hammer_base":
            _foundation_hammer()
        "election_sigil_base":
            _election_sigil()
        "inner_balance_base":
            _inner_balance()
        "will_vector_base":
            _will_vector()
        "character_column_base":
            player.shield += 38.0
            player.dodge_invulnerability_remaining = maxf(player.dodge_invulnerability_remaining, 0.36)
        "discipline_rhythm_base":
            player.stamina = player.max_stamina
            player.primary_cooldown = 0.0
            RogueliteContentService.recharge_instrument(1)
        "clarity_light_base":
            _clarity_light()
        "transmutation_serpent_base":
            _transmutation_serpent()
        "vital_pulse_base":
            player.heal(32.0)
            player.stamina = player.max_stamina
            player.shield += 8.0
        "hand_of_work_base":
            stage_director.rupture_charges += 1
            GameState.run_stats["rupture_charges"] = stage_director.rupture_charges
            player.shield += 18.0
        "sigillar_fortune_base":
            player.add_essence(7)
            GameState.run_stats["reward_reroll_tokens"] = int(GameState.run_stats.get("reward_reroll_tokens", 0)) + 1
        "verbum_base":
            _verbum()
        "memoria_ignis_base":
            RogueliteContentService.recharge_instrument(1)
            player.restore_focus(30.0)
            GameState.run_stats["memoria_ignis_uses"] = int(GameState.run_stats.get("memoria_ignis_uses", 0)) + 1
        _:
            # Unknown future matrix powers stay safe and visible rather than silently
            # consuming focus with no feedback.
            player.restore_focus(POWER_FOCUS_COST)
            if is_instance_valid(stage_director.hud):
                stage_director.hud.show_message("PODER AINDA NÃO MATERIALIZADO · %s" % String(effect_id).replace("_", " ").to_upper())
            return

    var display_name := String(power.get("name", power_id)).to_upper()
    if is_instance_valid(stage_director.hud):
        stage_director.hud.show_message(display_name, 1.65)
    VFXDirector.emit_feedback(&"power_reveal", player.global_position + Vector3.UP * 1.0, -player.global_transform.basis.z, {"power_id": String(power_id), "effect_id": String(effect_id)})
    AudioDirector.play_ui(&"power_reveal")
    power_activated.emit(power_id, effect_id)

func _combatants() -> Array[Node]:
    var result: Array[Node] = []
    if stage_director == null:
        return result
    for enemy in stage_director.active_enemies:
        if is_instance_valid(enemy):
            result.append(enemy)
    if stage_director.boss != null and is_instance_valid(stage_director.boss) and not result.has(stage_director.boss):
        result.append(stage_director.boss)
    return result

func _damage_radius(radius: float, damage: float, source_id: StringName, push_force := 0.0) -> int:
    var hits := 0
    for enemy in _combatants():
        if not enemy.has_method("apply_damage"):
            continue
        var enemy_3d := enemy as Node3D
        if enemy_3d == null or enemy_3d.global_position.distance_to(player.global_position) > radius:
            continue
        enemy.call("apply_damage", damage, source_id)
        hits += 1
        if push_force > 0.0 and enemy is CharacterBody3D:
            var direction := enemy_3d.global_position - player.global_position
            direction.y = 0.0
            if direction.length_squared() > 0.01:
                (enemy as CharacterBody3D).velocity += direction.normalized() * push_force
    return hits

func _reveal_combatants(duration_ms: int) -> void:
    var until := Time.get_ticks_msec() + duration_ms
    for enemy in _combatants():
        enemy.set_meta("revealed_until", until)
        enemy.set_meta("telegraph_revealed", true)

func _aim_target() -> Node:
    if player == null:
        return null
    var target := player.get_aim_target()
    if target != null and target.has_method("apply_damage"):
        return target
    var nearest: Node = null
    var nearest_distance := INF
    for enemy in _combatants():
        if enemy is Node3D:
            var distance := (enemy as Node3D).global_position.distance_to(player.global_position)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest = enemy
    return nearest

func _foundation_hammer() -> void:
    var target := _aim_target()
    if target != null:
        target.call("apply_damage", 44.0, &"foundation_hammer")
    _damage_radius(4.5, 14.0, &"foundation_shockwave", 5.5)

func _election_sigil() -> void:
    var target := _aim_target()
    if target != null:
        target.set_meta("election_mark_until", Time.get_ticks_msec() + 8000)
        target.call("apply_damage", 18.0, &"election_sigil")
    player.shield += 18.0

func _inner_balance() -> void:
    var missing_health := maxf(0.0, player.health.max_health - player.health.current_health)
    if missing_health > 0.0:
        player.heal(minf(24.0, missing_health))
        player.restore_focus(14.0)
    else:
        player.restore_focus(30.0)
        player.shield += 16.0

func _will_vector() -> void:
    var forward := -player.global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() > 0.01:
        player.velocity += forward.normalized() * 8.5
    var target := _aim_target()
    if target != null:
        target.call("apply_damage", 34.0, &"will_vector")
        target.set_meta("will_vector_mark", Time.get_ticks_msec() + 3200)

func _clarity_light() -> void:
    _reveal_combatants(9000)
    for enemy in _combatants():
        var attack_sm = enemy.get("attack_sm")
        if attack_sm is AttackStateMachine:
            (attack_sm as AttackStateMachine).cancel()
        enemy.set_meta("clarity_exposed_until", Time.get_ticks_msec() + 5000)

func _transmutation_serpent() -> void:
    var curses: Array = GameState.route_state.get("curses", [])
    if not curses.is_empty():
        curses.pop_front()
        GameState.route_state["curses"] = curses
        player.restore_focus(28.0)
        player.add_essence(4)
    else:
        player.heal(14.0)
        player.add_essence(2)

func _verbum() -> void:
    _damage_radius(8.0, 14.0, &"verbum", 7.0)
    for enemy in _combatants():
        var attack_sm = enemy.get("attack_sm")
        if attack_sm is AttackStateMachine:
            (attack_sm as AttackStateMachine).cancel()
        enemy.set_meta("silenced_until", Time.get_ticks_msec() + 2600)
