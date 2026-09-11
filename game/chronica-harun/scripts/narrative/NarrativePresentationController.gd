extends CanvasLayer
class_name NarrativePresentationController

signal advance_requested
signal skip_requested
signal choice_selected(option_id: StringName)

@onready var scene_title: Label = $Root/SceneTitle
@onready var subtitle: Label = $Root/Subtitle
@onready var skip_hint: Label = $Root/SkipHint
@onready var story_message: Label = $Root/StoryMessage
@onready var choice_modal_dimmer: ColorRect = $Root/ChoiceDimmer
@onready var choice_panel: PanelContainer = $Root/ChoicePanel
@onready var choice_prompt: Label = $Root/ChoicePanel/Margin/Column/ChoicePrompt
@onready var choice_options: VBoxContainer = $Root/ChoicePanel/Margin/Column/ChoiceOptions
@onready var choice_consequence: Label = $Root/ChoicePanel/Margin/Column/ChoiceConsequence
@onready var cinematic_veil: ColorRect = $Root/CinematicVeil
@onready var fragment_status: Label = $Root/FragmentStatus
@onready var reveal_label: Label = $Root/RevealLabel
@onready var evidence_label: Label = $Root/EvidenceLabel
@onready var blackout: ColorRect = $Root/Blackout

var lines: Array = []
var line_index := -1
var seconds_per_line := 3.0
var line_timer := 0.0
var message_timer := 0.0
var reveal_timer := 0.0
var fragment_timer := 0.0
var bridge: NarrativeRuntimeBridge
var choice_locked := false
var choice_option_ids: Array[StringName] = []
var paused_before_choice := false
var cinematic_sequence_active := false
var skip_available := false
var first_entry_flow_locked := true
var final_black_active := false

func _ready() -> void:
    visible = false
    blackout.visible = false
    cinematic_veil.visible = false
    choice_modal_dimmer.visible = false
    reveal_label.visible = false
    fragment_status.visible = false
    evidence_label.visible = false
    call_deferred("_bind_parent_bridge")

func _bind_parent_bridge() -> void:
    var parent_bridge := get_parent() as NarrativeRuntimeBridge
    if parent_bridge != null:
        bind_bridge(parent_bridge)

func bind_bridge(next_bridge: NarrativeRuntimeBridge) -> void:
    bridge = next_bridge
    if not bridge.narration_lines.is_connected(present_lines):
        bridge.narration_lines.connect(present_lines)
    if not bridge.story_message.is_connected(show_story_message):
        bridge.story_message.connect(show_story_message)
    if not bridge.scene_title_requested.is_connected(set_scene_title):
        bridge.scene_title_requested.connect(set_scene_title)
    if not bridge.cinematic_visual.is_connected(present_shot_mode):
        bridge.cinematic_visual.connect(present_shot_mode)
    if not bridge.cinematic_sequence_started.is_connected(_on_cinematic_sequence_started):
        bridge.cinematic_sequence_started.connect(_on_cinematic_sequence_started)
    if not bridge.cinematic_sequence_finished.is_connected(_on_cinematic_sequence_finished):
        bridge.cinematic_sequence_finished.connect(_on_cinematic_sequence_finished)
    if not bridge.fragment_progress.is_connected(show_fragment_progress):
        bridge.fragment_progress.connect(show_fragment_progress)
    if not bridge.grimorium_title_reveal.is_connected(show_title_reveal):
        bridge.grimorium_title_reveal.connect(show_title_reveal)
    if not bridge.command_reveal.is_connected(show_command_reveal):
        bridge.command_reveal.connect(show_command_reveal)
    if not bridge.final_black_requested.is_connected(enter_final_black):
        bridge.final_black_requested.connect(enter_final_black)
    if not bridge.gameplay_handoff_requested.is_connected(_on_gameplay_handoff):
        bridge.gameplay_handoff_requested.connect(_on_gameplay_handoff)
    if not bridge.story_state_saved.is_connected(_on_story_state_saved):
        bridge.story_state_saved.connect(_on_story_state_saved)
    if not bridge.narrative_choices.choice_requested.is_connected(present_choice):
        bridge.narrative_choices.choice_requested.connect(present_choice)
    if not bridge.narrative_choices.choice_resolved.is_connected(_on_choice_resolved):
        bridge.narrative_choices.choice_resolved.connect(_on_choice_resolved)
    if not choice_selected.is_connected(bridge.narrative_choices.choose):
        choice_selected.connect(bridge.narrative_choices.choose)
    if not advance_requested.is_connected(bridge.advance_active_sequence):
        advance_requested.connect(bridge.advance_active_sequence)
    if not skip_requested.is_connected(bridge.skip_active_sequence):
        skip_requested.connect(bridge.skip_active_sequence)
    skip_available = bool(bridge.current_story_state().get("skip_unlocked", false))
    first_entry_flow_locked = not skip_available
    set_skip_available(skip_available)

