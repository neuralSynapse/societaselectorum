extends CanvasLayer
class_name HUDController

@onready var objective: Label = $Root/Objective
@onready var life: ProgressBar = $Root/PlayerPanel/Life
@onready var life_value: Label = $Root/PlayerPanel/LifeValue
@onready var focus: ProgressBar = $Root/PlayerPanel/Focus
@onready var focus_value: Label = $Root/PlayerPanel/FocusValue
@onready var essence: Label = $Root/PlayerPanel/Essence
@onready var player_name: Label = $Root/PlayerPanel/PlayerName
@onready var player_level: Label = $Root/PlayerPanel/PlayerLevel
@onready var identity_panel: Control = $Root/IdentificationPanel
@onready var identity_name: Label = $Root/IdentificationPanel/IdentityName
@onready var identity_role: Label = $Root/IdentificationPanel/IdentityRole
@onready var identity_attack: Label = $Root/IdentificationPanel/IdentityAttack
@onready var boss_panel: Control = $Root/BossPanel
@onready var boss_name: Label = $Root/BossPanel/BossName
@onready var boss_level: Label = $Root/BossPanel/BossLevel
@onready var boss_health: ProgressBar = $Root/BossPanel/BossHealth
@onready var boss_phase: Label = $Root/BossPanel/BossPhase
@onready var boss_power: Label = $Root/BossPanel/BossPower
@onready var build_label: Label = $Root/PlayerPanel/BuildState
@onready var message: Label = $Root/Message
@onready var message_backdrop: Control = $Root/MessageBackdrop
@onready var kinesis_state: Label = $Root/KinesisState
@onready var camera_mode: Label = $Root/CameraMode
@onready var enemy_markers: Control = $Root/EnemyMarkers
@onready var reward_feed: VBoxContainer = $Root/RewardFeed
@onready var power_slots: HBoxContainer = $Root/PowerSlots
@onready var acquired_panel: Control = $Root/PowerAcquiredPanel
@onready var acquired_name: Label = $Root/PowerAcquiredPanel/PowerAcquiredName
@onready var acquired_description: Label = $Root/PowerAcquiredPanel/PowerAcquiredDescription
@onready var choice_panel: Control = $Root/ChoicePanel
@onready var choice_title: Label = $Root/ChoicePanel/ChoiceTitle
@onready var choice_options: VBoxContainer = $Root/ChoicePanel/ChoiceOptions
@onready var pause_panel: Control = $Root/PausePanel

var choice_callback: Callable
var hide_timer := 0.0
var acquired_hide_timer := 0.0
var player_ref: PlayerController
var tracked_enemies: Dictionary = {}
var slot_payloads: Array = []
var current_kinesis_loadout: Array = []
var known_mutations: Array[String] = []
var known_powers: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    message.visible = false
    message_backdrop.visible = false
    acquired_panel.visible = false
    get_tree().node_added.connect(_on_tree_node_added)
    RogueliteContentService.build_changed.connect(_on_build_changed_definitive)
    _capture_known_build()
    call_deferred("_scan_combatants")

func _process(delta: float) -> void:
    if hide_timer > 0.0:
        hide_timer -= delta
        if hide_timer <= 0.0:
            message.visible = false
            message_backdrop.visible = false
            identity_panel.visible = false
    if acquired_hide_timer > 0.0:
        acquired_hide_timer -= delta
        if acquired_hide_timer <= 0.0:
            acquired_panel.visible = false
    _update_enemy_markers()
    _update_boss_panel()
    _update_power_cooldowns()

func bind_player(player: PlayerController) -> void:
    player_ref = player
    player_name.text = "HARUN"
    player_level.text = str(maxi(1, GameState.stage_index + GameState.cycle + 1))
    life.max_value = player.health.max_health
    life.value = player.health.current_health
    life_value.text = "%d / %d" % [roundi(player.health.current_health), roundi(player.health.max_health)]
    focus.max_value = player.max_focus
    focus.value = player.focus
    focus_value.text = "%d / %d" % [roundi(player.focus), roundi(player.max_focus)]
    essence.text = "ESSÊNCIA  %d" % player.essence
    if not player.health.damaged.is_connected(_on_player_health_changed):
        player.health.damaged.connect(_on_player_health_changed)
    if not player.health.healed.is_connected(_on_player_healed):
        player.health.healed.connect(_on_player_healed)
    if not player.focus_changed.is_connected(_on_focus_changed):
        player.focus_changed.connect(_on_focus_changed)
    if not player.essence_changed.is_connected(_on_essence_changed):
        player.essence_changed.connect(_on_essence_changed)
    refresh_build()
    _refresh_power_slots_from_state()

