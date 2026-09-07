from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
STORY = json.loads((ROOT / 'data/narrative/chronica_story_bible.json').read_text())


def test_every_prologue_sequence_has_production_ready_shot_timeline():
    shots = []
    for scene in STORY['prologue']:
        assert len(scene.get('shots', [])) >= 4, scene['id']
        total = 0.0
        for shot in scene['shots']:
            for key in ['id','duration_seconds','camera','visual_event','audio_event','transition','tension']:
                assert key in shot, (scene['id'], key)
            assert shot['duration_seconds'] > 0
            assert 0.0 <= shot['tension'] <= 1.0
            total += shot['duration_seconds']
            shots.append(shot['id'])
        assert abs(total - scene['duration_seconds']) <= 0.25, scene['id']
    assert len(shots) >= 55
    assert len(shots) == len(set(shots))


def test_all_student_stages_have_a_real_choice_without_a_single_correct_answer():
    stages = STORY['student_journey']
    assert len(stages) == 16
    all_choice_ids = []
    for stage in stages:
        choice = stage.get('choice_event', {})
        assert choice.get('id')
        assert choice.get('prompt')
        assert 2 <= len(choice.get('options', [])) <= 3
        all_choice_ids.append(choice['id'])
        effect_keys = set()
        for option in choice['options']:
            assert option.get('id')
            assert option.get('label')
            assert option.get('immediate_cost')
            assert option.get('story_consequence')
            assert option.get('external_hook')
            effect_keys.add(option['external_hook'])
        assert len(effect_keys) >= 2, stage['stage_id']
    assert len(all_choice_ids) == len(set(all_choice_ids))


def test_cinematic_shot_director_contract_exists():
    script = (ROOT / 'scripts/narrative/CinematicShotDirector.gd').read_text()
    for token in ['signal shot_started','signal shot_finished','func begin_sequence','func advance','func skip_sequence','duration_seconds','transition']:
        assert token in script


def test_narrative_choice_director_persists_choice_and_only_emits_external_consequence():
    script = (ROOT / 'scripts/narrative/NarrativeChoiceDirector.gd').read_text()
    for token in ['signal choice_requested','signal consequence_requested','func present_stage_choice','func choose','narrative_choices']:
        assert token in script
    forbidden = ['real_progress_gate', 'institutional_grade', 'certified_grade']
    for token in forbidden:
        assert token not in script.lower()


def test_narrative_runtime_scene_wires_shot_and_choice_directors():
    scene=(ROOT/'scenes/narrative/NarrativeRuntime.tscn').read_text()
    bridge=(ROOT/'scripts/narrative/NarrativeRuntimeBridge.gd').read_text()
    for name in ['CinematicShots','NarrativeChoices']:
        assert f'name="{name}"' in scene
    for token in ['@onready var cinematic_shots','@onready var narrative_choices','present_stage_choice','consequence_requested']:
        assert token in bridge


def test_presentation_has_choice_ui_and_selection_signal():
    scene=(ROOT/'scenes/narrative/NarrativePresentation.tscn').read_text()
    script=(ROOT/'scripts/narrative/NarrativePresentationController.gd').read_text()
    for node in ['ChoicePanel','ChoicePrompt','ChoiceOptions','ChoiceConsequence']:
        assert f'name="{node}"' in scene
    for token in ['signal choice_selected','func present_choice','func resolve_choice','ChoiceOptions']:
        assert token in script


def test_choice_ui_freezes_world_and_supports_keyboard_selection():
    script=(ROOT/'scripts/narrative/NarrativePresentationController.gd').read_text()
    assert 'get_tree().paused = true' in script
    assert 'get_tree().paused = paused_before_choice' in script
    assert 'KEY_1' in script and 'KEY_2' in script and 'KEY_3' in script
    scene=(ROOT/'scenes/narrative/NarrativePresentation.tscn').read_text()
    assert 'process_mode = 3' in scene


def test_epilogue_has_production_ready_shots_and_bridge_uses_shot_director_for_all_cinematics():
    ep=STORY['epilogue']
    assert len(ep.get('shots', [])) >= 6
    assert abs(sum(s['duration_seconds'] for s in ep['shots']) - ep['duration_seconds']) <= 0.25
    bridge=(ROOT/'scripts/narrative/NarrativeRuntimeBridge.gd').read_text()
    assert 'cinematic_shots.begin_sequence(scene' in bridge
    assert 'cinematic_shots.begin_sequence(epilogue' in bridge
    assert 'scene_title_requested' in bridge


def test_presentation_binds_scene_title_signal():
    script=(ROOT/'scripts/narrative/NarrativePresentationController.gd').read_text()
    assert 'bridge.scene_title_requested.connect(set_scene_title)' in script
