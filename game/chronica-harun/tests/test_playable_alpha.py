from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


def test_project_has_playable_main_scene_and_fps_inputs():
    text = read('project.godot')
    assert 'run/main_scene="res://scenes/boot/Main.tscn"' in text
    for action in ['move_left','move_right','move_forward','move_back','sprint','primary_attack','power','interact','pause']:
        assert action + '=' in text


def test_playable_runtime_files_exist():
    for rel in [
        'scenes/boot/Main.tscn',
        'scripts/boot/PlayableMain.gd',
        'scripts/player/PlayablePlayer.gd',
        'scripts/combat/PlayableProjectile.gd',
        'scripts/ai/PlayableEnemy.gd',
        'scripts/bosses/PlayableBlindObserver.gd',
        'scripts/progression/PlayableStage.gd',
        'scripts/ui/PlayableHUD.gd',
    ]:
        assert (ROOT / rel).exists(), rel


def test_player_is_real_first_person_world_space():
    text = read('scripts/player/PlayablePlayer.gd')
    assert 'extends CharacterBody3D' in text
    assert 'Camera3D' in text
    assert 'invert_y := false' in text
    assert 'Input.MOUSE_MODE_CAPTURED' in text
    assert 'rotation.y' in text
    assert 'camera_pivot.rotation.x' in text


def test_enemy_attacks_have_telegraph_and_visible_projectiles():
    enemy = read('scripts/ai/PlayableEnemy.gd')
    projectile = read('scripts/combat/PlayableProjectile.gd')
    assert 'telegraph' in enemy.lower()
    assert 'windup' in enemy.lower()
    assert 'Projectile' in enemy or 'projectile' in enemy
    assert 'MeshInstance3D' in projectile
    assert 'CollisionShape3D' in projectile


def test_stage_has_low_density_rooms_and_three_phase_boss():
    stage = read('scripts/progression/PlayableStage.gd')
    boss = read('scripts/bosses/PlayableBlindObserver.gd')
    assert '[1, 2, 3]' in stage
    assert 'phase_changed' in boss
    assert '0.66' in boss
    assert '0.32' in boss
    assert 'radial' in boss.lower()
    assert 'dash' in boss.lower()
