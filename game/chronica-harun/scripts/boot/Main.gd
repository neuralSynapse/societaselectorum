extends Node3D

@onready var world_root: Node3D = $WorldRoot
@onready var ui_root: CanvasLayer = $UIRoot
@onready var stage_director: StageDirector = $StageDirector
@onready var world_expansion: WorldExpansionRuntime = $WorldExpansionRuntime
@onready var narrative_runtime: NarrativeRuntimeBridge = $NarrativeRuntime

var gameplay_enabled := false
var pause_active := false
var campaign_booted := false
var pending_snapshot: Dictionary = {}
var canonical_boot_gate: CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    pending_snapshot = SaveService.load_campaign()
    world_root.visible = false
    ui_root.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _show_canonical_boot_gate(not pending_snapshot.is_empty())

func _show_canonical_boot_gate(has_save: bool) -> void:
    if canonical_boot_gate != null:
        canonical_boot_gate.queue_free()
    canonical_boot_gate = CanvasLayer.new()
    canonical_boot_gate.name = "CanonicalBootGate"
    canonical_boot_gate.layer = 120
    add_child(canonical_boot_gate)

    var backdrop := ColorRect.new()
    backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color("050604")
    backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    canonical_boot_gate.add_child(backdrop)

    var halo := ColorRect.new()
    halo.set_anchors_preset(Control.PRESET_CENTER)
    halo.offset_left = -410.0
    halo.offset_top = -330.0
    halo.offset_right = 410.0
    halo.offset_bottom = 330.0
    halo.color = Color(0.09, 0.055, 0.025, 0.94)
    backdrop.add_child(halo)

    var border := Panel.new()
    border.set_anchors_preset(Control.PRESET_CENTER)
    border.offset_left = -388.0
    border.offset_top = -308.0
    border.offset_right = 388.0
    border.offset_bottom = 308.0
    var border_style := StyleBoxFlat.new()
    border_style.bg_color = Color(0.025, 0.025, 0.021, 0.98)
    border_style.border_color = Color("C9933A")
    border_style.set_border_width_all(1)
    border_style.corner_radius_top_left = 12
    border_style.corner_radius_top_right = 12
    border_style.corner_radius_bottom_left = 12
    border_style.corner_radius_bottom_right = 12
    border.add_theme_stylebox_override("panel", border_style)
    backdrop.add_child(border)

    var stack := VBoxContainer.new()
    stack.set_anchors_preset(Control.PRESET_FULL_RECT)
    stack.offset_left = 54.0
    stack.offset_top = 42.0
    stack.offset_right = -54.0
    stack.offset_bottom = -42.0
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", 13)
    border.add_child(stack)

    var institution := Label.new()
    institution.text = "SOCIETAS ELECTORUM · MUNDUS"
    institution.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    institution.add_theme_color_override("font_color", Color("C9933A"))
    institution.add_theme_font_size_override("font_size", 17)
    stack.add_child(institution)

    var title := Label.new()
    title.text = "CHRONICA HARUN"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", Color("F0CF83"))
    title.add_theme_font_size_override("font_size", 38)
    stack.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "PRIMEIRA PESSOA · ROGUELITE NARRATIVO INICIÁTICO"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_color_override("font_color", Color("F2E7D2"))
    subtitle.add_theme_font_size_override("font_size", 13)
    stack.add_child(subtitle)

    var rule := HSeparator.new()
    rule.custom_minimum_size = Vector2(0, 16)
    stack.add_child(rule)

    var invocation := Label.new()
    invocation.text = "“O Limiar não se abre. Ele reconhece.”"
    invocation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    invocation.add_theme_color_override("font_color", Color("F2E7D2"))
    invocation.add_theme_font_size_override("font_size", 20)
    stack.add_child(invocation)

    var continuity := Label.new()
    continuity.text = "Cosmogênese → Origem de Harun → Jornada do Estudante → Provas → Autoridades → Yaldabaoth"
    continuity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    continuity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    continuity.add_theme_color_override("font_color", Color(0.76, 0.69, 0.59, 1.0))
    continuity.add_theme_font_size_override("font_size", 14)
    stack.add_child(continuity)

    var new_campaign := Button.new()
    new_campaign.text = "NOVA CAMPANHA · CICLO 0"
    new_campaign.custom_minimum_size = Vector2(0, 54)
    new_campaign.add_theme_font_size_override("font_size", 17)
    new_campaign.pressed.connect(_start_new_campaign_from_gate)
    stack.add_child(new_campaign)

    var continue_campaign := Button.new()
    continue_campaign.text = "CONTINUAR"
    continue_campaign.custom_minimum_size = Vector2(0, 48)
    continue_campaign.disabled = not has_save
    continue_campaign.add_theme_font_size_override("font_size", 16)
    continue_campaign.pressed.connect(_continue_campaign_from_gate)
    stack.add_child(continue_campaign)

    var controls := Label.new()
    controls.text = "WASD mover · mouse olhar · clique para capturar a câmera · LMB atacar · RMB poder · Espaço esquiva · Esc pausa"
    controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls.add_theme_color_override("font_color", Color(0.64, 0.59, 0.51, 1.0))
    controls.add_theme_font_size_override("font_size", 12)
    stack.add_child(controls)

    var author := Label.new()
    author.text = "Obra: Frater Horus Phosphorus · Harun é personagem canônico"
    author.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    author.add_theme_color_override("font_color", Color("C9933A"))
    author.add_theme_font_size_override("font_size", 12)
    stack.add_child(author)

