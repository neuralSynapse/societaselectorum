from pathlib import Path

GAME = Path(__file__).resolve().parents[1]
ROOT = GAME.parents[1]


def read(rel: str) -> str:
    return (GAME / rel).read_text(encoding="utf-8")


def test_enemies_collide_with_player_world_and_each_other():
    scene = read("scenes/enemies/EnemyBase.tscn")
    assert 'collision_layer = 2' in scene
    # Layer 1 is the player. Layer 2 is the room/world and current enemy bodies.
    # Mask 3 makes enemy movement respect both instead of walking through walls.
    assert 'collision_mask = 3' in scene
    assert 'safe_margin = 0.06' in scene
    assert 'radius = 0.52' in scene


def test_player_keeps_world_and_enemy_collision_enabled():
    scene = read("scenes/player/Player.tscn")
    assert 'collision_layer = 1' in scene
    assert 'collision_mask = 2' in scene


def test_enemy_models_are_never_loaded_synchronously_during_spawn():
    factory = read("scripts/content/EnemyFactory.gd")
    assert 'load(model_path)' not in factory
    assert 'ResourceLoader.load_threaded_request' in factory
    assert 'ResourceLoader.load_threaded_get_status' in factory
    assert 'THREAD_LOAD_LOADED' in factory
    assert 'EnemyModelStream.gd' in factory


def test_enemy_model_attachment_is_staggered_after_threaded_load():
    streamer = read("scripts/content/EnemyModelStream.gd")
    assert 'STAGGER_BUCKETS := 6' in streamer
    assert 'ResourceLoader.load_threaded_get_status' in streamer
    assert 'ResourceLoader.THREAD_LOAD_LOADED' in streamer
    assert 'frame_index % STAGGER_BUCKETS' in streamer
    assert 'visual.add_child(instance)' in streamer


def test_bosses_respect_room_collision_and_player_body():
    scene = read("scenes/bosses/BossBase.tscn")
    assert 'collision_layer = 2' in scene
    assert 'collision_mask = 3' in scene
    assert 'safe_margin = 0.08' in scene


def test_boss_model_loading_is_threaded_instead_of_spawn_blocking():
    boss = read("scripts/bosses/DataBossController.gd")
    assert 'load(path)' not in boss
    assert 'ResourceLoader.load_threaded_request' in boss
    assert 'ResourceLoader.load_threaded_get_status' in boss
    assert 'EnemyModelStream.gd' in boss


def test_ci_runs_real_characterbody_collision_probe():
    probe_scene = GAME / "runtime_qa/CollisionRuntimeProbe.tscn"
    probe_script = GAME / "runtime_qa/CollisionRuntimeProbe.gd"
    assert probe_scene.exists()
    assert probe_script.exists()
    script = probe_script.read_text(encoding="utf-8")
    assert "ENEMY_WALL_COLLISION=PASS" in script
    assert "PLAYER_ENEMY_COLLISION=PASS" in script
    workflow = (ROOT / ".github/workflows/chronica-combat-definitive-v1.yml").read_text(encoding="utf-8")
    assert "Real gameplay collision probe" in workflow
    assert "COLLISION_RUNTIME=PASS" in workflow
