extends Node
class_name WorldExpansionRuntime

@onready var eden_mortis: EdenMortisDirector = $EdenMortisDirector
@onready var temporal_rifts: TemporalRiftDirector = $TemporalRiftDirector
@onready var mentors: MentorDirector = $MentorDirector
@onready var sanctum: CharacterSanctumDirector = $CharacterSanctumDirector
@onready var kinesis: KinesisProgressionDirector = $KinesisProgressionDirector
@onready var quantum: QuantumRiftDirector = $QuantumRiftDirector
@onready var arsenal: RitualArsenalDirector = $RitualArsenalDirector

var camera_modes: CameraModeController
var player: PlayerController

func configure_player(target_player: PlayerController) -> void:
    player = target_player
    camera_modes = CameraModeController.new()
    camera_modes.name = "CameraModeController"
    add_child(camera_modes)
    camera_modes.configure(player)

func on_stage_started(stage_id: StringName) -> Dictionary:
    var mentor := mentors.begin_stage_mentor(stage_id)
    return {
        "stage_id": String(stage_id),
        "mentor": mentor,
        "available_characters": sanctum.available_characters(),
        "kinesis_loadout": kinesis.current_loadout()
    }

func on_room_cleared(room_id: StringName, context: Dictionary = {}) -> Dictionary:
    var result := {"room_id": String(room_id), "mentor_progress": false, "quantum_hint": false}
    if not mentors.active.is_empty():
        var objectives: Array = mentors.active.get("mission", {}).get("objectives", [])
        if objectives.size() > mentors.progress.size():
            result["mentor_progress"] = mentors.complete_mentor_objective(mentors.progress.size())
    var qstate: Dictionary = GameState.meta_progression.get("quantum", {})
    if int(qstate.get("observation_fragments", 0)) >= 2 and not quantum.can_open_lab(context):
        result["quantum_hint"] = true
    return result

func on_boss_defeated(stage_id: StringName) -> Dictionary:
    var result := {"stage_id": String(stage_id), "mentor_complete": false, "eden_opportunity": false, "mortis_opportunity": false}
    if not mentors.active.is_empty():
        var objectives: Array = mentors.active.get("mission", {}).get("objectives", [])
        while mentors.progress.size() < objectives.size():
            mentors.complete_mentor_objective(mentors.progress.size())
        result["mentor_complete"] = mentors.complete_mentor_mission()
    var rng := RandomNumberGenerator.new(); rng.seed = GameState.run_seed + GameState.stage_index * 193
    result["eden_opportunity"] = rng.randf() < .40
    result["mortis_opportunity"] = rng.randf() < .20 or GameState.route_state.get("curses", []).size() >= 2
    return result