func set_objective(text: String) -> void:
    objective.text = text

func set_pause_visible(value: bool) -> void:
    pause_panel.visible = value

func show_identification(display_name: String, role: String, attack_name: String) -> void:
    identity_name.text = display_name.to_upper()
    identity_role.text = role.replace("_", " ").to_upper()
    identity_attack.text = "PODER · %s" % attack_name.to_upper()
    identity_panel.visible = true
    hide_timer = maxf(hide_timer, 2.2)

func show_boss(display_name: String, hp_ratio: float, phase: int, level: int = 1, power_name: String = "") -> void:
    boss_panel.visible = true
    boss_name.text = display_name.to_upper()
    boss_level.text = "N%d" % maxi(1, level)
    boss_health.value = clampf(hp_ratio, 0.0, 1.0) * 100.0
    boss_phase.text = "FASE %s" % _roman(maxi(1, phase))
    boss_power.text = power_name.replace("_", " ").to_upper()

func hide_boss() -> void:
    boss_panel.visible = false

func show_message(text: String, duration := 2.5) -> void:
    message.text = text
    message.visible = true
    message_backdrop.visible = true
    hide_timer = maxf(hide_timer, duration)

func refresh_build() -> void:
    var build := RogueliteContentService.ensure_build()
    var labels: Array[String] = []
    for key in ["arcana", "pharmakon", "sigillum", "daimon", "route"]:
        var value := String(build.get(key, ""))
        if not value.is_empty():
            labels.append(value.replace("_", " ").to_upper())
    var instrument: Dictionary = build.get("instrumentum", {})
    if not instrument.is_empty():
        labels.append(String(instrument.get("id", "INSTRUMENTUM")).replace("_", " ").to_upper())
    var powers: Array = build.get("powers", [])
    if not powers.is_empty():
        labels.append("PODERES %d" % powers.size())
    var mutations: Array = build.get("mutations", [])
    if not mutations.is_empty():
        labels.append("MUTAÇÕES %d" % mutations.size())
    build_label.text = " · ".join(labels) if not labels.is_empty() else "VONTADE SEM FORMA"

func set_kinesis_loadout(loadout: Array) -> void:
    current_kinesis_loadout = loadout.duplicate(true)
    var labels: Array[String] = []
    for i in range(loadout.size()):
        var value := String(loadout[i])
        if not value.is_empty():
            labels.append("%d %s" % [i + 1, value.replace("_", " ").to_upper()])
    kinesis_state.text = "KINESIS  " + "  ·  ".join(labels)
    _refresh_power_slots_from_state()

func set_camera_mode(mode: StringName) -> void:
    camera_mode.text = ("1ª PESSOA" if String(mode) == "first_person" else "3ª PESSOA") + " · V"

func set_power_slots(slots: Array) -> void:
    slot_payloads = slots.duplicate(true)
    for i in range(mini(power_slots.get_child_count(), 4)):
        var panel := power_slots.get_child(i)
        var data: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
        var name_label := panel.get_node("Name") as Label
        var key_label := panel.get_node("Key") as Label
        var cooldown_label := panel.get_node("Cooldown") as Label
        if data.is_empty():
            name_label.text = "VAZIO"
            key_label.text = ""
            cooldown_label.text = ""
        else:
            name_label.text = String(data.get("name", "PODER")).replace("_", " ").to_upper()
            key_label.text = String(data.get("key", ""))
            cooldown_label.text = ""

