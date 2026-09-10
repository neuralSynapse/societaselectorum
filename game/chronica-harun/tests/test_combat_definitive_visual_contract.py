from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def test_hud_exposes_reference_layout_surfaces():
    hud = read("scenes/ui/HUD.tscn")
    required_nodes = [
        'name="PlayerPanel"', 'name="PlayerName"', 'name="PlayerLevel"',
        'name="LifeValue"', 'name="FocusValue"', 'name="EnemyMarkers"',
        'name="RewardFeed"', 'name="PowerSlots"', 'name="PowerAcquiredPanel"',
        'name="PowerAcquiredName"',
    ]
    for node in required_nodes:
        assert node in hud, f"HUD definitive surface missing: {node}"
    message_block = hud.split('[node name="Message"', 1)[1].split("[node ", 1)[0]
    assert "offset_top = 820.0" not in message_block
    assert "anchor_top" in message_block


def test_hud_controller_tracks_enemy_health_and_acquisition_feedback():
    controller = read("scripts/ui/HUDController.gd")
    for method in [
        "func track_enemy(", "func untrack_enemy(", "func show_power_acquired(",
        "func push_reward(", "func set_power_slots(", "func _scan_combatants(",
        "func _on_build_changed_definitive(",
    ]:
        assert method in controller, f"HUD runtime method missing: {method}"
    assert "unproject_position" in controller
    assert "get_health_ratio" in controller
    assert "node_added.connect" in controller
    assert "build_changed.connect" in controller


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
    assert 'dodge={' in project
    assert "dodge_invulnerability" in player
    assert "func _start_dodge(" in player
    assert "PowerMutationRuntime.on_dodge" in player
    assert "dodge_started" in player


def test_powers_can_be_acquired_into_the_run_build():
    service = read("autoload/RogueliteContentService.gd")
    assert '"powers":[]' in service
    assert '"powers": return add_power(id)' in service
    assert "func add_power(" in service


def test_active_power_does_not_overwrite_canonical_stage_data():
    router = read("autoload/CombatLoadoutDirector.gd")
    runtime = read("autoload/DefinitivePowerRuntime.gd")
    assert 'build.get("active_power"' in router
    assert 'build.get("active_power"' in runtime
    assert 'stage_data["power_id"]' not in router


def test_stage_power_is_acquired_and_second_combat_offers_one_of_three_mutations():
    project = read("project.godot")
    rewards = read("autoload/DefinitiveRewardRuntime.gd")
    assert 'DefinitiveRewardRuntime="*res://autoload/DefinitiveRewardRuntime.gd"' in project
    assert "func _ensure_stage_power(" in rewards
    assert "func _offer_stage_mutations(" in rewards
    assert "room_cleared.connect" in rewards
    assert 'room_id != &"combat_2"' in rewards
    assert "RogueliteContentService.add_power" in rewards
    assert "RogueliteContentService.add_mutation" in rewards
    assert "hud.show_choice" in rewards
    assert "SaveService.save_campaign" in rewards
    assert "CRÍTICO SOBRE O REVELADO" in rewards
    assert "MEMÓRIA DA FORMA" in rewards


def test_all_fifteen_matrix_powers_have_live_runtime_behaviour():
    project = read("project.godot")
    runtime = read("autoload/DefinitivePowerRuntime.gd")
    assert 'DefinitivePowerRuntime="*res://autoload/DefinitivePowerRuntime.gd"' in project
    assert "func _replace_stage_power_handler(" in runtime
    assert "func _activate_power(" in runtime
    for effect_id in [
        "revelatory_eye_base", "black_flame_matrix_base", "foundation_hammer_base",
        "election_sigil_base", "inner_balance_base", "will_vector_base",
        "character_column_base", "discipline_rhythm_base", "clarity_light_base",
        "transmutation_serpent_base", "vital_pulse_base", "hand_of_work_base",
        "sigillar_fortune_base", "verbum_base", "memoria_ignis_base",
    ]:
        assert f'"{effect_id}"' in runtime, f"matrix power runtime missing: {effect_id}"
    assert "get_signal_connection_list" in runtime
    assert "VFXDirector.emit_feedback(&\"power_reveal\"" in runtime


def test_first_person_viewmodel_matches_power_fantasy_and_animates_casting():
    player_scene = read("scenes/player/Player.tscn")
    presentation = read("scripts/player/FirstPersonPresentation.gd")
    for token in [
        'name="LeftGauntlet"', 'name="LeftSigilRingOuter"', 'name="LeftSigilRingInner"',
        'name="RightGauntlet"', 'name="RightVoidOrb"', 'name="LeftPowerLight"',
        'name="RightPowerLight"', 'script = ExtResource("3")',
    ]:
        assert token in player_scene, f"first-person reference element missing: {token}"
    for method in ["func _on_primary_attack(", "func _on_power(", "func _on_dodge(", "func _process("]:
        assert method in presentation, f"first-person presentation missing: {method}"
    assert "LeftSigilRingOuter" in presentation
    assert "RightOrbRingOuter" in presentation
    assert "create_tween" in presentation


def test_combat_room_uses_gothic_occult_presentation_without_changing_footprint():
    room = read("scenes/rooms/RoomShell.tscn")
    script = read("scripts/generation/RoomShell.gd")
    for token in ["DarkStoneMaterial", "RitualMetalMaterial", "FloorSigil", "WarmKeyLight"]:
        assert token in room, f"combat room presentation missing: {token}"
    for token in ["GothicDressing", "VaultRibs", "RitualLanterns", "DoorArches"]:
        assert token in script, f"runtime gothic chamber layer missing: {token}"
    for method in ["func _add_vault_ribs(", "func _add_ritual_lanterns(", "func _add_door_arches(", "func _apply_role_lighting("]:
        assert method in script, f"gothic room builder missing: {method}"
    assert 'room_role == &"boss"' in script
    assert 'size = Vector3(10, 0.2, 10)' in room, "room footprint must remain generation-compatible"


def test_runtime_visual_acceptance_probe_exports_actual_capture():
    probe_scene = read("runtime_qa/DefinitiveVisualProbe.tscn")
    probe = read("runtime_qa/DefinitiveVisualProbe.gd")
    workflow = read("../../.github/workflows/chronica-combat-definitive-v1.yml")
    assert "scenes/boot/Main.tscn" in probe_scene
    assert "EnemyFactory.spawn" in probe
    assert "BossBase.tscn" in probe
    assert "get_viewport().get_texture().get_image()" in probe
    assert "definitive_visual.png" in probe
    assert "Definitive visual capture" in workflow
    assert "actions/upload-artifact@v4" in workflow


def test_vfx_and_audio_have_dodge_power_feedback():
    vfx = read("autoload/VFXDirector.gd")
    audio = read("autoload/AudioDirector.gd")
    for event in ['"player_dodge"', '"perfect_dodge"', '"power_reveal"']:
        assert event in vfx, f"VFX event missing: {event}"
    assert '"perfect_dodge"' in audio
    assert '"power_reveal"' in audio


def test_definitive_hud_uses_ritual_red_violet_gold_language():
    hud = read("scenes/ui/HUD.tscn")
    for token in ["PlayerLifeFill", "PlayerFocusFill", "BossLifeFill", "GoldFrame"]:
        assert token in hud, f"missing ritual UI style: {token}"
