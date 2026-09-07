extends CanvasLayer
class_name NarrativePresentationController

signal advance_requested
signal skip_requested
signal choice_selected(option_id: StringName)

@onready var scene_title: Label = $Root/SceneTitle
@onready var subtitle: Label = $Root/Subtitle
@onready var skip_hint: Label = $Root/SkipHint
@onready var story_message: Label = $Root/StoryMessage
@onready var choice_panel: PanelContainer = $Root/ChoicePanel
@onready var choice_prompt: Label = $Root/ChoicePanel/Margin/Column/ChoicePrompt
@onready var choice_options: VBoxContainer = $Root/ChoicePanel/Margin/Column/ChoiceOptions
@onready var choice_consequence: Label = $Root/ChoicePanel/Margin/Column/ChoiceConsequence

var lines: Array = []
var line_index := -1
var seconds_per_line := 3.0
var line_timer := 0.0
var message_timer := 0.0
var bridge: NarrativeRuntimeBridge
var choice_locked := false
var choice_option_ids: Array[StringName] = []
var paused_before_choice := false

func _ready() -> void:
    visible = false
    var parent_bridge := get_parent() as NarrativeRuntimeBridge
    if parent_bridge:
        bind_bridge(parent_bridge)

func bind_bridge(next_bridge: NarrativeRuntimeBridge) -> void:
    bridge = next_bridge
    if not bridge.narration_lines.is_connected(present_lines):
        bridge.narration_lines.connect(present_lines)
    if not bridge.story_message.is_connected(show_story_message):
        bridge.story_message.connect(show_story_message)
    if not bridge.scene_title_requested.is_connected(set_scene_title):
        bridge.scene_title_requested.connect(set_scene_title)
    if not bridge.narrative_choices.choice_requested.is_connected(present_choice):
        bridge.narrative_choices.choice_requested.connect(present_choice)
    if not bridge.narrative_choices.choice_resolved.is_connected(_on_choice_resolved):
        bridge.narrative_choices.choice_resolved.connect(_on_choice_resolved)
    if not choice_selected.is_connected(bridge.narrative_choices.choose):
        choice_selected.connect(bridge.narrative_choices.choose)
    advance_requested.connect(bridge.advance_active_sequence)
    skip_requested.connect(bridge.skip_active_sequence)
    set_skip_available(bool(bridge.current_story_state().get("skip_unlocked", false)))

func present_lines(next_lines: Array, duration_seconds: float) -> void:
    lines = next_lines.duplicate(true)
    line_index = -1
    seconds_per_line = maxf(1.2, duration_seconds / maxf(1.0, float(lines.size())))
    line_timer = 0.0
    visible = true
    _next_line()

func show_story_message(text: String, duration := 3.0) -> void:
    story_message.text = text
    story_message.visible = true
    message_timer = duration
    visible = true

func set_scene_title(text: String) -> void:
    scene_title.text = text
    scene_title.visible = not text.is_empty()

func set_skip_available(value: bool) -> void:
    skip_hint.visible = value
    skip_hint.text = "ESC · PULAR" if value else ""

func present_choice(_stage_id: StringName, choice: Dictionary) -> void:
    choice_locked = false
    choice_option_ids.clear()
    paused_before_choice = get_tree().paused
    get_tree().paused = true
    visible = true
    choice_panel.visible = true
    choice_prompt.text = String(choice.get("prompt", "Escolha."))
    choice_consequence.visible = false
    choice_consequence.text = ""
    for child in choice_options.get_children():
        child.queue_free()
    for option in choice.get("options", []):
        var button := Button.new()
        button.text = "%s\nCUSTO: %s" % [String(option.get("label", "Escolher")), String(option.get("immediate_cost", "desconhecido"))]
        button.custom_minimum_size = Vector2(0, 64)
        var option_id := StringName(option.get("id", ""))
        choice_option_ids.append(option_id)
        button.pressed.connect(func(): _select_choice(option_id))
        choice_options.add_child(button)

func resolve_choice(option: Dictionary) -> void:
    choice_locked = true
    choice_consequence.text = String(option.get("story_consequence", "A escolha foi registrada."))
    choice_consequence.visible = true
    for child in choice_options.get_children():
        if child is Button:
            child.disabled = true
    var timer := get_tree().create_timer(2.4, true)
    timer.timeout.connect(_finish_choice_display)

func _select_choice(option_id: StringName) -> void:
    if choice_locked:
        return
    choice_locked = true
    choice_selected.emit(option_id)

func _on_choice_resolved(_stage_id: StringName, _choice_id: StringName, option: Dictionary) -> void:
    resolve_choice(option)

func _finish_choice_display() -> void:
    choice_panel.visible = false
    get_tree().paused = paused_before_choice
    choice_option_ids.clear()

func _process(delta: float) -> void:
    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0:
            story_message.visible = false
    if lines.is_empty():
        return
    line_timer -= delta
    if line_timer <= 0.0:
        _next_line()

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if choice_panel.visible:
        if event is InputEventKey and event.pressed and not event.echo:
            var key := event as InputEventKey
            if key.keycode == KEY_1 and choice_option_ids.size() >= 1:
                _select_choice(choice_option_ids[0])
            elif key.keycode == KEY_2 and choice_option_ids.size() >= 2:
                _select_choice(choice_option_ids[1])
            elif key.keycode == KEY_3 and choice_option_ids.size() >= 3:
                _select_choice(choice_option_ids[2])
        return
    if event.is_action_pressed("ui_accept"):
        if lines.is_empty():
            advance_requested.emit()
        else:
            _next_line()
    elif event.is_action_pressed("ui_cancel") and skip_hint.visible:
        skip_requested.emit()

func _next_line() -> void:
    line_index += 1
    if line_index >= lines.size():
        lines.clear()
        subtitle.text = ""
        advance_requested.emit()
        return
    subtitle.text = String(lines[line_index])
    line_timer = seconds_per_line