func show_power_acquired(power_name: String, description: String = "") -> void:
    acquired_name.text = power_name.replace("_", " ").to_upper()
    acquired_description.text = description if not description.is_empty() else "A vontade encontra uma nova forma."
    acquired_panel.modulate = Color(1, 1, 1, 0)
    acquired_panel.visible = true
    var readable_time := maxf(4.2, NarratorDirector.estimate_duration(acquired_description.text) + 1.2)
    acquired_hide_timer = readable_time
    var tween := create_tween()
    tween.tween_property(acquired_panel, "modulate:a", 1.0, 0.18)
    tween.tween_interval(maxf(3.4, readable_time - 0.7))
    tween.tween_property(acquired_panel, "modulate:a", 0.0, 0.48)

func show_acquisition(category: String, item_id: StringName, data: Dictionary = {}) -> String:
    var row := data.duplicate(true)
    if row.is_empty():
        row = ContentRegistry.get_item(category, item_id)
    var name := String(row.get("name", row.get("display_name", item_id))).replace("_", " ")
    var explanation := _describe_acquisition(category, row)
    var category_label := category.replace("_", " ").to_upper()
    show_power_acquired("%s · %s" % [category_label, name], explanation)
    push_reward("+ %s · %s" % [category_label, name.to_upper()])
    AudioDirector.play_ui(&"power_reveal")
    return explanation

func _describe_acquisition(category: String, data: Dictionary) -> String:
    var purpose := _acquisition_purpose(category, data)
    var usage := _acquisition_usage(category, data)
    return "PARA QUE SERVE · %s\nCOMO USAR · %s" % [purpose, usage]

func _acquisition_purpose(category: String, data: Dictionary) -> String:
    var effect_id := String(data.get("effect_id", data.get("effect", {}).get("effect_id", "")))
    var summary := String(data.get("effect_text", data.get("codex", {}).get("summary", "")))
    match category:
        "tarot":
            return _effect_purpose(effect_id, summary)
        "pharmaka":
            var benefit := String(data.get("benefit", data.get("effect", {}).get("benefit", "efeito desconhecido"))).replace("_", " ")
            var magnitude := int(data.get("magnitude", data.get("effect", {}).get("magnitude", 0)))
            var side := String(data.get("side_effect", data.get("effect", {}).get("side_effect", "none"))).replace("_", " ")
            var text := "gera %s" % benefit
            if magnitude > 0:
                text += " com intensidade %d" % magnitude
            if side != "none" and not side.is_empty():
                text += "; cobra como efeito colateral: %s" % side
            return text
        "instrumenta":
            return _effect_purpose(effect_id, summary)
        "relics":
            return summary if not summary.is_empty() else "modifica passivamente a build durante esta run"
        "talismans":
            return summary if not summary.is_empty() else "altera passivamente defesa, dano ou recursos enquanto equipado"
        "sigilla":
            var dominion := String(data.get("dominium", "um domínio oculto")).replace("_", " ")
            var price := String(data.get("pretium", "um preço ainda não revelado")).replace("_", " ")
            return "vincula o domínio %s em troca de %s" % [dominion, price]
        "daimones":
            return summary if not summary.is_empty() else "adiciona um companheiro autônomo com uma regra própria de assistência"
        "blessings":
            return summary if not summary.is_empty() else "concede uma vantagem persistente durante a rota atual"
        "curses":
            return summary if not summary.is_empty() else "impõe uma regra adversa persistente e aumenta o risco da run"
        "transformations":
            return summary if not summary.is_empty() else "altera o corpo e a matriz de efeitos de Harun automaticamente"
        "powers":
            return summary if not summary.is_empty() else "adiciona uma nova forma ativa de poder"
    return summary if not summary.is_empty() else "altera a build da run"

