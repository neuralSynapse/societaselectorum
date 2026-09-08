from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return (ROOT / path).read_text()


def test_gauntlet_runtime_can_start_track_and_complete_current_catalog_challenges():
    meta = source('scripts/progression/MetaRunDirector.gd')
    for token in ['func start_gauntlet', 'func record_gauntlet_room_clear', 'func complete_gauntlet']:
        assert token in meta, f'missing gauntlet runtime bridge: {token}'
    assert 'completion_mark' in meta
    assert 'completed_gauntlets' in meta


def test_stage_runtime_counts_real_room_clears_for_active_gauntlets():
    stage = source('scripts/progression/StageDirector.gd')
    assert 'record_gauntlet_room_clear' in stage


def test_current_gauntlet_catalog_is_preserved_not_replaced_by_historical_ids():
    catalog = (ROOT / 'data/roguelite/gauntlets.json').read_text()
    for current_id in ['blind_crown', 'seven_authorities', 'phosphoros_trial', 'pleroma_return']:
        assert f'"{current_id}"' in catalog
    for historical_id in ['gauntlet_seven_thresholds', 'gauntlet_speculum_circuit', 'gauntlet_saturnine_crucible', 'gauntlet_blind_throne']:
        assert historical_id not in catalog
