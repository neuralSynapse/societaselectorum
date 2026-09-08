extends Node3D

@onready var world_root: Node3D = $WorldRoot
@onready var ui_root: CanvasLayer = $UIRoot
@onready var stage_director: StageDirector = $StageDirector
@onready var world_expansion: WorldExpansionRuntime = $WorldExpansionRuntime
@onready var narrative_runtime: NarrativeRuntimeBridge = $NarrativeRuntime

var gameplay_enabled := true

func _ready() -> void:
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
    var blocking_entry := entry_sequence == &"cosmogony" or entry_sequence == &"harun_origin" or entry_sequence == &"epilogue"
    _set_gameplay_enabled(not blocking_entry)

func _set_gameplay_enabled(enabled: bool) -> void:
    gameplay_enabled = enabled
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
    _set_gameplay_enabled(false)

func _on_gameplay_handoff(_target_stage: StringName) -> void:
    world_root.visible = true
    if stage_director.player != null and stage_director.player.camera != null:
        narrative_runtime.cinematic_stage.prepare_gameplay_handoff(stage_director.player.camera)
        await get_tree().process_frame
        narrative_runtime.cinematic_stage.release_camera()
        stage_director.player.camera.make_current()
    _set_gameplay_enabled(true)

func _on_stage_completed(stage_id: StringName, _summary: Dictionary) -> void:
    world_expansion.on_boss_defeated(stage_id)
