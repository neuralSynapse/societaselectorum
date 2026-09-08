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
    begin_transition(StringName(payload.get("transition", "cut")), float(payload.get("tension", 0.0)))
    if OS.is_debug_build():
        evidence_label.text = "%s · %s · %s" % [
            String(payload.get("sequence_id", "cinematic")),
            String(payload.get("shot_id", "shot")),
            String(payload.get("transition", "cut")),
        ]
        evidence_label.visible = true

func begin_transition(kind: StringName, tension: float = 0.0) -> void:
    if final_black_active:
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
    visible = false

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

func _on_cinematic_sequence_started(_sequence_id: StringName, _sequence: Dictionary) -> void:
    cinematic_sequence_active = true
    visible = true
    cinematic_veil.visible = true

func _on_cinematic_sequence_finished(_sequence_id: StringName) -> void:
    pass

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