func _acquisition_usage(category: String, data: Dictionary) -> String:
    match category:
        "tarot": return "pressione C quando o Arcano estiver equipado; é consumido no uso"
        "pharmaka": return "pressione C; o efeito é identificado plenamente depois do primeiro consumo"
        "instrumenta": return "pressione R; possui cargas limitadas e pode ser recarregado"
        "relics": return "passivo; funciona automaticamente enquanto permanecer na build"
        "talismans": return "passivo; até dois ficam equipados ao mesmo tempo"
        "sigilla": return "vínculo passivo; o benefício e o preço entram na run imediatamente"
        "daimones": return "automático; reage a mortes, salas, Arcana e outros gatilhos compatíveis"
        "blessings": return "passivo; permanece ativo na rota atual"
        "curses": return "automático; a maldição permanece até ser removida por um efeito específico"
        "transformations": return "automático; a transformação é reconciliada com a build atual"
        "powers": return "RMB ativa o poder selecionado e normalmente consome Foco"
    var charges := int(data.get("charges", 0))
    return "efeito contextual%s" % (" com %d cargas" % charges if charges > 0 else "")

func _effect_purpose(effect_id: String, fallback: String) -> String:
    var purposes := {
        "threshold_reset":"retorna ao último limiar seguro e recupera Foco",
        "echo_instrument":"repete o próximo efeito de Instrumentum",
        "secret_sight":"revela passagens secretas próximas",
        "fecundity":"cura Harun e concede Essência",
        "command":"interrompe inimigos e cria proteção temporária",
        "tradition":"converte conhecimento do Codex em defesa",
        "syzygy":"funde Talisman e Instrumentum em uma combinação de build",
        "chariot":"concede avanço rápido com breve invulnerabilidade",
        "adjustment":"reequilibra recursos e remove efeitos adversos",
        "hermit":"abre uma escolha oculta",
        "fortune":"rerrola uma recompensa da sala",
        "lust":"premia agressividade contínua por tempo limitado",
        "suspension":"altera fase e desacelera ameaças",
        "death":"executa alvos enfraquecidos e reduz sua pressão",
        "art":"funde consumível e Instrumentum",
        "devil":"troca vida máxima por aumento de dano",
        "tower":"provoca explosão ritual e pode romper segredos",
        "star":"revela objetivo e aumenta precisão temporariamente",
        "moon":"revela segredo, mas acrescenta ameaça",
        "sun":"cura, revela a sala e causa dano aos inimigos",
        "aeon":"altera uma regra do andar",
        "universe":"abre conexão excepcional, cura e concede Essência",
    }
    if purposes.has(effect_id):
        return String(purposes[effect_id])
    return fallback if not fallback.is_empty() else effect_id.replace("_", " ")

