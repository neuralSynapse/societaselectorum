from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text())


def test_gauntlets_and_meta_runtime_are_complete():
    rows = load('data/roguelite/gauntlets.json')
    assert len(rows) == 4
    assert len({r['id'] for r in rows}) == 4
    for row in rows:
        assert row['unlock_conditions']
        assert row['modifiers']
        assert row['completion_mark']
    script = (ROOT / 'scripts/progression/MetaRunDirector.gd').read_text()
    for fn in ['set_route','add_curse','add_blessing','record_completion_mark','unlock_gauntlet','apply_floor_modifiers']:
        assert f'func {fn}' in script


def test_completion_marks_are_per_character_and_never_institutional_grade_writes():
    state = (ROOT / 'autoload/GameState.gd').read_text().lower()
    assert 'completion_marks_by_character' in state
    for forbidden in ['institutional_grade','certified_grade','initiation_certificate','real_progress_gate_write']:
        assert forbidden not in state


def test_transformations_have_visual_manifestations_not_only_effect_names():
    rows = load('data/roguelite/transformations.json')
    assert len(rows) >= 10
    for row in rows:
        assert row['visual_profile']['mesh_overlay']
        assert row['visual_profile']['material_shift']
        assert row['visual_profile']['vfx']
    script = (ROOT / 'scripts/content/TransformationDirector.gd').read_text()
    assert 'func reconcile' in script
    assert 'mesh_overlay' in script and 'material_shift' in script and 'vfx' in script
