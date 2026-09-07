from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_main_mounts_and_configures_world_expansion_runtime():
    scene=(ROOT/'scenes/boot/Main.tscn').read_text()
    script=(ROOT/'scripts/boot/Main.gd').read_text()
    assert 'WorldExpansionRuntime.tscn' in scene
    assert 'WorldExpansionRuntime' in scene
    for token in ['world_expansion.configure_player(stage_director.player)','world_expansion.on_stage_started','world_expansion.on_boss_defeated']:
        assert token in script

def test_player_inputs_expose_camera_and_three_kinesis_slots():
    project=(ROOT/'project.godot').read_text()
    player=(ROOT/'scripts/player/PlayerController.gd').read_text()
    for action in ['camera_toggle','kinesis_1','kinesis_2','kinesis_3']:
        assert action+'=' in project
    for token in ['signal camera_mode_requested','signal kinesis_slot_requested','camera_toggle','kinesis_1','kinesis_2','kinesis_3']:
        assert token in player

def test_stage_director_integrates_world_expansion_special_rooms_and_kinesis():
    script=(ROOT/'scripts/progression/StageDirector.gd').read_text()
    for token in ['func attach_world_expansion','_on_kinesis_slot_requested','eden','arbor_mortis','liminal_laboratory','sacrifice','pneumatic','chthonic','pact_table']:
        assert token in script
    assert 'world_expansion.on_room_cleared' in script

def test_hud_displays_camera_and_kinesis_loadout():
    scene=(ROOT/'scenes/ui/HUD.tscn').read_text()
    script=(ROOT/'scripts/ui/HUDController.gd').read_text()
    for token in ['KinesisState','CameraMode']:
        assert token in scene
    for token in ['func set_kinesis_loadout','func set_camera_mode']:
        assert token in script
