from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text(encoding='utf-8'))


def test_nine_libri_are_preserved_as_progression_domains_not_mislabeled_as_nine_kinesis_volumes():
    libri = load('data/kinesis/nine_libri_progression.json')
    assert len(libri) == 9
    ids = [x['id'] for x in libri]
    assert ids == [
        'liber_harun','liber_vis_psychicae','liber_atramenti_sanguinis','liber_ars_occulta',
        'liber_paradoxi_temporalis','liber_architecturae_mentis','liber_somniorum_projectionis',
        'liber_laboratorii_arcani','liber_manifestationis_hermeticae'
    ]
    for row in libri:
        assert row['progression_tree']['nodes']
        assert row['unlock_condition']
        assert row['gameplay_identity']
        assert row['provenance']['level']
    assert libri[1]['genealogy']['kinesis_field'] is True
    assert libri[0]['genealogy']['kinesis_field'] is False


def test_vis_psychicae_contains_distinct_kinesis_families_as_gameplay_powers():
    data = load('data/kinesis/kinetic_disciplines.json')
    ids = {x['id'] for x in data}
    expected = {
        'telekinesis','electrokinesis','pyrokinesis','geokinesis','cryokinesis','aerokinesis',
        'hydrokinesis','technokinesis','biokinesis','sonokinesis','luminokinesis'
    }
    assert expected.issubset(ids)
    for row in data:
        assert row['ability']['kind']
        assert row['ability']['cost']
        assert row['ability']['cooldown'] >= 0
        assert row['combat_hooks']
        assert row['provenance']['scientific_status'] == 'fictional_gameplay_dramatization'


def test_quantum_layer_uses_real_concepts_but_marks_gameplay_as_dramatization():
    quantum = load('data/quantum/quantum_mechanics.json')
    concepts = {x['id'] for x in quantum['concepts']}
    assert {'superposition','measurement','decoherence','entanglement','tunneling','branching'}.issubset(concepts)
    assert quantum['epistemic_rule']['real_physics_is_not_paranormal_proof'] is True
    assert quantum['epistemic_rule']['gameplay_effects_are_electorum_dramatization'] is True
    assert quantum['secret_room']['id'] == 'quantum_liminal_lab'
    assert quantum['secret_room']['access']['hidden'] is True
    assert quantum['branch_corridor']['doors'] >= 3
    assert quantum['branch_corridor']['copy_reference_media'] is False


def test_ritual_tools_and_altars_can_be_weapons_without_flattening_their_ritual_identity():
    items = load('data/combat/ritual_arsenal.json')
    assert len(items) >= 16
    ids = {x['id'] for x in items}
    assert {'ritual_sword','athame','wand','staff','chalice','pentacle','censer','bell','earth_altar_focus','luciferian_altar_focus'}.issubset(ids)
    for item in items:
        assert item['ritual_role']
        assert item['combat_profile']['kind']
        assert item['unlock']
        assert item['vfx_hook'] and item['sfx_hook']


def test_quantum_kinesis_runtime_directors_are_concrete():
    expected = {
        'scripts/kinesis/KinesisProgressionDirector.gd': ['func unlock_node','func equip_ability','func use_ability','func current_loadout'],
        'scripts/quantum/QuantumRiftDirector.gd': ['func can_open_lab','func enter_superposition','func measure_branch','func exit_branch_corridor'],
        'scripts/combat/RitualArsenalDirector.gd': ['func unlock_weapon','func equip_weapon','func primary_attack_profile'],
    }
    for rel, tokens in expected.items():
        text = (ROOT / rel).read_text(encoding='utf-8')
        for token in tokens:
            assert token in text, (rel, token)


def test_quantum_branching_and_kinesis_persist_only_as_game_state():
    text = '\n'.join([
        (ROOT/'scripts/kinesis/KinesisProgressionDirector.gd').read_text(encoding='utf-8'),
        (ROOT/'scripts/quantum/QuantumRiftDirector.gd').read_text(encoding='utf-8'),
    ]).lower()
    for forbidden in ['real_progress_gate','institutional_grade','grant_grade','certified_grade']:
        assert forbidden not in text
    assert 'meta_progression' in text or 'run_build' in text
