from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text(encoding='utf-8'))


def test_eden_and_arbor_mortis_are_canonical_mirrored_power_rooms():
    data = load('data/world/eden_mortis.json')
    assert data['eden']['id'] == 'room_eden'
    assert data['arbor_mortis']['id'] == 'room_arbor_mortis'
    assert data['eden']['first_entry_free'] is True
    assert data['eden']['repeat_entry_cost']['resource'] == 'eden_key'
    assert data['eden']['tree'] == 'arbor_vitae'
    assert data['arbor_mortis']['tree'] == 'arbor_mortis'
    assert data['arbor_mortis']['risk']['kind'] in {'curse','sacrifice','debt'}
    fruits = data['fruits']
    assert len(fruits) >= 12
    assert len({f['id'] for f in fruits}) == len(fruits)
    assert any(f['id'] == 'fruit_knowledge_good_evil' for f in fruits)
    for fruit in fruits:
        assert fruit['effect']['kind']
        assert fruit['provenance']['level']
        assert fruit['vfx_hook'] and fruit['sfx_hook']


def test_every_student_stage_has_one_primary_mentor_and_provenance():
    stages = load('data/stages/student_journey.json')
    mentors = load('data/narrative/stage_mentors.json')
    assert len(mentors) == len(stages) == 16
    assert {m['stage_id'] for m in mentors} == {s['id'] for s in stages}
    assert len({m['mentor_id'] for m in mentors}) >= 12
    for row in mentors:
        assert row['mentor_name']
        assert row['mentor_type'] in {
            'theophany','historical_rift','historical_projection','traditional_figure',
            'diegic_ancestor','mythic_tradition','future_self'
        }
        assert row['delivery_mode'] in {'ritual_rift','vision','projection','manuscript','dream','threshold'}
        assert row['lesson']
        assert row['mission']['objectives']
        assert row['reward_hook']
        assert row['provenance']['level']


def test_crowley_and_ford_are_present_but_not_given_fake_quotes():
    mentors = load('data/narrative/stage_mentors.json')
    by_id = {m['mentor_id']: m for m in mentors}
    assert 'aleister_crowley' in by_id
    assert 'michael_w_ford' in by_id
    assert by_id['aleister_crowley']['mentor_type'] == 'historical_rift'
    assert by_id['michael_w_ford']['mentor_type'] == 'historical_projection'
    for row in (by_id['aleister_crowley'], by_id['michael_w_ford']):
        assert row['no_invented_quotes'] is True
        assert 'quoted_dialogue' not in row
        assert row['provenance']['level'] in {'source','interpretation'}


def test_temporal_rifts_are_ritual_gated_and_mission_driven():
    rifts = load('data/narrative/temporal_rifts.json')
    assert len(rifts) >= 6
    assert len({r['id'] for r in rifts}) == len(rifts)
    for rift in rifts:
        assert rift['ritual']['requirements']
        assert rift['mission']['objectives']
        assert rift['return_condition']
        assert rift['save_state']['persist'] is True
        assert rift['provenance']['level']


def test_runtime_directors_exist_for_eden_time_mentors_roster_and_camera():
    expected = {
        'scripts/world/EdenMortisDirector.gd': ['func request_entry','func choose_fruit'],
        'scripts/narrative/TemporalRiftDirector.gd': ['func open_rift','func complete_objective','func return_from_rift'],
        'scripts/narrative/MentorDirector.gd': ['func begin_stage_mentor','func complete_mentor_mission'],
        'scripts/meta/CharacterSanctumDirector.gd': ['func available_characters','func select_character'],
        'scripts/player/CameraModeController.gd': ['func set_mode','first_person','over_shoulder'],
    }
    for rel, tokens in expected.items():
        text = (ROOT / rel).read_text(encoding='utf-8')
        for token in tokens:
            assert token in text, (rel, token)


def test_playable_roster_uses_unlock_conditions_and_keeps_harun_default():
    roster = load('data/characters/playable_roster.json')
    assert roster[0]['id'] == 'harun'
    ids = {r['id'] for r in roster}
    assert {'harun','caim','lilith'}.issubset(ids)
    assert len(roster) >= 9
    for row in roster:
        assert row['unlock']
        assert row['starting_build']
        assert row['completion_mark_set']
        assert row['silhouette_profile']


def test_camera_modes_preserve_first_person_as_default():
    config = load('data/settings/camera_modes.json')
    assert config['default'] == 'first_person'
    assert config['modes']['first_person']['shows_player_body'] is False
    assert config['modes']['over_shoulder']['shows_player_body'] is True
    assert config['modes']['over_shoulder']['combat_aim_source'] == 'world_camera'
    assert config['rules']['enemies_never_parented_to_camera'] is True
