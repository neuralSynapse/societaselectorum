from pathlib import Path
import json

ROOT=Path(__file__).parents[1]


def test_narrative_presentation_scene_has_letterbox_titles_subtitles_and_skip_hint():
    scene=(ROOT/'scenes/narrative/NarrativePresentation.tscn').read_text()
    script=(ROOT/'scripts/narrative/NarrativePresentationController.gd').read_text()
    for node in ['TopBar','BottomBar','SceneTitle','Subtitle','SkipHint','StoryMessage']:
        assert f'name="{node}"' in scene
    for fn in ['bind_bridge','present_lines','show_story_message','set_scene_title','set_skip_available']:
        assert f'func {fn}' in script
    assert 'advance_requested' in script
    assert 'skip_requested' in script


def test_bridge_can_advance_and_skip_active_story_sequence():
    script=(ROOT/'scripts/narrative/NarrativeRuntimeBridge.gd').read_text()
    for fn in ['advance_active_sequence','skip_active_sequence']:
        assert f'func {fn}' in script
    assert 'active_sequence' in script
    assert '&"cosmogony"' in script and '&"harun_origin"' in script


def test_story_codex_has_scene_stage_motif_and_epilogue_entries_with_provenance():
    rows=json.loads((ROOT/'data/codex/story_codex.json').read_text(encoding='utf-8'))
    story=json.loads((ROOT/'data/narrative/chronica_story_bible.json').read_text(encoding='utf-8'))
    ids={r['id'] for r in rows}
    for scene in story['prologue']:
        assert 'story_scene:'+scene['id'] in ids
    for stage in story['student_journey']:
        assert 'story_stage:'+stage['stage_id'] in ids
    for motif in story['recurring_motifs']:
        assert 'story_motif:'+motif in ids
    assert 'story_epilogue:aleppo_1585' in ids
    allowed={'source','tradition','interpretation','electorum_dramatization'}
    for row in rows:
        assert row['provenance_class'] in allowed
        assert row['body']
        assert row['unlock_key']


def test_story_codex_service_unlocks_without_touching_institutional_progress():
    script=(ROOT/'scripts/narrative/StoryCodexService.gd').read_text()
    for fn in ['unlock','is_unlocked','entry','all_unlocked']:
        assert f'func {fn}' in script
    assert 'meta_progression["story_codex"]' in script
    for forbidden in ['institutional_grade','certified_grade','real_progress_gate']:
        assert forbidden not in script.lower()
