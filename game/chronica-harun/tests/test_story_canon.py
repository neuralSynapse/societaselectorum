import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
STORY = ROOT / 'data' / 'narrative' / 'chronica_story_bible.json'


def load_story():
    return json.loads(STORY.read_text(encoding='utf-8'))


def test_story_bible_has_canonical_top_level_contract():
    story = load_story()
    assert story['work'] == 'CHRONICA HARUN'
    assert story['real_author_credit'] == 'Frater Horus Phosphorus'
    assert story['harun_is_character'] is True
    assert set(story) >= {'canon_rules', 'prologue', 'student_journey', 'epilogue'}
    assert story['canon_rules']['institutional_progression_write'] is False


def test_prologue_chronology_and_horror_arc_are_exact():
    story = load_story()
    prologue = story['prologue']
    ids = [scene['id'] for scene in prologue]
    assert ids == [
        'before_dark', 'pleroma', 'sophia_at_edge', 'first_scream',
        'blind_god', 'lower_architecture', 'form_without_breath',
        'lilith_first_refusal', 'eve_epinoia_knowledge', 'cain',
        'lineage_of_mark', 'dismembered_book', 'see_govern_make'
    ]
    assert prologue[0]['anchor'] == 'Antes do primeiro céu, não havia lugar para onde cair.'
    assert prologue[-1]['transition']['target_stage'] == 'o_olho'
    assert all(scene['order'] == i for i, scene in enumerate(prologue))
    for scene in prologue:
        assert scene['narration']
        assert scene['visual']
        assert scene['audio']
        assert scene['emotion']
        assert scene['strategy']
        assert scene['provenance']


def test_sophia_lucifer_lilith_eve_and_cain_provenance_stay_separated():
    story = load_story()
    by_id = {s['id']: s for s in story['prologue']}
    assert by_id['sophia_at_edge']['provenance']['primary_class'] == 'source'
    assert by_id['form_without_breath']['provenance']['luciferian_light'] == 'electorum_dramatization'
    assert by_id['lilith_first_refusal']['provenance']['primary_class'] == 'electorum_dramatization'
    assert by_id['eve_epinoia_knowledge']['provenance']['primary_class'] in {'source', 'interpretation'}
    cain = by_id['cain']
    joined = json.dumps(cain, ensure_ascii=False).lower()
    assert 'abel' in joined
    assert 'proteção' in joined or 'protecao' in joined
    assert 'assassin' in joined or 'morte' in joined
    assert cain['provenance']['lineage_reading'] == 'tradition'
    lineage = by_id['lineage_of_mark']
    assert lineage['provenance']['direct_harun_descent'] == 'electorum_dramatization'


def test_student_journey_has_15_stages_plus_initiation_with_personal_harun_arc():
    story = load_story()
    rows = story['student_journey']
    assert len(rows) == 16
    expected = [
        'o_olho','a_chama','a_obra_fundacao','autoelection','autorresponsabilidade',
        'verdadeira_vontade','carater','disciplina','clareza','transmutacao',
        'corpo_energia','obra','fortuna','influencia','legado','initiation_chamber'
    ]
    assert [r['stage_id'] for r in rows] == expected
    for row in rows:
        assert row['harun_conflict']
        assert row['dramatic_question']
        assert row['horror_device']
        assert row['strategic_lesson']
        assert len(row['beats']) >= 4
    assert rows[-1]['completion_state'] == 'PEREGRINUS_IGNIS_GAME'


def test_epilogue_closes_on_aleppo_1585_nadir_second_shadow_and_lucifer():
    story = load_story()
    epilogue = story['epilogue']
    assert epilogue['location'] == 'Aleppo'
    assert epilogue['date_display'] == 'c. 1585'
    assert epilogue['nadir_enters'] is True
    assert epilogue['second_wick_unlit'] is True
    assert epilogue['second_shadow_present'] is True
    assert epilogue['final_word'] == 'LUCIFER'
    assert epilogue['continuity_target'] == 'OPUS_LUX_FERRE_LIVRO_ZERO'
