from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def test_web_mouse_capture_requires_real_user_gesture():
    player = read("scripts/player/PlayerController.gd")
    assert 'OS.has_feature("web")' in player
    assert "func _request_mouse_capture_from_user_gesture(" in player
    assert "InputEventMouseButton" in player
    assert "MOUSE_MODE_CAPTURED" in player
    assert "mouse_capture_changed" in player


def test_connected_rooms_keep_side_collision_around_doorway():
    floor = read("scripts/generation/StageFloorBuilder.gd")
    assert "DOORWAY_WIDTH" in floor
    assert "func _open_doorway(" in floor
    assert "func _add_doorway_side(" in floor
    assert "_open_doorway(a, wall_a)" in floor
    assert "_open_doorway(b, wall_b)" in floor


def test_boot_restores_canonical_societas_campaign_gate():
    main = read("scripts/boot/Main.gd")
    save = read("autoload/SaveService.gd")
    assert "SOCIETAS ELECTORUM" in main
    assert "NOVA CAMPANHA" in main
    assert "CONTINUAR" in main
    assert "Frater Horus Phosphorus" in main
    assert "func _show_canonical_boot_gate(" in main
    assert "func _start_new_campaign_from_gate(" in main
    assert "func _continue_campaign_from_gate(" in main
    assert "func delete_campaign(" in save


def test_web_export_generates_production_models_before_export():
    workflow = read("../../.github/workflows/chronica-combat-definitive-v1.yml")
    generate_index = workflow.index('python "$GAME_DIR/tools/generate_models.py"')
    export_index = workflow.index('godot --headless --path "$GAME_DIR" --export-release "Web"')
    assert generate_index < export_index
