from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_ENEMY = ROOT / "scripts/ai/DataEnemy.gd"


def test_repeated_enemy_families_have_distinct_runtime_movement_paths():
    text = DATA_ENEMY.read_text(encoding="utf-8")
    required_helpers = [
        "func _ram_charge_stalk(",
        "func _zigzag_hunt(",
        "func _strafe_ranged(",
        "func _orbit_ranged(",
        "func _burst_pursuit(",
        "func _anchor_advance(",
        "func _skitter_flank(",
    ]
    for helper in required_helpers:
        assert helper in text, f"missing family behavior: {helper}"

    required_routes = {
        '"ram_archon":': "_ram_charge_stalk",
        '"hyena_archon":': "_zigzag_hunt",
        '"asinine_archon":': "_strafe_ranged",
        '"chorus":': "_orbit_ranged",
        '"fire":': "_burst_pursuit",
        '"construct":': "_anchor_advance",
        '"walker":': "_skitter_flank",
    }
    for family, helper in required_routes.items():
        assert family in text and helper in text.split(family, 1)[1][:180], f"{family} must route to {helper}"


def test_family_motion_helpers_keep_world_space_movement():
    text = DATA_ENEMY.read_text(encoding="utf-8")
    assert "move_and_slide()" in text
    assert "target.global_position" in text
    assert "camera" not in "\n".join(line for line in text.splitlines() if "func _" in line and "camera" in line.lower())
