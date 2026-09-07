from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text())


def test_theophanies_and_historical_echoes_have_contextual_conditions_and_provenance():
    theophanies = load('data/roguelite/theophanies.json')
    echoes = load('data/roguelite/historical_echoes.json')
    assert len(theophanies) >= 18
    assert len(echoes) >= 6
    for row in theophanies + echoes:
        assert row['appearance'] in {'vision_or_patron','narrative_echo','judge','blessing','pact','memory'}
        assert row['provenance_class'] in {'source','tradition','interpretation','electorum_dramatization','source_inspired_synthesis'}
        assert row['conditions']
        assert row['codex_note']


def test_vision_director_never_defaults_historical_figures_to_enemies():
    script = (ROOT / 'scripts/narrative/VisionDirector.gd').read_text()
    for fn in ['eligible_theophanies','eligible_historical_echoes','trigger_theophany','trigger_historical_echo']:
        assert f'func {fn}' in script
    assert 'spawn_enemy' not in script
    assert 'narrative_echo' in script
    assert 'vision_or_patron' in script


def test_codex_provenance_registry_has_explicit_four_layer_labels():
    codex = load('data/codex/full_codex.json')
    labels = {row['provenance_class'] for row in codex}
    assert {'source','tradition','interpretation','electorum_dramatization'}.issubset(labels)
    assert all(row.get('source_note') for row in codex)
