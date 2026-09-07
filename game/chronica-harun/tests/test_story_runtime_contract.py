import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
STORY = ROOT / 'data/narrative/chronica_story_bible.json'


def load_story():
    return json.loads(STORY.read_text(encoding='utf-8'))


def test_cinematic_profile_is_game_length_and_every_prologue_scene_is_directable():
    story = load_story()
    profile = story['cinematic_profile']
    assert profile['first_view_target_seconds'][0] >= 420
    assert profile['first_view_target_seconds'][1] <= 540
    total = sum(scene['duration_seconds'] for scene in story['prologue'])
    assert 420 <= total <= 540
    assert profile['narration_density'] == 'cinematic_sparse'
    assert profile['horror_rule'] == 'dread_before_explanation'
    for scene in story['prologue']:
        assert 1 <= len(scene['voiceover']) <= 6
        assert all((4 <= len(line.split()) <= 28) or line in {'VER.','GOVERNAR.','FAZER.'} for line in scene['voiceover'])
        assert 0.0 <= scene['tension'] <= 1.0
        assert scene['cinematic_hook']
        assert scene['exit_image']
        assert scene['player_learning']


def test_prologue_has_escalation_release_and_human_emotional_pivot():
    story = load_story()
    p = {s['id']: s for s in story['prologue']}
    assert p['before_dark']['tension'] < p['first_scream']['tension']
    assert p['blind_god']['tension'] >= 0.8
    assert p['form_without_breath']['tension'] >= 0.85
    assert p['lilith_first_refusal']['emotion_pivot'] == 'freedom_has_a_cost'
    assert p['cain']['emotion_pivot'] == 'irreversibility'
    assert p['lineage_of_mark']['emotion_pivot'] == 'inheritance_without_innocence'
    assert p['dismembered_book']['emotion_pivot'] == 'obsession_becomes_method'
    assert p['see_govern_make']['emotion_pivot'] == 'agency'


def test_cosmogony_director_owns_0_through_9_and_skip_unlocks_only_after_completion():
    script = (ROOT / 'scripts/narrative/CosmogonyPrologueDirector.gd').read_text()
    for fn in ['start', 'advance', 'skip', 'current_scene', 'mark_completed', 'configure']:
        assert f'func {fn}' in script
    for sig in ['scene_started', 'narration_requested', 'visual_requested', 'audio_requested', 'prologue_finished', 'completion_persist_requested']:
        assert f'signal {sig}' in script
    assert 'slice(0, 10)' in script
    assert 'prologue_completed' in script
    assert 'skip_unlocked' in script


def test_harun_origin_requires_all_fragments_before_grimorium_title_reveal():
    script = (ROOT / 'scripts/narrative/HarunOriginDirector.gd').read_text()
    for fn in ['configure', 'begin_origin_sequence', 'register_fragment', 'can_reveal_title', 'reveal_title', 'advance']:
        assert f'func {fn}' in script
    assert 'reveal_requires_all' in script
    assert 'GRIMORIUM ASCENSIONIS' in script
    assert 'fragment_ids' in script


def test_chronica_story_director_covers_15_stages_initiation_and_epilogue_without_institutional_write():
    script = (ROOT / 'scripts/narrative/ChronicaStoryDirector.gd').read_text()
    for fn in ['configure', 'begin_stage', 'trigger', 'complete_stage', 'begin_epilogue']:
        assert f'func {fn}' in script
    for sig in ['beat_started', 'stage_story_completed', 'epilogue_started', 'epilogue_finished']:
        assert f'signal {sig}' in script
    assert 'PEREGRINUS_IGNIS_GAME' in script
    low = script.lower()
    for forbidden in ['institutional_grade', 'certified_grade', 'real_progress_gate']:
        assert forbidden not in low


def test_story_directors_never_own_rendering_or_audio_players():
    text = '\n'.join((ROOT / 'scripts/narrative' / f).read_text() for f in [
        'CosmogonyPrologueDirector.gd', 'HarunOriginDirector.gd', 'ChronicaStoryDirector.gd'
    ])
    for forbidden in ['Camera3D.new', 'AudioStreamPlayer.new', 'AudioStreamPlayer3D.new', 'MeshInstance3D.new']:
        assert forbidden not in text


def test_each_student_stage_has_full_dramatic_arc_not_just_lore_labels():
    story = load_story()
    required = {'threshold','wound','revelation','inversion','boss_intro','boss_truth','completion'}
    for stage in story['student_journey']:
        ids = {b['id'] for b in stage['beats']}
        assert required.issubset(ids), stage['stage_id']
        for key in ['opening_image','personal_stake','choice_under_pressure','boss_revelation','reward_meaning','foreshadow','stage_voiceover']:
            assert stage[key], (stage['stage_id'], key)
        assert 2 <= len(stage['stage_voiceover']) <= 5


def test_recurring_motifs_bind_cosmogony_harun_and_aleppo():
    story = load_story()
    motifs = story['recurring_motifs']
    for key in ['missing_frequency','breath','hand_and_mark','door','second_shadow','unlit_wick']:
        assert key in motifs
        assert len(motifs[key]['appearances']) >= 2
    assert 'aleppo_1585' in motifs['second_shadow']['appearances']
    assert 'aleppo_1585' in motifs['unlit_wick']['appearances']


def test_epilogue_is_short_cinematic_and_hands_off_to_opus_lux_ferre():
    ep = load_story()['epilogue']
    assert 35 <= ep['duration_seconds'] <= 90
    assert 2 <= len(ep['voiceover']) <= 6
    assert ep['continuity_target'] == 'OPUS_LUX_FERRE_LIVRO_ZERO'
    assert ep['final_word'] == 'LUCIFER'
    assert ep['cut_to_black_after_final_word'] is True
