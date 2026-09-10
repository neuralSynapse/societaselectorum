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

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    message.visible = false
    message_backdrop.visible = false
    acquired_panel.visible = false

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
    boss_power.text = power_name.to_upper()

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
    for key in ["arcana", "pharmakon", "sigillum", "instrumentum", "daimon", "route"]:
        var value := String(build.get(key, ""))
        if not value.is_empty():
            labels.append(value.replace("_", " ").to_upper())
    var mutations: Array = build.get("mutations", [])
    if not mutations.is_empty():
        labels.append("MUTAÇÕES %d" % mutations.size())
    build_label.text = " · ".join(labels) if not labels.is_empty() else "VONTADE SEM FORMA"

func set_kinesis_loadout(loadout: Array) -> void:
    var labels: Array[String] = []
    for i in range(loadout.size()):
        var value := String(loadout[i])
        if not value.is_empty():
            labels.append("%d %s" % [i + 1, value.replace("_", " ").to_upper()])
    kinesis_state.text = "KINESIS  " + "  ·  ".join(labels)

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
    acquired_hide_timer = 4.2
    var tween := create_tween()
    tween.tween_property(acquired_panel, "modulate:a", 1.0, 0.18)
    tween.tween_interval(3.4)
    tween.tween_property(acquired_panel, "modulate:a", 0.0, 0.48)

func push_reward(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.add_theme_color_override("font_color", Color(0.88, 0.75, 0.52, 1.0))
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    label.add_theme_font_size_override("font_size", 14)
    reward_feed.add_child(label)
    while reward_feed.get_child_count() > 5:
        reward_feed.get_child(0).queue_free()
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
        return
    var marker := _create_enemy_marker(enemy)
    enemy_markers.add_child(marker)
    tracked_enemies[id] = {"enemy": enemy, "marker": marker, "boss": false}

func untrack_enemy(enemy: Node) -> void:
    if enemy == null:
        return
    var id := enemy.get_instance_id()
    if not tracked_enemies.has(id):
        return
    var entry: Dictionary = tracked_enemies[id]
    var marker: Control = entry.get("marker") as Control
    if marker != null and is_instance_valid(marker):
        marker.queue_free()
    tracked_enemies.erase(id)

func show_choice(title: String, options: Array, callback: Callable) -> void:
    for child in choice_options.get_children():
        child.queue_free()
    choice_title.text = title
    choice_callback = callback
    for i in range(options.size()):
        var button := Button.new()
        button.text = String(options[i])
        button.custom_minimum_size = Vector2(0, 54)
        button.add_theme_font_size_override("font_size", 16)
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
        var entry: Dictionary = tracked_enemies.get(id, {})
        var marker: Control = entry.get("marker") as Control
        if marker != null and is_instance_valid(marker):
            marker.queue_free()
        tracked_enemies.erase(id)

func _update_power_cooldowns() -> void:
    if player_ref == null or not is_instance_valid(player_ref) or power_slots.get_child_count() < 2:
        return
    var primary := power_slots.get_child(0).get_node("Cooldown") as Label
    primary.text = "%.1f" % player_ref.primary_cooldown if player_ref.primary_cooldown > 0.05 else ""
    var power := power_slots.get_child(1).get_node("Cooldown") as Label
    power.text = "%.1f" % player_ref.get_power_cooldown() if player_ref.has_method("get_power_cooldown") and player_ref.get_power_cooldown() > 0.05 else ""

func _roman(value: int) -> String:
    match value:
        1: return "I"
        2: return "II"
        3: return "III"
        4: return "IV"
        5: return "V"
        _: return str(value)
