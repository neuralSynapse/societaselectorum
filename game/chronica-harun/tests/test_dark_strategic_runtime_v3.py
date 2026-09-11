from pathlib import Path

GAME = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (GAME / rel).read_text(encoding="utf-8")


def test_pause_surface_only_tracks_explicit_manual_pause_not_any_tree_pause():
    runtime = read("autoload/InitiaticRuntimeIntegrator.gd")
    assert "_manual_pause_active" in runtime
    process = runtime[runtime.index("func _process"):runtime.index("func _scan_existing_nodes")]
    assert "get_tree().paused" not in process
    assert "_manual_pause_active()" in process
    assert 'main.get("pause_active")' in runtime or "main.pause_active" in runtime


def test_pickups_explain_what_they_do_and_how_to_use_them():
    hud = read("scripts/ui/HUDController.gd")
    stage = read("scripts/progression/StageDirector.gd")
    assert "func show_acquisition" in hud
    assert "func _describe_acquisition" in hud
    assert "PARA QUE SERVE" in hud
    assert "COMO USAR" in hud
    assert "show_acquisition" in stage[stage.index("func _spawn_pickup"):stage.index("func _on_enemy_identified")]
    for category in ["tarot", "pharmaka", "instrumenta", "relics", "talismans", "sigilla", "daimones", "blessings", "curses", "transformations"]:
        assert f'"{category}"' in hud


def test_enemies_are_scaled_up_and_have_tactical_seals_instead_of_flat_hp_only():
    enemy = read("scripts/ai/DataEnemy.gd")
    assert "difficulty_scalar" in enemy
    assert "tactical_seal" in enemy
    assert "vulnerability_window" in enemy
    assert "_resolve_tactical_seal" in enemy
    assert "_incoming_damage_multiplier" in enemy
    assert "stage_pressure" in enemy
    assert "room_pressure" in enemy
    # Difficulty must affect more than health.
    assert "move_speed *= " in enemy
    assert "attack_cooldown" in enemy
    assert "damage_scale" in enemy


def test_room_runtime_contains_deterministic_enigmas_with_risk_and_reward():
    enigma = read("scripts/progression/EnigmaDirector.gd")
    stage = read("scripts/progression/StageDirector.gd")
    assert "class_name EnigmaDirector" in enigma
    assert "func build_enigma" in enigma
    assert "correct_index" in enigma
    assert "penalty" in enigma
    assert "reward" in enigma
    assert "stage_id" in enigma
    assert "_offer_room_enigma" in stage
    assert 'room_id in [&"trial", &"secret", &"super_secret"]' in stage
    assert "resolve_enigma" in stage


def test_reactive_narrative_is_driven_by_actual_game_events_and_throttled():
    reactive = read("scripts/narrative/ReactiveNarrativeDirector.gd")
    stage = read("scripts/progression/StageDirector.gd")
    assert "class_name ReactiveNarrativeDirector" in reactive
    assert "func narrate_event" in reactive
    assert "event_cooldowns" in reactive
    for event in ["room_entered", "enemy_identified", "enemy_killed", "room_cleared", "secret_opened", "acquisition", "boss_phase"]:
        assert f'"{event}"' in reactive
    assert "reactive_narrative" in stage
    for hook in ["_on_room_entered", "_on_enemy_identified", "_on_enemy_killed", "_on_room_cleared", "_on_secret_opened", "_on_boss_phase"]:
        block = stage[stage.index(f"func {hook}"):]
        assert "narrate_event" in block[:2200]
