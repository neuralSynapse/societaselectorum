extends Node3D

@onready var world_root: Node3D = $WorldRoot
@onready var ui_root: CanvasLayer = $UIRoot
@onready var stage_director: StageDirector = $StageDirector
@onready var world_expansion: WorldExpansionRuntime = $WorldExpansionRuntime
@onready var narrative_runtime: NarrativeRuntimeBridge = $NarrativeRuntime

var gameplay_enabled := true
var pause_active := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    var snapshot := SaveService.load_campaign()
    if snapshot.is_empty():
        GameState.start_new_campaign()
    else:
        GameState.load_save_data(snapshot)
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

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") and gameplay_enabled:
        set_pause_state(not pause_active)
        get_viewport().set_input_as_handled()

func set_pause_state(paused: bool) -> void:
    pause_active = paused
    if stage_director != null and stage_director.hud != null:
        stage_director.hud.set_pause_visible(paused)
    get_tree().paused = paused
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

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
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_HIDDEN

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

func _on_stage_completed(stage_id: StringName, _summary: Dictionary) -> void:
    world_expansion.on_boss_defeated(stage_id)
