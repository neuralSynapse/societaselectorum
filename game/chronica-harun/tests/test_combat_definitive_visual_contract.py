from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def test_hud_exposes_reference_layout_surfaces():
    hud = read("scenes/ui/HUD.tscn")
    required_nodes = [
        'name="PlayerPanel"',
        'name="PlayerName"',
        'name="PlayerLevel"',
        'name="LifeValue"',
        'name="FocusValue"',
        'name="EnemyMarkers"',
        'name="RewardFeed"',
        'name="PowerSlots"',
        'name="PowerAcquiredPanel"',
        'name="PowerAcquiredName"',
    ]
    for node in required_nodes:
        assert node in hud, f"HUD definitive surface missing: {node}"

    # Narration belongs to the upper band, never the old bottom-of-screen placement.
    message_block = hud.split('[node name="Message"', 1)[1].split("[node ", 1)[0]
    assert "offset_top = 820.0" not in message_block
    assert "anchor_top" in message_block


def test_hud_controller_tracks_enemy_health_and_acquisition_feedback():
    controller = read("scripts/ui/HUDController.gd")
    for method in [
        "func track_enemy(",
        "func untrack_enemy(",
        "func show_power_acquired(",
        "func push_reward(",
        "func set_power_slots(",
    ]:
        assert method in controller, f"HUD runtime method missing: {method}"
    assert "unproject_position" in controller
    assert "get_health_ratio" in controller


def test_enemy_and_boss_publish_level_and_health_ratio():
    enemy = read("scripts/ai/EnemyBrain.gd")
    boss = read("scripts/bosses/DataBossController.gd")
    assert "combat_level" in enemy
    assert "func get_health_ratio(" in enemy
    assert "combat_level" in boss
    assert "func get_health_ratio(" in boss


def test_harun_has_real_dodge_with_invulnerability_and_mutation_hook():
    player = read("scripts/player/PlayerController.gd")
    project = read("project.godot")
    assert '"dodge"' in project
    assert "dodge_invulnerability" in player
    assert "func _start_dodge(" in player
    assert "PowerMutationRuntime.on_dodge" in player
    assert "dodge_started" in player


def test_stage_director_wires_enemy_markers_and_power_acquisition():
    stage = read("scripts/progression/StageDirector.gd")
    assert "hud.track_enemy(enemy" in stage
    assert "hud.untrack_enemy(enemy" in stage
    assert "hud.track_enemy(boss" in stage
    assert "hud.show_power_acquired" in stage
    assert "hud.set_power_slots" in stage


def test_definitive_hud_uses_ritual_red_violet_gold_language():
    hud = read("scenes/ui/HUD.tscn")
    # Styles are data, not screenshots. These named resources make the palette intentional and testable.
    for token in ["PlayerLifeFill", "PlayerFocusFill", "BossLifeFill", "GoldFrame"]:
        assert token in hud, f"missing ritual UI style: {token}"
