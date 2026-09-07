extends Node
class_name NarrativeRuntimeBridge

signal narration_lines(lines: Array, duration_seconds: float)
signal scene_title_requested(text: String)
signal cinematic_visual(payload: Dictionary)
signal cinematic_audio(payload: Dictionary)
signal story_message(text: String, duration: float)
signal transition_requested(target: StringName)
signal story_state_saved(state: Dictionary)
signal narrative_consequence_requested(external_hook: StringName, payload: Dictionary)

@onready var cosmogony: CosmogonyPrologueDirector = $CosmogonyPrologue
@onready var harun_origin: HarunOriginDirector = $HarunOrigin
@onready var chronica_story: ChronicaStoryDirector = $ChronicaStory
@onready var story_codex: StoryCodexService = $StoryCodex
@onready var cinematic_shots: CinematicShotDirector = $CinematicShots
@onready var narrative_choices: NarrativeChoiceDirector = $NarrativeChoices

var active_sequence: StringName = &""
var stage_director: StageDirector
var bound_room_director: RoomDirector
var first_combat_entered := false
var first_combat_cleared := false
var inversion_triggered := false

func _ready() -> void:
    var state := current_story_state()
    cosmogony.configure(state)
    harun_origin.configure(state)
    chronica_story.configure(state)
    narrative_choices.configure(state)
    _connect_story_signals()
    call_deferred("_auto_bind")

func start_entry_flow() -> StringName:
    var state := current_story_state()
    cosmogony.configure(state)
    harun_origin.configure(state)
    chronica_story.configure(state)
    narrative_choices.configure(state)
    if not bool(state.get("prologue_completed", false)):
        active_sequence = &"cosmogony"
        cosmogony.start()
        return active_sequence
    if not bool(state.get("grimorium_title_revealed", false)):
        active_sequence = &"harun_origin"
        harun_origin.begin_origin_sequence()
        return active_sequence
    if GameState.journey_state == GameState.PEREGRINUS_IGNIS_GAME:
        active_sequence = &"epilogue"
        start_epilogue()
        return active_sequence
    active_sequence = &"student_journey"
    chronica_story.begin_stage(GameState.current_stage_id)
    return active_sequence

func advance_active_sequence() -> bool:
    match active_sequence:
        &"cosmogony":
            return cosmogony.advance()
        &"harun_origin":
            return harun_origin.advance()
        &"epilogue":
            chronica_story.finish_epilogue()
            active_sequence = &""
            return true
    return false

func skip_active_sequence() -> bool:
    if active_sequence == &"cosmogony":
        return cosmogony.skip()
    return false

func bind_stage_director(next_stage_director: StageDirector) -> void:
    stage_director = next_stage_director
    if stage_director == null:
        return
    if not stage_director.stage_completed.is_connected(_on_stage_completed):
        stage_director.stage_completed.connect(_on_stage_completed)
    call_deferred("_bind_room_director")
    chronica_story.begin_stage(GameState.current_stage_id)

func current_story_state() -> Dictionary:
    var state = GameState.meta_progression.get("story", {})
    return state.duplicate(true) if state is Dictionary else {}

func register_grimorium_fragment(fragment_id: StringName) -> bool:
    return harun_origin.register_fragment(fragment_id)

func start_epilogue() -> bool:
    return chronica_story.begin_epilogue()

func _auto_bind() -> void:
    if stage_director != null:
        return
    var candidate := get_parent().get_node_or_null("StageDirector") as StageDirector
    if candidate != null:
        bind_stage_director(candidate)

func _bind_room_director() -> void:
    if stage_director == null or stage_director.room_director == null:
        return
    bound_room_director = stage_director.room_director
    if not bound_room_director.room_entered.is_connected(_on_room_entered):
        bound_room_director.room_entered.connect(_on_room_entered)
    if not bound_room_director.room_cleared.is_connected(_on_room_cleared):
        bound_room_director.room_cleared.connect(_on_room_cleared)

func _connect_story_signals() -> void:
    cosmogony.scene_started.connect(_on_cosmogony_scene_started)
    cosmogony.narration_requested.connect(func(lines, duration): narration_lines.emit(lines, duration))
    cosmogony.visual_requested.connect(func(payload): cinematic_visual.emit(payload))
    cosmogony.audio_requested.connect(func(payload): cinematic_audio.emit(payload))
    cosmogony.completion_persist_requested.connect(_on_key_persist_requested)
    cosmogony.prologue_finished.connect(_on_cosmogony_finished)
    harun_origin.origin_scene_started.connect(_on_origin_scene_started)
    harun_origin.story_state_persist_requested.connect(_persist_story_state)
    harun_origin.title_revealed.connect(func(title): story_message.emit(title, 3.0))
    harun_origin.command_revealed.connect(func(command, _index): story_message.emit(String(command), 1.4))
    harun_origin.origin_finished.connect(_on_origin_finished)
    chronica_story.beat_started.connect(_on_story_beat_started)
    chronica_story.story_state_persist_requested.connect(_persist_story_state)
    chronica_story.epilogue_started.connect(_on_epilogue_started)
    chronica_story.epilogue_finished.connect(func(target): transition_requested.emit(target))
    cinematic_shots.shot_started.connect(_on_cinematic_shot_started)
    narrative_choices.story_state_persist_requested.connect(_persist_story_state)
    narrative_choices.consequence_requested.connect(_on_choice_consequence_requested)

