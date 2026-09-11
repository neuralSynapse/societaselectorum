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


def test_definitive_world_uses_cinematic_environment_not_empty_worldenvironment():
    main_scene = read("scenes/boot/Main.tscn")
    assert '[sub_resource type="Environment"' in main_scene
    assert "environment = SubResource(" in main_scene
    assert "background_color" in main_scene
    assert "ambient_light_color" in main_scene
    assert "fog_enabled = true" in main_scene
    assert "tonemap_mode" in main_scene
    assert 'name="MoonRim"' in main_scene


def test_rooms_have_ruin_depth_not_only_clean_procedural_arches():
    room = read("scripts/generation/RoomShell.gd")
    for marker in [
        "RuinDebris",
        "WallReliefs",
        "RitualCandles",
        "BlindStatues",
        "func _add_ruin_debris(",
        "func _add_wall_reliefs(",
        "func _add_ritual_candles(",
        "func _add_blind_statues(",
    ]:
        assert marker in room


def test_first_person_power_palette_is_gold_and_deep_violet_not_neon_red_magenta():
    player_scene = read("scenes/player/Player.tscn")
    assert "emission_energy_multiplier = 2.4" in player_scene
    assert "emission_energy_multiplier = 2.2" in player_scene
    assert "light_energy = 0.9" in player_scene
    assert "light_energy = 0.8" in player_scene


def test_proxy_cinematics_do_not_darkveil_the_live_gameplay_camera():
    presentation = read("scripts/narrative/NarrativePresentationController.gd")
    assert "func _has_player_facing_cinematic_visuals(" in presentation
    assert "if not _has_player_facing_cinematic_visuals():" in presentation
    assert "cinematic_veil.visible = false" in presentation
    assert "blackout.visible = false" in presentation


def test_entry_rooms_have_a_web_safe_visibility_fill():
    room_scene = read("scenes/rooms/RoomShell.tscn")
    assert 'name="VisibilityFillLight"' in room_scene
    assert "light_energy = 2.2" in room_scene
    assert "omni_range = 9.0" in room_scene


def test_player_primary_vfx_travels_forward_instead_of_expanding_toward_camera():
    vfx = read("autoload/VFXDirector.gd")
    motion = read("scripts/vfx/TransientVFXMotion.gd")
    assert '"player_primary"' in vfx
    assert '"travel":5.6' in vfx
    assert '"start_scale":0.52' in vfx
    assert '"end_scale":0.52' in vfx
    assert 'var travel := float(spec.get("travel", 0.0))' in vfx
    assert "TRANSIENT_VFX_MOTION" in vfx
    assert "root.configure(direction, travel, duration" in vfx
    assert "velocity = direction.normalized() * (travel / lifetime)" in motion
    assert "position += velocity * delta" in motion