func present_lines(next_lines: Array, duration_seconds: float) -> void:
    lines = next_lines.duplicate(true)
    line_index = -1
    seconds_per_line = maxf(1.2, duration_seconds / maxf(1.0, float(lines.size())))
    line_timer = 0.0
    visible = true
    if not lines.is_empty():
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
    skip_available = value
    var show_hint := value and not first_entry_flow_locked
    skip_hint.visible = show_hint
    skip_hint.text = "ESC · PULAR" if show_hint else ""

func present_shot_mode(payload: Dictionary) -> void:
    var subtitle_mode := String(payload.get("subtitle_mode", "voiceover"))
    if subtitle_mode == "silence":
        subtitle.text = ""
        subtitle.visible = false
    else:
        subtitle.visible = true
    if not _has_player_facing_cinematic_visuals():
        cinematic_veil.visible = false
        blackout.visible = false
        return
    begin_transition(StringName(payload.get("transition", "cut")), float(payload.get("tension", 0.0)))
    if OS.is_debug_build():
        evidence_label.text = "%s · %s · %s" % [
            String(payload.get("sequence_id", "cinematic")),
            String(payload.get("shot_id", "shot")),
            String(payload.get("transition", "cut")),
        ]
        evidence_label.visible = true

func begin_transition(kind: StringName, tension: float = 0.0) -> void:
    if final_black_active or not _has_player_facing_cinematic_visuals():
        cinematic_veil.visible = false
        blackout.visible = false
        return
    visible = true
    cinematic_veil.visible = true
    cinematic_veil.color = Color(0.025, 0.018, 0.045, 0.08 + clampf(tension, 0.0, 1.0) * 0.16)
    match String(kind):
        "fade_from_black":
            blackout.visible = true
            blackout.color = Color(0, 0, 0, 1)
            var tween := create_tween()
            tween.tween_property(blackout, "color", Color(0, 0, 0, 0), 1.15)
            tween.tween_callback(func(): blackout.visible = false)
        "match_cut":
            blackout.visible = true
            blackout.color = Color(0, 0, 0, 0.16)
            var tween := create_tween()
            tween.tween_property(blackout, "color", Color(0, 0, 0, 0), 0.18)
            tween.tween_callback(func(): blackout.visible = false)
        "slow_dissolve", "focus_pull":
            cinematic_veil.color = Color(0.025, 0.018, 0.045, 0.24)
            var tween := create_tween()
            tween.tween_property(cinematic_veil, "color", Color(0.025, 0.018, 0.045, 0.1), 1.25)
        "hard_reframe":
            blackout.visible = true
            blackout.color = Color(0, 0, 0, 0.28)
            var tween := create_tween()
            tween.tween_property(blackout, "color", Color(0, 0, 0, 0), 0.12)
            tween.tween_callback(func(): blackout.visible = false)
        "hard_cut_to_black":
            cinematic_veil.color = Color(0.0, 0.0, 0.0, 0.18)
        _:
            pass

func show_fragment_progress(_fragment_id: StringName, current: int, required: int) -> void:
    fragment_status.text = "FRAGMENTOS · %d / %d" % [current, required]
    fragment_status.visible = true
    fragment_timer = 3.0
    visible = true

func show_title_reveal(text: String) -> void:
    reveal_label.text = text
    reveal_label.visible = true
    reveal_label.modulate = Color(1, 1, 1, 0)
    reveal_timer = 4.0
    visible = true
    var tween := create_tween()
    tween.tween_property(reveal_label, "modulate", Color(1, 1, 1, 1), 0.65)

func show_command_reveal(command: StringName, index: int) -> void:
    reveal_label.text = String(command)
    reveal_label.visible = true
    reveal_label.modulate = Color(1, 1, 1, 1)
    reveal_label.add_theme_font_size_override("font_size", 54 + index * 4)
    reveal_timer = 1.35
    visible = true

func enter_final_black(final_word: String = "LUCIFER") -> void:
    final_black_active = true
    visible = true
    cinematic_sequence_active = true
    scene_title.visible = false
    subtitle.visible = false
    story_message.visible = false
    fragment_status.visible = false
    evidence_label.visible = false
    skip_hint.visible = false
    reveal_label.text = final_word
    reveal_label.visible = true
    reveal_label.modulate = Color(1, 1, 1, 1)
    blackout.visible = true
    blackout.color = Color(0, 0, 0, 0)
    await get_tree().create_timer(1.25, true).timeout
    var tween := create_tween()
    tween.tween_property(blackout, "color", Color(0, 0, 0, 1), 0.18)
    await tween.finished
    reveal_label.visible = false
    cinematic_veil.visible = false

func release_to_gameplay(_target_stage: StringName = &"") -> void:
    final_black_active = false
    cinematic_sequence_active = false
    lines.clear()
    line_index = -1
    subtitle.text = ""
    subtitle.visible = false
    scene_title.visible = false
    story_message.visible = false
    fragment_status.visible = false
    reveal_label.visible = false
    evidence_label.visible = false
    cinematic_veil.visible = false
    blackout.visible = false
    choice_modal_dimmer.visible = false
    choice_panel.visible = false
    visible = false

