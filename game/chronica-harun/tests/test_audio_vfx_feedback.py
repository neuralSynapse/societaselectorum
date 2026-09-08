from pathlib import Path
import re

GAME = Path(__file__).resolve().parents[1]

REQUIRED_SFX = {
    "player_primary", "player_power", "kinesis", "instrumenta", "tarot_activate",
    "player_hit", "enemy_windup", "enemy_shot", "projectile_impact", "enemy_hit",
    "enemy_death", "boss_windup", "boss_attack", "boss_phase", "boss_death",
    "pickup", "secret_break", "special_room_activate",
}


def read(rel: str) -> str:
    return (GAME / rel).read_text(encoding="utf-8")


def test_audio_ids_resolve_or_have_procedural_fallback():
    src = read("autoload/AudioDirector.gd")
    for event_id in REQUIRED_SFX:
        assert f'"{event_id}"' in src, event_id
    assert "AudioStreamWAV" in src
    assert "placeholder" in src
    assert "func has_event" in src
    assert "func event_status" in src
    assert 'Audio event not installed' not in src


def test_vfx_director_is_safe_autoload_with_emission_caps():
    project = read("project.godot")
    assert 'VFXDirector="*res://autoload/VFXDirector.gd"' in project
    src = read("autoload/VFXDirector.gd")
    for event_id in [
        "player_primary", "player_power", "kinesis", "instrumenta", "tarot_activate",
        "enemy_windup", "enemy_telegraph", "enemy_projectile", "projectile_travel", "projectile_impact",
        "enemy_hit", "enemy_death", "boss_windup", "boss_attack", "boss_phase",
        "boss_death", "pickup", "secret_rupture", "special_room_activate",
    ]:
        assert f'"{event_id}"' in src, event_id
    assert "MAX_EMISSION" in src
    assert "TELEGRAPH_MAX_EMISSION" in src
    assert "minf" in src or "clampf" in src


def test_projectile_is_visible_has_rendered_trail_and_physically_travels():
    scene = read("scenes/vfx/Projectile.tscn")
    script = read("scripts/combat/Projectile.gd")
    assert "draw_pass_1" in scene
    radius_match = re.search(r"radius = ([0-9.]+)", scene)
    assert radius_match and float(radius_match.group(1)) >= 0.1
    assert "global_position += direction * speed * delta" in script
    assert "projectile_impact" in script
    assert script.index("global_position += direction * speed * delta") < script.index("body.apply_damage")


def test_attack_contract_preserves_telegraph_before_emission_and_ranged_damage_on_collision():
    state = read("scripts/combat/AttackStateMachine.gd")
    projectile = read("scripts/combat/Projectile.gd")
    enemy = read("scripts/ai/DataEnemy.gd")
    boss = read("scripts/bosses/DataBossController.gd")
    assert state.index("telegraph_started.emit") < state.index("emission_requested.emit")
    assert "PROJECTILE_SCENE.instantiate" in enemy
    assert "PROJECTILE_SCENE.instantiate" in boss
    assert "func _on_body_entered" in projectile
    damage_line = projectile.index("body.apply_damage")
    travel_line = projectile.index("global_position += direction * speed * delta")
    assert travel_line < damage_line


def test_enemy_and_boss_feedback_hooks_cover_required_combat_states():
    enemy = read("scripts/ai/EnemyBrain.gd")
    boss = read("scripts/bosses/DataBossController.gd")
    for token in ["enemy_windup", "enemy_telegraph", "enemy_hit", "enemy_death"]:
        assert token in enemy
    for token in ["boss_windup", "boss_attack", "boss_phase", "boss_death"]:
        assert token in boss
    assert "VFXDirector" in enemy
    assert "VFXDirector" in boss


def test_player_content_pickup_secret_and_special_room_feedback_hooks_exist():
    vfx = read("autoload/VFXDirector.gd")
    pickup = read("scripts/pickups/PickupController.gd")
    player = read("scripts/player/PlayerController.gd")
    stage = read("scripts/progression/StageDirector.gd")
    for token in [
        "player_primary", "player_power", "kinesis", "instrumenta", "tarot_activate",
        "secret_rupture", "special_room_activate",
    ]:
        assert token in vfx
    assert 'AudioDirector.play_3d(&"secret_break"' in stage
    assert "pickup" in pickup and "VFXDirector" in pickup
    assert 'AudioDirector.play_3d(&"player_hit"' in player
    assert '"player_hit"' in vfx


def test_boss_phase_feedback_is_emitted_from_actual_phase_transition():
    boss = read("scripts/bosses/DataBossController.gd")
    transition = boss[boss.index("if next_phase != current_phase:"):]
    assert 'AudioDirector.play_3d(&"boss_phase"' in transition
    assert 'VFXDirector.emit_feedback(&"boss_phase"' in transition


def test_runtime_probe_covers_audio_projectile_and_boss_phase():
    probe = read("runtime_qa/AudioVfxProbe.gd")
    assert "AUDIO_VFX_RUNTIME_PROBE=PASS" in probe
    assert "projectile did not physically travel" in probe
    assert "boss phase feedback did not fire" in probe
