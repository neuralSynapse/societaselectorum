extends Node

const SAVE_VERSION := 1
const FINAL_NARRATIVE_STATE := "PEREGRINUS_IGNIS_GAME"

var current_stage_id: String = "o_olho"
var stage_index: int = 0
var cycle: int = 0
var journey_state: String = "STUDENT_JOURNEY"
var completion_marks: Dictionary = {}
var run_stats: Dictionary = {}
var run_build: Dictionary = {}

func reset_campaign() -> void:
    current_stage_id = "o_olho"
    stage_index = 0
    cycle = 0
    journey_state = "STUDENT_JOURNEY"
    completion_marks = {}
    run_stats = {}
    run_build = {}

func apply_save(payload: Dictionary) -> void:
    if int(payload.get("save_version", -1)) != SAVE_VERSION:
        return
    current_stage_id = str(payload.get("current_stage_id", current_stage_id))
    stage_index = maxi(0, int(payload.get("stage_index", stage_index)))
    cycle = maxi(0, int(payload.get("cycle", cycle)))
    journey_state = str(payload.get("journey_state", journey_state))
    completion_marks = payload.get("completion_marks", {}).duplicate(true)
    run_stats = payload.get("run_stats", {}).duplicate(true)
    run_build = payload.get("run_build", {}).duplicate(true)

func to_save() -> Dictionary:
    return {
        "save_version": SAVE_VERSION,
        "current_stage_id": current_stage_id,
        "stage_index": stage_index,
        "cycle": cycle,
        "journey_state": journey_state,
        "completion_marks": completion_marks.duplicate(true),
        "run_stats": run_stats.duplicate(true),
        "run_build": run_build.duplicate(true),
    }

func complete_student_journey() -> void:
    stage_index = 15
    current_stage_id = "camara_iniciacao"
    journey_state = FINAL_NARRATIVE_STATE
