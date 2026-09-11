from pathlib import Path

GAME = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (GAME / rel).read_text(encoding="utf-8")


def test_primary_vfx_spawns_from_left_muzzle_and_follows_camera_forward_only():
    scene = read("scenes/player/Player.tscn")
    vfx = read("autoload/VFXDirector.gd")
    assert "PrimaryMuzzle" in scene
    primary = vfx[vfx.index("func _on_primary_requested"):vfx.index("func _on_power_requested")]
    assert "_player_primary_origin" in primary
    assert "_player_aim_direction" in primary
    assert "-player.global_transform.basis.z" not in primary
    aim = vfx[vfx.index("func _player_aim_direction"):]
    assert "-camera.global_transform.basis.z" in aim
    origin = vfx[vfx.index("func _player_primary_origin"):]
    assert "PrimaryMuzzle" in origin
    assert "camera_to_origin.dot(forward)" in origin


def test_primary_visual_does_not_expand_toward_camera():
    vfx = read("autoload/VFXDirector.gd")
    line = next(line for line in vfx.splitlines() if '"player_primary"' in line and 'travel' in line)
    assert '"start_scale":0.52' in line
    assert '"end_scale":0.52' in line
    assert '"travel":5.6' in line
    assert '"duration":0.16' in line
    assert 'spec.get("start_scale", 0.45)' in vfx


def test_right_mouse_power_is_visually_distinct_and_uses_right_hand_origin():
    vfx = read("autoload/VFXDirector.gd")
    presentation = read("scripts/player/FirstPersonPresentation.gd")
    power = vfx[vfx.index("func _on_power_requested"):vfx.index("func _on_kinesis_requested")]
    assert "_player_power_origin" in power
    assert "_player_aim_direction" in power
    assert "RightVoidOrb" in vfx[vfx.index("func _player_power_origin"):]
    assert "player.power_requested.connect(_on_power_requested)" in presentation
    assert "func _on_power_requested()" in presentation


def test_portal_zero_start_room_teaches_core_controls_on_the_floor():
    runtime = read("autoload/VFXDirector.gd")
    assert "_install_start_floor_tutorial" in runtime
    for token in [
        "TutorialFloorGuide",
        "WASD · MOVER",
        "LMB · ATAQUE PRIMÁRIO",
        "RMB · PODER INICIÁTICO",
        "Q · ESQUIVA",
        "V · CÂMERA",
        "ESC · PAUSA",
        "SEM CUSTO DE FOCO",
        "CONSOME FOCO",
    ]:
        assert token in runtime