func _start_new_campaign_from_gate() -> void:
    if campaign_booted:
        return
    SaveService.delete_campaign()
    GameState.start_new_campaign()
    SaveService.save_campaign(GameState.to_save_data())
    _boot_campaign_runtime()

func _continue_campaign_from_gate() -> void:
    if campaign_booted:
        return
    if pending_snapshot.is_empty():
        _start_new_campaign_from_gate()
        return
    GameState.load_save_data(pending_snapshot)
    _boot_campaign_runtime()

func _boot_campaign_runtime() -> void:
    if campaign_booted:
        return
    campaign_booted = true
    if canonical_boot_gate != null:
        canonical_boot_gate.queue_free()
        canonical_boot_gate = null
    world_root.visible = true
    ui_root.visible = true
    stage_director.stage_completed.connect(_on_stage_completed)
    stage_director.configure(world_root, ui_root)
    world_expansion.configure_player(stage_director.player)
    stage_director.attach_world_expansion(world_expansion)
    world_expansion.on_stage_started(GameState.current_stage_id)
    narrative_runtime.bind_stage_director(stage_director)
    if not narrative_runtime.cinematic_sequence_started.is_connected(_on_cinematic_sequence_started):
        narrative_runtime.cinematic_sequence_started.connect(_on_cinematic_sequence_started)
    if not narrative_runtime.gameplay_handoff_requested.is_connected(_on_gameplay_handoff):
        narrative_runtime.gameplay_handoff_requested.connect(_on_gameplay_handoff)
    var entry_sequence := narrative_runtime.start_entry_flow()
    var blocking_entry := _cinematic_can_take_player_control() and (entry_sequence == &"cosmogony" or entry_sequence == &"harun_origin" or entry_sequence == &"epilogue")
    _set_gameplay_enabled(not blocking_entry)
    if not blocking_entry and stage_director.hud != null and OS.has_feature("web"):
        stage_director.hud.show_message("CLIQUE NA CENA PARA CAPTURAR A CÂMERA", 5.5)

func _unhandled_input(event: InputEvent) -> void:
    if not campaign_booted:
        return
    if event.is_action_pressed("pause") and gameplay_enabled:
        set_pause_state(not pause_active)
        get_viewport().set_input_as_handled()

func set_pause_state(paused: bool) -> void:
    pause_active = paused
    if stage_director != null and stage_director.hud != null:
        stage_director.hud.set_pause_visible(paused)
    get_tree().paused = paused
    if paused:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif OS.has_feature("web"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        if stage_director != null and stage_director.hud != null:
            stage_director.hud.show_message("CLIQUE NA CENA PARA RETOMAR A CÂMERA", 3.5)
    else:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
    if get_tree() != null:
        get_tree().paused = false

func _cinematic_can_take_player_control() -> bool:
    return narrative_runtime != null and narrative_runtime.cinematic_stage != null and narrative_runtime.cinematic_stage.can_take_player_control()

func _set_gameplay_enabled(enabled: bool) -> void:
    gameplay_enabled = enabled
    if not enabled and pause_active:
        set_pause_state(false)
    world_root.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
    world_root.visible = enabled
    if stage_director.player != null:
        stage_director.player.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
        if stage_director.player.camera != null:
            stage_director.player.camera.current = enabled
    if stage_director.hud != null:
        stage_director.hud.visible = enabled
    if enabled:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if OS.has_feature("web") else Input.MOUSE_MODE_CAPTURED
    else:
        Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_cinematic_sequence_started(_sequence_id: StringName, _sequence: Dictionary) -> void:
    if _cinematic_can_take_player_control():
        _set_gameplay_enabled(false)

func _on_gameplay_handoff(_target_stage: StringName) -> void:
    world_root.visible = true
    if stage_director.player != null and stage_director.player.camera != null:
        if _cinematic_can_take_player_control():
            narrative_runtime.cinematic_stage.prepare_gameplay_handoff(stage_director.player.camera)
            await get_tree().process_frame
            narrative_runtime.cinematic_stage.release_camera()
        stage_director.player.camera.make_current()
    _set_gameplay_enabled(true)
    if stage_director.hud != null and OS.has_feature("web"):
        stage_director.hud.show_message("CLIQUE NA CENA PARA CONTROLAR A CÂMERA", 4.0)

func _on_stage_completed(stage_id: StringName, _summary: Dictionary) -> void:
    world_expansion.on_boss_defeated(stage_id)