func push_reward(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.add_theme_color_override("font_color", Color(0.88, 0.75, 0.52, 1.0))
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    label.add_theme_font_size_override("font_size", 14)
    reward_feed.add_child(label)
    if reward_feed.get_child_count() > 5:
        var oldest := reward_feed.get_child(0)
        reward_feed.remove_child(oldest)
        oldest.queue_free()
    var tween := create_tween()
    tween.tween_interval(2.8)
    tween.tween_property(label, "modulate:a", 0.0, 0.5)
    tween.tween_callback(label.queue_free)

func track_enemy(enemy: Node3D, boss_view := false) -> void:
    if enemy == null or not is_instance_valid(enemy):
        return
    var id := enemy.get_instance_id()
    if tracked_enemies.has(id):
        return
    if boss_view:
        tracked_enemies[id] = {"enemy": enemy, "marker": null, "boss": true}
        _bind_boss(enemy as DataBossController)
        return
    var marker := _create_enemy_marker(enemy)
    enemy_markers.add_child(marker)
    tracked_enemies[id] = {"enemy": enemy, "marker": marker, "boss": false}

func untrack_enemy(enemy: Node) -> void:
    if enemy == null:
        return
    _untrack_by_id(enemy.get_instance_id())

func _untrack_by_id(id: int) -> void:
    if not tracked_enemies.has(id):
        return
    var entry: Dictionary = tracked_enemies[id]
    var marker: Control = entry.get("marker") as Control
    if marker != null and is_instance_valid(marker):
        marker.queue_free()
    tracked_enemies.erase(id)

func _scan_combatants() -> void:
    for node in get_tree().get_nodes_in_group("enemies"):
        if node is Node3D:
            track_enemy(node as Node3D)
    for node in get_tree().get_nodes_in_group("bosses"):
        if node is Node3D:
            track_enemy(node as Node3D, true)

func _on_tree_node_added(node: Node) -> void:
    if node is EnemyBrain:
        call_deferred("track_enemy", node as Node3D, false)
    elif node is DataBossController:
        call_deferred("track_enemy", node as Node3D, true)

func _bind_boss(next_boss: DataBossController) -> void:
    if next_boss == null or not is_instance_valid(next_boss):
        return
    if not next_boss.combat_status_changed.is_connected(_on_boss_status_changed):
        next_boss.combat_status_changed.connect(_on_boss_status_changed)
    if not next_boss.phase_changed.is_connected(_on_boss_phase_changed):
        next_boss.phase_changed.connect(_on_boss_phase_changed.bind(next_boss))
    if not next_boss.boss_defeated.is_connected(_on_tracked_boss_defeated):
        next_boss.boss_defeated.connect(_on_tracked_boss_defeated.bind(next_boss))
    show_boss(next_boss.display_name, next_boss.get_health_ratio(), next_boss.current_phase + 1, next_boss.combat_level, next_boss.get_attack_name())

func _on_boss_status_changed(next_boss: DataBossController, ratio: float) -> void:
    if next_boss == null or not is_instance_valid(next_boss):
        return
    show_boss(next_boss.display_name, ratio, next_boss.current_phase + 1, next_boss.combat_level, next_boss.get_attack_name())

func _on_boss_phase_changed(index: int, next_boss: DataBossController) -> void:
    if next_boss == null or not is_instance_valid(next_boss):
        return
    show_boss(next_boss.display_name, next_boss.get_health_ratio(), index, next_boss.combat_level, next_boss.get_attack_name())
    show_message("%s · FASE %s" % [next_boss.display_name.to_upper(), _roman(index)], 1.8)

func _on_tracked_boss_defeated(_boss_id: StringName, _reward_id: StringName, next_boss: DataBossController) -> void:
    if next_boss != null:
        _untrack_by_id(next_boss.get_instance_id())
    hide_boss()

func _capture_known_build() -> void:
    var build := RogueliteContentService.ensure_build()
    known_mutations.clear()
    known_powers.clear()
    for id in build.get("mutations", []):
        known_mutations.append(String(id))
    for id in build.get("powers", []):
        known_powers.append(String(id))

func _on_build_changed_definitive(build: Dictionary) -> void:
    var next_powers: Array[String] = []
    for id in build.get("powers", []):
        var power_id := String(id)
        next_powers.append(power_id)
        if not known_powers.has(power_id):
            _announce_power(power_id)
    var next_mutations: Array[String] = []
    for id in build.get("mutations", []):
        var mutation_id := String(id)
        next_mutations.append(mutation_id)
        if not known_mutations.has(mutation_id):
            _announce_mutation(mutation_id)
    known_powers = next_powers
    known_mutations = next_mutations
    refresh_build()
    _refresh_power_slots_from_state()

func _announce_power(power_id: String) -> void:
    var power := ContentRegistry.get_power(StringName(power_id))
    var label := String(power.get("name", power_id)).to_upper()
    var description := String(power.get("effect_text", power.get("codex", {}).get("summary", "Nova matriz de poder integrada.")))
    show_power_acquired(label, description)
    push_reward("+ PODER · %s" % label)
    AudioDirector.play_ui(&"power_reveal")
    if player_ref != null and is_instance_valid(player_ref):
        VFXDirector.emit_feedback(&"power_reveal", player_ref.global_position + Vector3.UP, Vector3.UP)

func _announce_mutation(mutation_id: String) -> void:
    var label := _mutation_label(mutation_id)
    show_power_acquired(label, "A matriz de Harun sofreu uma mutação permanente nesta run.")
    push_reward("+ MUTAÇÃO · %s" % label)
    AudioDirector.play_ui(&"power_reveal")
    if player_ref != null and is_instance_valid(player_ref):
        VFXDirector.emit_feedback(&"power_reveal", player_ref.global_position + Vector3.UP, Vector3.UP)

func _mutation_label(mutation_id: String) -> String:
    for power in ContentRegistry.all("powers"):
        var power_name := String(power.get("name", power.get("id", "PODER")))
        for mutation in power.get("mutations", []):
            if String(mutation.get("id", "")) == mutation_id:
                return "%s · FORMA %d" % [power_name.to_upper(), int(mutation.get("tier", 1))]
    return mutation_id.replace("_", " ").to_upper()

func _refresh_power_slots_from_state() -> void:
    var build := RogueliteContentService.ensure_build()
    var active_power_id := String(build.get("active_power", ""))
    if active_power_id.is_empty():
        var journey := ContentRegistry.get_student_journey()
        if not journey.is_empty():
            var stage: Dictionary = journey[clampi(GameState.stage_index, 0, journey.size() - 1)]
            active_power_id = String(stage.get("power_id", ""))
    var active_power_name := "PODER"
    if not active_power_id.is_empty():
        var power := ContentRegistry.get_power(StringName(active_power_id))
        active_power_name = String(power.get("name", active_power_id))
    var kinesis_name := "KINESIS"
    if not current_kinesis_loadout.is_empty() and not String(current_kinesis_loadout[0]).is_empty():
        kinesis_name = String(current_kinesis_loadout[0])
    var utility_name := "RITUAL"
    var utility_key := "R"
    var instrument: Dictionary = build.get("instrumentum", {})
    if not instrument.is_empty():
        var instrument_id := StringName(instrument.get("id", ""))
        var instrument_data := ContentRegistry.get_item("instrumenta", instrument_id)
        utility_name = String(instrument_data.get("name", instrument_id))
    elif not String(build.get("arcana", "")).is_empty():
        utility_name = String(build.get("arcana", "ARCANO"))
        utility_key = "C"
    set_power_slots([
        {"name":"ATAQUE", "key":"LMB"},
        {"name":active_power_name, "key":"RMB"},
        {"name":kinesis_name, "key":"1–3"},
        {"name":utility_name, "key":utility_key}
    ])

func show_choice(title: String, options: Array, callback: Callable) -> void:
    for child in choice_options.get_children():
        child.queue_free()
    choice_title.text = title
    choice_callback = callback
    for i in range(options.size()):
        var button := Button.new()
        button.text = String(options[i])
        button.custom_minimum_size = Vector2(0, 72)
        button.add_theme_font_size_override("font_size", 16)
        button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        button.pressed.connect(_on_choice_pressed.bind(i))
        choice_options.add_child(button)
    choice_panel.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_choice_pressed(index: int) -> void:
    choice_panel.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if choice_callback.is_valid():
        choice_callback.call(index)

func _on_player_health_changed(current: float, maximum: float, _amount: float, _source_id: StringName) -> void:
    life.max_value = maximum
    life.value = current
    life_value.text = "%d / %d" % [roundi(current), roundi(maximum)]

func _on_player_healed(current: float, maximum: float, _amount: float) -> void:
    life.max_value = maximum
    life.value = current
    life_value.text = "%d / %d" % [roundi(current), roundi(maximum)]

func _on_focus_changed(current: float, maximum: float) -> void:
    focus.max_value = maximum
    focus.value = current
    focus_value.text = "%d / %d" % [roundi(current), roundi(maximum)]

func _on_essence_changed(value: int) -> void:
    essence.text = "ESSÊNCIA  %d" % value

func _create_enemy_marker(enemy: Node3D) -> Control:
    var panel := Panel.new()
    panel.custom_minimum_size = Vector2(210, 52)
    panel.size = Vector2(210, 52)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color(0.015, 0.012, 0.014, 0.78)
    frame.border_width_left = 1
    frame.border_width_top = 1
    frame.border_width_right = 1
    frame.border_width_bottom = 1
    frame.border_color = Color(0.55, 0.39, 0.19, 0.88)
    frame.corner_radius_top_left = 3
    frame.corner_radius_top_right = 3
    frame.corner_radius_bottom_left = 3
    frame.corner_radius_bottom_right = 3
    panel.add_theme_stylebox_override("panel", frame)

    var name_label := Label.new()
    name_label.name = "Name"
    name_label.position = Vector2(8, 3)
    name_label.size = Vector2(194, 22)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 13)
    name_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.78, 1))
    panel.add_child(name_label)

    var health_bar := ProgressBar.new()
    health_bar.name = "Life"
    health_bar.position = Vector2(18, 29)
    health_bar.size = Vector2(174, 12)
    health_bar.max_value = 100.0
    health_bar.value = 100.0
    health_bar.show_percentage = false
    var background := StyleBoxFlat.new()
    background.bg_color = Color(0.025, 0.018, 0.02, 0.95)
    background.border_width_left = 1
    background.border_width_top = 1
    background.border_width_right = 1
    background.border_width_bottom = 1
    background.border_color = Color(0.25, 0.18, 0.14, 0.9)
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color(0.66, 0.045, 0.06, 1)
    health_bar.add_theme_stylebox_override("background", background)
    health_bar.add_theme_stylebox_override("fill", fill)
    panel.add_child(health_bar)

    var role := String(enemy.get("role"))
    if role == "elite":
        frame.border_color = Color(0.71, 0.43, 0.18, 1)
        fill.bg_color = Color(0.77, 0.12, 0.09, 1)
    return panel

