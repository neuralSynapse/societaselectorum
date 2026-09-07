from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_expansion_runtime_scene_mounts_all_new_systems():
    scene=(ROOT/'scenes/systems/WorldExpansionRuntime.tscn').read_text(encoding='utf-8')
    for token in ['EdenMortisDirector','TemporalRiftDirector','MentorDirector','CharacterSanctumDirector','KinesisProgressionDirector','QuantumRiftDirector','RitualArsenalDirector']:
        assert token in scene


def test_expansion_bridge_connects_player_camera_and_exposes_stage_hook():
    script=(ROOT/'scripts/world/WorldExpansionRuntime.gd').read_text(encoding='utf-8')
    for token in ['func configure_player','func on_stage_started','func on_room_cleared','func on_boss_defeated','CameraModeController']:
        assert token in script
