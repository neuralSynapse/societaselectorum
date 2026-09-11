extends Node

const JOURNEY_PORTAL_0 := "PORTAL_0_ASPIRANTE"
const JOURNEY_STUDENT := "STUDENT"
const JOURNEY_DEGREE := "DEGREE"
const LEGACY_JOURNEY_INGRESSUS := "ACTUS_INGRESSUS"
const PEREGRINUS_IGNIS_GAME := "PEREGRINUS_IGNIS_GAME"

var selected_character_id: StringName = &"harun"
var current_stage_id: StringName = &"o_olho"
var stage_index := 0
var cycle := 0
var run_seed := 0
var journey_state := JOURNEY_PORTAL_0
var completion_marks: Dictionary = {}
var completion_marks_by_character: Dictionary = {}
var run_stats: Dictionary = {}
var run_build: Dictionary = {}
var meta_progression: Dictionary = {}
var route_state: Dictionary = {"route":"student","curses":[],"blessings":[],"post_boss_choice":"","gauntlet":""}

func _ready() -> void:
    if run_seed == 0:
        run_seed = int(Time.get_unix_time_from_system())
    if run_stats.is_empty():
        _reset_run_stats()

func start_new_campaign(seed: int = 0) -> void:
    selected_character_id = &"harun"
    current_stage_id = &"o_olho"
    stage_index = 0
    cycle = 0
    journey_state = JOURNEY_PORTAL_0
    completion_marks.clear()
    completion_marks_by_character.clear()
    run_build.clear()
    meta_progression.clear()
    meta_progression["entry_chain"] = "Portal 0 · Aspirante — Initiatio Luciferi → Estudante → I · Peregrinus Ignis"
    route_state = {"route":"student","curses":[],"blessings":[],"post_boss_choice":"","gauntlet":""}
    run_seed = seed if seed != 0 else int(Time.get_unix_time_from_system())
    _reset_run_stats()

func complete_stage(stage_id: StringName) -> bool:
    if journey_state == JOURNEY_DEGREE:
        var current_degree := int(meta_progression.get("degree_current", 0))
        var expected := InitiaticProgressionService.degree_row(current_degree)
        if expected.is_empty() or StringName(expected.get("id", "")) != stage_id:
            return false
        completion_marks[String(stage_id)] = true
        _mark_character_completion(stage_id)
        var degree_result := InitiaticProgressionService.complete_current_degree()
        if degree_result.is_empty():
            return false
        _reset_run_stats()
        return true

    var journey := ContentRegistry.get_base_student_journey()
    if stage_index < 0 or stage_index >= journey.size():
        return false
    var row: Dictionary = journey[stage_index]
    if StringName(row.get("id")) != stage_id or current_stage_id != stage_id:
        return false
    completion_marks[String(stage_id)] = true
    _mark_character_completion(stage_id)

    var next := String(row.get("next_stage", ""))
    if next == PEREGRINUS_IGNIS_GAME or stage_index >= journey.size() - 1:
        meta_progression["student_initiation_completed"] = true
        meta_progression["degree_current"] = maxi(1, int(meta_progression.get("degree_current", 1)))
        journey_state = JOURNEY_DEGREE
        var first_degree := InitiaticProgressionService.degree_row(int(meta_progression["degree_current"]))
        current_stage_id = StringName(first_degree.get("id", "grade_01_peregrinus_ignis"))
    else:
        stage_index += 1
        current_stage_id = StringName(next)
        journey_state = JOURNEY_PORTAL_0 if stage_index <= 2 else JOURNEY_STUDENT
    _reset_run_stats()
    return true

func _mark_character_completion(stage_id: StringName) -> void:
    var character_key := String(selected_character_id)
    if not completion_marks_by_character.has(character_key):
        completion_marks_by_character[character_key] = {}
    completion_marks_by_character[character_key][String(stage_id)] = true

func record_death(cause := "unknown") -> void:
    run_stats["deaths"] = int(run_stats.get("deaths",0)) + 1
    run_stats["last_death_cause"] = cause
    meta_progression["total_deaths"] = int(meta_progression.get("total_deaths",0)) + 1