func _update_enemy_markers() -> void:
    if tracked_enemies.is_empty():
        return
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var viewport_size := get_viewport().get_visible_rect().size
    var stale: Array[int] = []
    for id_value in tracked_enemies.keys():
        var id := int(id_value)
        var entry: Dictionary = tracked_enemies[id]
        var enemy: Node3D = entry.get("enemy") as Node3D
        if enemy == null or not is_instance_valid(enemy):
            stale.append(id)
            continue
        if bool(entry.get("boss", false)):
            continue
        var marker: Control = entry.get("marker") as Control
        if marker == null or not is_instance_valid(marker):
            stale.append(id)
            continue
        var health_ratio := 1.0
        if enemy.has_method("get_health_ratio"):
            health_ratio = float(enemy.call("get_health_ratio"))
        var display := String(enemy.get("display_name"))
        var level := int(enemy.get("combat_level"))
        (marker.get_node("Name") as Label).text = "%s   N%d" % [display.to_upper(), maxi(1, level)]
        (marker.get_node("Life") as ProgressBar).value = clampf(health_ratio, 0.0, 1.0) * 100.0
        var world_pos := enemy.global_position + Vector3.UP * 1.85
        var visible := not camera.is_position_behind(world_pos)
        if visible:
            var screen_pos := camera.unproject_position(world_pos)
            visible = screen_pos.x >= -120.0 and screen_pos.x <= viewport_size.x + 120.0 and screen_pos.y >= -80.0 and screen_pos.y <= viewport_size.y + 80.0
            if visible:
                marker.position = screen_pos - Vector2(marker.size.x * 0.5, marker.size.y + 12.0)
        marker.visible = visible
    for id in stale:
        _untrack_by_id(id)

func _update_boss_panel() -> void:
    for entry_value in tracked_enemies.values():
        var entry: Dictionary = entry_value
        if not bool(entry.get("boss", false)):
            continue
        var tracked_boss: DataBossController = entry.get("enemy") as DataBossController
        if tracked_boss == null or not is_instance_valid(tracked_boss):
            continue
        show_boss(tracked_boss.display_name, tracked_boss.get_health_ratio(), tracked_boss.current_phase + 1, tracked_boss.combat_level, tracked_boss.get_attack_name())
        return

func _update_power_cooldowns() -> void:
    if player_ref == null or not is_instance_valid(player_ref) or power_slots.get_child_count() < 2:
        return
    var primary := power_slots.get_child(0).get_node("Cooldown") as Label
    primary.text = "%.1f" % player_ref.primary_cooldown if player_ref.primary_cooldown > 0.05 else ""
    var power := power_slots.get_child(1).get_node("Cooldown") as Label
    var remaining := player_ref.get_power_cooldown()
    power.text = "%.1f" % remaining if remaining > 0.05 else ""

func _roman(value: int) -> String:
    match value:
        1: return "I"
        2: return "II"
        3: return "III"
        4: return "IV"
        5: return "V"
        _: return str(value)
