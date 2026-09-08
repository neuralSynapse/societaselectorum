from pathlib import Path

ROOT=Path(__file__).parents[1]


def test_narrative_runtime_scene_is_self_contained_and_additive():
    scene=(ROOT/'scenes/narrative/NarrativeRuntime.tscn').read_text()
    for token in ['NarrativeRuntimeBridge.gd','CosmogonyPrologueDirector.gd','HarunOriginDirector.gd','ChronicaStoryDirector.gd']:
        assert token in scene
    for node in ['CosmogonyPrologue','HarunOrigin','ChronicaStory']:
        assert f'name="{node}"' in scene


def test_bridge_persists_story_inside_meta_progression_and_never_institutional_state():
    script=(ROOT/'scripts/narrative/NarrativeRuntimeBridge.gd').read_text()
    for fn in ['start_entry_flow','bind_stage_director','current_story_state','start_epilogue']:
        assert f'func {fn}' in script
    assert 'meta_progression["story"]' in script
    assert 'SaveService.save_campaign(GameState.to_save_data())' in script
    for forbidden in ['institutional_grade','certified_grade','real_progress_gate']:
        assert forbidden not in script.lower()


def test_bridge_maps_physical_gameplay_events_to_story_beats():
    script=(ROOT/'scripts/narrative/NarrativeRuntimeBridge.gd').read_text()
    for beat in ['threshold','wound','revelation','inversion','boss_intro','boss_truth','completion']:
        assert f'&"{beat}"' in script
    assert 'room_entered' in script
    assert 'room_cleared' in script
    assert 'stage_completed' in script


def test_bridge_forwards_cinematic_payload_without_owning_camera_audio_or_mesh():
    script=(ROOT/'scripts/narrative/NarrativeRuntimeBridge.gd').read_text()
    for sig in ['narration_lines','cinematic_visual','cinematic_audio','story_message','transition_requested']:
        assert f'signal {sig}' in script
    for forbidden in ['Camera3D.new','AudioStreamPlayer.new','AudioStreamPlayer3D.new','MeshInstance3D.new']:
        assert forbidden not in script
