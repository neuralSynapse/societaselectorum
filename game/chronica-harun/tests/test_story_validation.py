from copy import deepcopy
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).parents[1]


def load_validator():
    path = ROOT / 'tools/validate_story_canon.py'
    spec = importlib.util.spec_from_file_location('story_validator', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_story():
    return json.loads((ROOT / 'data/narrative/chronica_story_bible.json').read_text(encoding='utf-8'))


def test_story_validator_passes_current_canon():
    validator = load_validator()
    assert validator.validate(ROOT) == []


def test_validator_rejects_collapsing_electorum_claims_into_ancient_source():
    validator = load_validator()
    story = load_story()
    bad = deepcopy(story)
    by_id = {s['id']: s for s in bad['prologue']}
    by_id['form_without_breath']['provenance']['luciferian_light'] = 'source'
    by_id['lineage_of_mark']['provenance']['direct_harun_descent'] = 'source'
    errors = validator.validate_payload(bad)
    joined = '\n'.join(errors).lower()
    assert 'luciferian' in joined
    assert 'harun' in joined and 'caim' in joined


def test_validator_rejects_erasing_abel_or_moving_lilith_after_eve():
    validator = load_validator()
    story = load_story()
    bad = deepcopy(story)
    by_id = {s['id']: s for s in bad['prologue']}
    by_id['cain']['narration'] = 'Caim recebeu uma marca e partiu.'
    # swap narrative order while preserving IDs to simulate canon regression
    by_id['lilith_first_refusal']['order'], by_id['eve_epinoia_knowledge']['order'] = 8, 7
    errors = validator.validate_payload(bad)
    joined = '\n'.join(errors).lower()
    assert 'abel' in joined
    assert 'lilith' in joined and 'eva' in joined


def test_human_readable_canon_is_generated_and_credits_real_author_only():
    doc = (ROOT / 'docs/canon/CHRONICA_HARUN_CANONE_NARRATIVO_v2_0_2026-09-07.md').read_text(encoding='utf-8')
    assert 'Frater Horus Phosphorus' in doc
    assert 'Frater Harun é personagem' in doc
    assert 'GRIMORIUM ASCENSIONIS' in doc
    assert 'Aleppo' in doc and '1585' in doc
    assert 'VER · GOVERNAR · FAZER' in doc