func present_choice(_stage_id: StringName, choice: Dictionary) -> void:
    choice_locked = false
    choice_option_ids.clear()
    paused_before_choice = get_tree().paused
    get_tree().paused = true
    visible = true
    choice_modal_dimmer.visible = true
    choice_panel.visible = true
    choice_prompt.text = String(choice.get("prompt", "Escolha."))
    choice_consequence.visible = false
    choice_consequence.text = ""
    for child in choice_options.get_children():
        child.queue_free()
    var index := 0
    for option_value in choice.get("options", []):
        if not (option_value is Dictionary):
            continue
        var option: Dictionary = option_value
        var option_id := StringName(option.get("id", ""))
        choice_option_ids.append(option_id)
        choice_options.add_child(_build_choice_card(option, index, option_id))
        index += 1
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_choice_card(option: Dictionary, index: int, option_id: StringName) -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(0, 132)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.014, 0.021, 0.98)
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.58, 0.43, 0.22, 0.88)
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    panel.add_theme_stylebox_override("panel", style)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 5)
    margin.add_child(column)

    var button := Button.new()
    button.name = "ChoiceButton"
    button.text = "%d · %s" % [index + 1, String(option.get("label", "Escolher"))]
    button.custom_minimum_size = Vector2(0, 46)
    button.add_theme_font_size_override("font_size", 17)
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    button.pressed.connect(func(): _select_choice(option_id))
    column.add_child(button)

    var cost := Label.new()
    cost.text = "CUSTO IMEDIATO · %s" % String(option.get("immediate_cost", "Nenhum custo explícito."))
    cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    cost.add_theme_font_size_override("font_size", 13)
    cost.add_theme_color_override("font_color", Color(0.83, 0.66, 0.43, 1.0))
    column.add_child(cost)

    var consequence := Label.new()
    consequence.text = "CONSEQUÊNCIA · %s" % String(option.get("story_consequence", "A escolha altera a rota narrativa."))
    consequence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    consequence.add_theme_font_size_override("font_size", 13)
    consequence.add_theme_color_override("font_color", Color(0.72, 0.69, 0.66, 1.0))
    column.add_child(consequence)
    return panel

func resolve_choice(option: Dictionary) -> void:
    choice_locked = true
    choice_consequence.text = "ESCOLHA REGISTRADA · %s" % String(option.get("story_consequence", "A escolha foi registrada."))
    choice_consequence.visible = true
    _set_choice_buttons_disabled(choice_options, true)
    var timer := get_tree().create_timer(2.4, true)
    timer.timeout.connect(_finish_choice_display)

func _set_choice_buttons_disabled(node: Node, disabled: bool) -> void:
    for child in node.get_children():
        if child is Button:
            (child as Button).disabled = disabled
        _set_choice_buttons_disabled(child, disabled)

func _select_choice(option_id: StringName) -> void:
    if choice_locked:
        return
    choice_locked = true
    choice_selected.emit(option_id)

func _on_choice_resolved(_stage_id: StringName, _choice_id: StringName, option: Dictionary) -> void:
    resolve_choice(option)

func _finish_choice_display() -> void:
    choice_panel.visible = false
    choice_modal_dimmer.visible = false
    get_tree().paused = paused_before_choice
    choice_option_ids.clear()
    if OS.has_feature("web"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        show_story_message("CLIQUE NA CENA PARA RETOMAR A CÂMERA", 2.6)
    else:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _has_player_facing_cinematic_visuals() -> bool:
    return bridge != null and bridge.cinematic_stage != null and bridge.cinematic_stage.can_take_player_control()

func _on_cinematic_sequence_started(_sequence_id: StringName, _sequence: Dictionary) -> void:
    cinematic_sequence_active = true
    visible = true
    if not _has_player_facing_cinematic_visuals():
        cinematic_veil.visible = false
        blackout.visible = false
        return
    cinematic_veil.visible = true

func _on_cinematic_sequence_finished(_sequence_id: StringName) -> void:
    if not _has_player_facing_cinematic_visuals():
        cinematic_veil.visible = false
        blackout.visible = false

func _on_gameplay_handoff(target_stage: StringName) -> void:
    release_to_gameplay(target_stage)

func _on_story_state_saved(state: Dictionary) -> void:
    if first_entry_flow_locked:
        return
    set_skip_available(bool(state.get("skip_unlocked", false)))

func _process(delta: float) -> void:
    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0:
            story_message.visible = false
    if reveal_timer > 0.0:
        reveal_timer -= delta
        if reveal_timer <= 0.0 and not final_black_active:
            reveal_label.visible = false
    if fragment_timer > 0.0:
        fragment_timer -= delta
        if fragment_timer <= 0.0:
            fragment_status.visible = false
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
        if cinematic_sequence_active and first_entry_flow_locked:
            return
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