func _on_cosmogony_finished(_next_sequence: StringName) -> void:
    active_sequence = &"harun_origin"
    harun_origin.configure(current_story_state())
    harun_origin.begin_origin_sequence()

func _on_origin_scene_started(scene_id: StringName, scene: Dictionary) -> void:
    story_codex.unlock_by_key("scene:" + String(scene_id))
    scene_title_requested.emit(String(scene.get("title", "")))
    cinematic_shots.begin_sequence(scene, bool(current_story_state().get("skip_unlocked", false)))
    narration_lines.emit(scene.get("voiceover", []), float(scene.get("duration_seconds", 40.0)))
    cinematic_visual.emit(scene.get("visual", {}))
    cinematic_audio.emit(scene.get("audio", {}))

func _on_origin_finished(target_stage: StringName) -> void:
    active_sequence = &"student_journey"
    chronica_story.configure(current_story_state())
    chronica_story.begin_stage(target_stage)
    transition_requested.emit(target_stage)

func _on_room_entered(room_id: StringName) -> void:
    var stage_id := StringName(stage_director.stage_data.get("id", GameState.current_stage_id)) if stage_director != null else GameState.current_stage_id
    var id := String(room_id)
    if id == "threshold":
        story_codex.unlock_by_key("stage:" + String(stage_id))
        chronica_story.begin_stage(stage_id)
        chronica_story.trigger(stage_id, &"threshold")
    elif id == "combat_1" and not first_combat_entered:
        first_combat_entered = true
        chronica_story.trigger(stage_id, &"wound")
    elif id in ["trial", "speculum", "cursed", "archon", "historical_echo"] and not inversion_triggered:
        inversion_triggered = true
        chronica_story.trigger(stage_id, &"inversion")
    elif id == "boss":
        chronica_story.trigger(stage_id, &"boss_intro")

func _on_room_cleared(room_id: StringName) -> void:
    if stage_director == null:
        return
    var stage_id := StringName(stage_director.stage_data.get("id", GameState.current_stage_id))
    var id := String(room_id)
    if id == "combat_1" and not first_combat_cleared:
        first_combat_cleared = true
        chronica_story.trigger(stage_id, &"revelation")
        narrative_choices.present_stage_choice(stage_id)
    elif id in ["combat_2", "trial"] and not inversion_triggered:
        inversion_triggered = true
        chronica_story.trigger(stage_id, &"inversion")

func _on_stage_completed(stage_id: StringName, _summary: Dictionary) -> void:
    chronica_story.trigger(stage_id, &"boss_truth")
    chronica_story.trigger(stage_id, &"completion")
    chronica_story.complete_stage(stage_id)
    first_combat_entered = false
    first_combat_cleared = false
    inversion_triggered = false
    if GameState.journey_state == GameState.PEREGRINUS_IGNIS_GAME:
        start_epilogue()

func _on_story_beat_started(_stage_id: StringName, _beat_id: StringName, beat: Dictionary) -> void:
    story_message.emit(String(beat.get("text", "")), 4.0)

func _on_epilogue_started(epilogue: Dictionary) -> void:
    active_sequence = &"epilogue"
    story_codex.unlock_by_key("epilogue:" + String(epilogue.get("id", "aleppo_1585")))
    scene_title_requested.emit("%s · %s" % [String(epilogue.get("location", "Aleppo")), String(epilogue.get("date_display", "c. 1585"))])
    cinematic_shots.begin_sequence(epilogue, bool(current_story_state().get("skip_unlocked", false)))
    narration_lines.emit(epilogue.get("voiceover", []), float(epilogue.get("duration_seconds", 62.0)))
    cinematic_visual.emit(epilogue.get("visual", {}))
    cinematic_audio.emit(epilogue.get("audio", {}))

func _on_key_persist_requested(key: StringName, value) -> void:
    var state := current_story_state()
    state[String(key)] = value
    _persist_story_state(state)

func _persist_story_state(state: Dictionary) -> void:
    GameState.meta_progression["story"] = state.duplicate(true)
    SaveService.save_campaign(GameState.to_save_data())
    story_state_saved.emit(state.duplicate(true))

func _on_cosmogony_scene_started(scene_id: StringName, scene: Dictionary) -> void:
    story_codex.unlock_by_key("scene:" + String(scene_id))
    scene_title_requested.emit(String(scene.get("title", "")))
    cinematic_shots.begin_sequence(scene, bool(current_story_state().get("skip_unlocked", false)))

func _on_cinematic_shot_started(_sequence_id: StringName, _shot_id: StringName, shot: Dictionary) -> void:
    cinematic_visual.emit({"shot": shot.get("visual_event", ""), "camera": shot.get("camera", ""), "transition": shot.get("transition", "cut"), "tension": shot.get("tension", 0.0)})
    cinematic_audio.emit({"event": shot.get("audio_event", ""), "tension": shot.get("tension", 0.0)})

func _on_choice_consequence_requested(external_hook: StringName, payload: Dictionary) -> void:
    # Combat/meta-run owns mechanics. Narrative emits a stable semantic hook only.
    story_message.emit("CONSEQUÊNCIA · %s" % String(payload.get("story_consequence", "Escolha registrada.")), 3.8)
    narrative_consequence_requested.emit(external_hook, payload.duplicate(true))
