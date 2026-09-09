extends Node

const TEST_MARKER := "_qa_death_recovery_phase"
const TEST_SEED := 95201

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_gate")

func _fail(message: String) -> void:
    printerr("DEATH_RECOVERY_GATE_FAIL: %s" % message)
    GameState.meta_progression.erase(TEST_MARKER)
    get_tree().quit(1)

func _run_gate() -> void:
    # SceneTree.reload_current_scene() preserves autoloads. The marker lets the
    # second load prove that a real scene reload happened after player death.
    if int(GameState.meta_progression.get(TEST_MARKER, 0)) == 1:
        var deaths := int(GameState.run_stats.get("deaths", 0))
        var total_deaths := int(GameState.meta_progression.get("total_deaths", 0))
        GameState.meta_progression.erase(TEST_MARKER)
        if deaths < 1 or total_deaths < 1:
            _fail("scene reloaded but death counters were not persisted")
            return
        print("CHRONICA_DEATH_RECOVERY_GATE_OK")
        get_tree().quit(0)
        return

    GameState.start_new_campaign(TEST_SEED)
    GameState.meta_progression[TEST_MARKER] = 1
    SaveService.save_campaign(GameState.to_save_data())

    var main_scene: PackedScene = load("res://scenes/boot/Main.tscn")
    if main_scene == null:
        _fail("Main scene cannot be loaded")
        return
    var main := main_scene.instantiate()
    add_child(main)
    await get_tree().process_frame
    await get_tree().physics_frame

    var stage_director := main.get_node_or_null("StageDirector") as StageDirector
    if stage_director == null or stage_director.player == null:
        _fail("Main boot did not produce a playable StageDirector/player")
        return

    var player := stage_director.player
    if player.health == null:
        _fail("playable player has no health component")
        return

    player.health.invulnerable_for = 0.0
    player.apply_damage(99999.0, &"death_recovery_gate")
    if not player.health.dead:
        _fail("forced lethal damage did not kill the player")
        return

    # Production recovery is expected to reload this current test scene.
    # If no reload occurs, this instance survives and deliberately fails.
    var timeout := get_tree().create_timer(4.0, true, false, true)
    await timeout.timeout
    _fail("player death did not reload the current stage/scene within the recovery window")