func to_save_data() -> Dictionary:
    return {
        "selected_character":String(selected_character_id), "current_stage_id":String(current_stage_id),
        "stage_index":stage_index, "cycle":cycle, "run_seed":run_seed, "journey_state":journey_state,
        "completion_marks":completion_marks.duplicate(true), "completion_marks_by_character":completion_marks_by_character.duplicate(true),
        "run_stats":run_stats.duplicate(true), "run_build":run_build.duplicate(true),
        "meta_progression":meta_progression.duplicate(true), "route_state":route_state.duplicate(true)
    }

func load_save_data(snapshot: Dictionary) -> void:
    selected_character_id = StringName(snapshot.get("selected_character","harun"))
    current_stage_id = StringName(snapshot.get("current_stage_id","o_olho"))
    stage_index = clampi(int(snapshot.get("stage_index",0)),0,15)
    cycle = maxi(0,int(snapshot.get("cycle",0)))
    run_seed = int(snapshot.get("run_seed",Time.get_unix_time_from_system()))
    journey_state = String(snapshot.get("journey_state",JOURNEY_PORTAL_0))
    completion_marks = snapshot.get("completion_marks",{}).duplicate(true)
    completion_marks_by_character = snapshot.get("completion_marks_by_character",{}).duplicate(true)
    run_stats = snapshot.get("run_stats",{}).duplicate(true)
    run_build = snapshot.get("run_build",{}).duplicate(true)
    meta_progression = snapshot.get("meta_progression",{}).duplicate(true)
    route_state = snapshot.get("route_state",{"route":"student","curses":[],"blessings":[],"post_boss_choice":"","gauntlet":""}).duplicate(true)
    _reconcile_loaded_journey()
    if run_stats.is_empty():
        _reset_run_stats()

func _reconcile_loaded_journey() -> void:
    var journey := ContentRegistry.get_base_student_journey()
    if journey.is_empty():
        journey_state = JOURNEY_PORTAL_0
        stage_index = 0
        current_stage_id = &"o_olho"
        return

    # Compatibilidade com a nomenclatura intermediária usada antes da decisão Portal 0.
    if journey_state == LEGACY_JOURNEY_INGRESSUS:
        journey_state = JOURNEY_PORTAL_0

    # Compatibilidade: saves da arquitetura anterior terminavam em PEREGRINUS_IGNIS_GAME.
    if journey_state == PEREGRINUS_IGNIS_GAME:
        meta_progression["student_initiation_completed"] = true
        meta_progression["degree_current"] = maxi(1, int(meta_progression.get("degree_current", 1)))
        journey_state = JOURNEY_DEGREE

    if journey_state == JOURNEY_DEGREE:
        var degree := clampi(int(meta_progression.get("degree_current", 1)), 1, 33)
        meta_progression["degree_current"] = degree
        var row := InitiaticProgressionService.degree_row(degree)
        current_stage_id = StringName(row.get("id", "grade_01_peregrinus_ignis"))
        stage_index = journey.size() - 1
        return

    stage_index = clampi(stage_index, 0, journey.size() - 1)
    var row: Dictionary = journey[stage_index]
    current_stage_id = StringName(String(row.get("id", "o_olho")))
    journey_state = JOURNEY_PORTAL_0 if stage_index <= 2 else JOURNEY_STUDENT

func snapshot_run() -> Dictionary:
    return to_save_data().duplicate(true)

func restore_run(snapshot: Dictionary) -> bool:
    if snapshot.is_empty():
        return false
    load_save_data(snapshot)
    return true

func save_run() -> bool:
    return SaveService.save_campaign(snapshot_run())

func load_run() -> bool:
    var snapshot := SaveService.load_campaign()
    return restore_run(snapshot)

func _reset_run_stats() -> void:
    run_stats = {"rooms_cleared":0,"secret_found":false,"super_secret_found":false,"rupture_charges":1,"deaths":0,"damage_taken":0.0,"identified_enemies":[],"items_used":[],"stage_started_at":int(Time.get_unix_time_from_system())}
