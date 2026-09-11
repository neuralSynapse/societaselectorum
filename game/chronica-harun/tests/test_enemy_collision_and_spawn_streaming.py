from pathlib import Path

GAME = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (GAME / rel).read_text(encoding="utf-8")


def test_enemies_collide_with_player_world_and_each_other():
    scene = read("scenes/enemies/EnemyBase.tscn")
    assert 'collision_layer = 2' in scene
    # Layer 1 is the player. Layer 2 is the room/world and current enemy bodies.
    # Mask 3 makes enemy movement respect both instead of walking through walls.
    assert 'collision_mask = 3' in scene
    assert 'safe_margin = 0.06' in scene


def test_player_keeps_solid_world_and_enemy_collision_margin():
    scene = read("scenes/player/Player.tscn")
    assert 'collision_mask = 2' in scene
    assert 'safe_margin = 0.06' in scene


def test_enemy_models_are_never_loaded_synchronously_during_spawn():
    factory = read("scripts/content/EnemyFactory.gd")
    assert 'load(model_path)' not in factory
    assert 'ResourceLoader.load_threaded_request' in factory
    assert 'ResourceLoader.load_threaded_get_status' in factory
    assert 'THREAD_LOAD_LOADED' in factory


def test_combat_room_spawn_is_distributed_across_physics_frames():
    stage = read("scripts/progression/StageDirector.gd")
    spawn = stage[stage.index("func _spawn_combat_room"):stage.index("func _spawn_elite_room")]
    assert 'await get_tree().physics_frame' in spawn
    assert 'EnemyFactory.request_model' in stage
