extends Node3D

@onready var world_root: Node3D = $WorldRoot
@onready var ui_root: CanvasLayer = $UIRoot
@onready var stage_director: StageDirector = $StageDirector
@onready var world_expansion: WorldExpansionRuntime = $WorldExpansionRuntime

func _ready() -> void:
    var snapshot := SaveService.load_campaign()
    if snapshot.is_empty():
        GameState.start_new_campaign()
    else:
        GameState.load_save_data(snapshot)
    var final_narrative_state := GameState.journey_state == GameState.PEREGRINUS_IGNIS_GAME
    stage_director.stage_completed.connect(_on_stage_completed)
    stage_director.configure(world_root, ui_root)
    if final_narrative_state:
        GameState.current_stage_id = StringName(GameState.PEREGRINUS_IGNIS_GAME)
    world_expansion.configure_player(stage_director.player)
    stage_director.attach_world_expansion(world_expansion)
    world_expansion.on_stage_started(GameState.current_stage_id)

func _on_stage_completed(stage_id: StringName, _summary: Dictionary) -> void:
    world_expansion.on_boss_defeated(stage_id)
