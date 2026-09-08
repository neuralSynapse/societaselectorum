extends CanvasLayer
class_name HUDController

@onready var objective: Label = $Root/Objective
@onready var life: ProgressBar = $Root/Life
@onready var focus: ProgressBar = $Root/Focus
@onready var essence: Label = $Root/Essence
@onready var identity_panel: PanelContainer = $Root/IdentificationPanel
@onready var identity_name: Label = $Root/IdentificationPanel/VBox/IdentityName
@onready var identity_role: Label = $Root/IdentificationPanel/VBox/IdentityRole
@onready var identity_attack: Label = $Root/IdentificationPanel/VBox/IdentityAttack
@onready var boss_panel: PanelContainer = $Root/BossPanel
@onready var boss_name: Label = $Root/BossPanel/VBox/BossName
@onready var boss_health: ProgressBar = $Root/BossPanel/VBox/BossHealth
@onready var boss_phase: Label = $Root/BossPanel/VBox/BossPhase
@onready var build_label: Label = $Root/BuildState
@onready var message: Label = $Root/Message
@onready var kinesis_state: Label = $Root/KinesisState
@onready var camera_mode: Label = $Root/CameraMode
@onready var choice_panel: PanelContainer = $Root/ChoicePanel
@onready var choice_title: Label = $Root/ChoicePanel/VBox/Title
@onready var choice_options: VBoxContainer = $Root/ChoicePanel/VBox/Options
@onready var pause_panel: PanelContainer = $Root/PausePanel

var choice_callback: Callable
var hide_timer := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    if hide_timer > 0.0:
        hide_timer -= delta
        if hide_timer <= 0.0:
            message.visible = false

func bind_player(player: PlayerController) -> void:
    life.max_value = player.health.max_health
    life.value = player.health.current_health
    focus.max_value = player.max_focus
    focus.value = player.focus
    essence.text = "ESSÊNCIA %d" % player.essence
    player.health.damaged.connect(func(current, _maximum, _amount, _source): life.value = current)
    player.health.healed.connect(func(current, _maximum, _amount): life.value = current)
    player.focus_changed.connect(func(current, _maximum): focus.value = current)
    player.essence_changed.connect(func(value): essence.text = "ESSÊNCIA %d" % value)
    RogueliteContentService.build_changed.connect(func(_build): refresh_build())
    refresh_build()

func set_objective(text: String) -> void:
    objective.text = text

func set_pause_visible(value: bool) -> void:
    pause_panel.visible = value

func show_identification(display_name: String, role: String, attack_name: String) -> void:
    identity_name.text = display_name.to_upper()
    identity_role.text = role.to_upper()
    identity_attack.text = attack_name.to_upper()
    identity_panel.visible = true
    var tween := create_tween()
    identity_panel.modulate.a = 1.0
    tween.tween_interval(2.2)
    tween.tween_property(identity_panel, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func(): identity_panel.visible = false)

func show_boss(name: String, hp_ratio: float, phase: int) -> void:
    boss_panel.visible = true
    boss_name.text = name.to_upper()
    boss_health.value = clampf(hp_ratio, 0.0, 1.0) * 100.0
    boss_phase.text = "FASE %d" % phase

func hide_boss() -> void:
    boss_panel.visible = false

func show_message(text: String, duration := 2.5) -> void:
    message.text = text
    message.visible = true
    hide_timer = duration

func refresh_build() -> void:
    var build := RogueliteContentService.ensure_build()
    var instrument: Dictionary = build.get("instrumentum", {})
    build_label.text = "ARCANO %s   PHARMAKON %s   SIGILLUM %s   INSTRUMENTUM %s   DAIMON %s   ROTA %s" % [
        _short(build.get("arcana", "—")), _short(build.get("pharmakon", "—")),
        _short(build.get("sigillum", "—")), _short(instrument.get("id", "—")),
        _short(build.get("daimon", "—")), _short(GameState.route_state.get("route", "student"))]

func _short(value) -> String:
    var s := String(value)
    if s.is_empty(): return "—"
    return s.replace("_", " ").to_upper()

func set_kinesis_loadout(loadout: Array) -> void:
    var slots := ["—", "—", "—"]
    for i in mini(3, loadout.size()): slots[i] = _short(loadout[i])
    kinesis_state.text = "KINESIS  1 %s   2 %s   3 %s" % slots

func set_camera_mode(mode: StringName) -> void:
    camera_mode.text = "CÂMERA · %s" % ("PRIMEIRA PESSOA" if mode == &"first_person" else "SOBRE O OMBRO")

func show_choice(title: String, options: Array, callback: Callable) -> void:
    choice_title.text = title
    choice_callback = callback
    for child in choice_options.get_children(): child.queue_free()
    for i in options.size():
        var button := Button.new()
        button.text = String(options[i])
        button.pressed.connect(_on_choice_pressed.bind(i))
        choice_options.add_child(button)
    choice_panel.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_choice_pressed(index: int) -> void:
    choice_panel.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if choice_callback.is_valid(): choice_callback.call(index)
