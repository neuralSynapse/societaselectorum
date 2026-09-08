import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def text(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def test_front_b_runtime_paths_and_test_arena_exist():
    required = [
        "scripts/combat/ReadableTelegraph.gd",
        "scripts/combat/CombatFeedback.gd",
        "scripts/rooms/SpecialRoomDirector.gd",
        "scripts/vision/VisionDirector.gd",
        "scripts/meta/MetaRunDirector.gd",
        "scenes/test/CombatEntityArena.tscn",
        "scripts/test/CombatEntityArena.gd",
    ]
    for rel in required:
        assert (ROOT / rel).exists(), rel


def test_enemy_and_boss_scenes_expose_world_space_attack_origins():
    enemy_scene = text("scenes/enemies/EnemyBase.tscn")
    boss_scene = text("scenes/bosses/BossBase.tscn")
    for scene in (enemy_scene, boss_scene):
        assert "TelegraphRoot" in scene
        assert "ProjectileOrigin" in scene
        assert "ImpactOrigin" in scene
    assert "TelegraphOrigin" in enemy_scene


def test_telegraph_runtime_supports_readable_attack_shapes():
    script = text("scripts/combat/ReadableTelegraph.gd")
    for token in [
        "class_name ReadableTelegraph",
        "MeshInstance3D",
        '"line"',
        '"fan"',
        '"radial"',
        '"zone"',
        '"dash"',
        "telegraph_time",
    ]:
        assert token in script


def test_enemy_and_boss_wire_telegraph_and_impact_feedback():
    enemy = text("scripts/ai/EnemyBrain.gd") + text("scripts/ai/DataEnemy.gd")
    boss = text("scripts/bosses/DataBossController.gd")
    for source in (enemy, boss):
        assert "ReadableTelegraph" in source
        assert "CombatFeedback" in source
        assert "telegraph_started" in source
        assert "projectile_origin.global_position" in source
    assert "impact_window_started" in boss


def test_enemy_catalog_is_individualized_and_attack_readable():
    enemies = json.loads(text("data/enemies/student_enemies.json"))
    assert len(enemies) >= 82
    ids = [row["id"] for row in enemies]
    assert len(ids) == len(set(ids))
    model_paths = [row["model_path"] for row in enemies]
    assert len(model_paths) == len(set(model_paths))
    for row in enemies:
        attack = row["attack"]
        assert attack["id"]
        assert attack["attack_kind"] in {"movement", "projectile"}
        assert attack["pattern"] in {"dash", "line", "fan", "radial", "zone", "summon"}
        assert float(attack["windup"]) > 0
        assert float(attack["telegraph_time"]) > 0
        assert float(attack["damage"]) > 0


def test_boss_catalog_has_three_real_phases_and_unique_models():
    bosses = json.loads(text("data/bosses/student_bosses.json"))
    assert len(bosses) == 16
    assert len({row["id"] for row in bosses}) == 16
    assert len({row["model_path"] for row in bosses}) == 16
    for row in bosses:
        phases = row["phases"]
        assert len(phases) == 3, row["id"]
        assert all(phase.get("attacks") for phase in phases)
        attack_ids = [a["id"] for phase in phases for a in phase["attacks"]]
        assert len(set(attack_ids)) >= 3, row["id"]
