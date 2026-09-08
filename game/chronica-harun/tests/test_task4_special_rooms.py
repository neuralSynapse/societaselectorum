from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text())


def test_special_room_catalog_has_all_approved_room_types_and_rules():
    rows = load('data/roguelite/special_rooms.json')
    ids = {r['id'] for r in rows}
    required = {
        'arcana','reliquary','instrumentarium','laboratorium','sigillar','market',
        'bibliotheca','speculum','planetary','trial','cursed','secret','super_secret',
        'archon','theophany','historical_echo','initiation','solar_benediction','chthonic_pact'
    }
    assert required.issubset(ids)
    for row in rows:
        for field in ['eligibility','access','risk','reward_pool','telegraph','min_stage','max_per_floor']:
            assert field in row, (row['id'], field)
        assert 0.0 <= row['base_chance'] <= 1.0


def test_special_room_runtime_resolves_eligibility_and_post_boss_exclusivity():
    script = (ROOT / 'scripts/generation/SpecialRoomDirector.gd').read_text()
    for fn in ['eligible_rooms','roll_floor_rooms','choose_post_boss_room','record_post_boss_choice','can_open_secret']:
        assert f'func {fn}' in script
    for token in ['solar_benediction','chthonic_pact','post_boss_choice','rupture_charge','super_secret']:
        assert token in script


def test_stage_floor_builder_integrates_special_room_director_physically():
    builder = (ROOT / 'scripts/generation/StageFloorBuilder.gd').read_text()
    stage = (ROOT / 'scripts/progression/StageDirector.gd').read_text()
    assert 'SpecialRoomDirector' in builder
    assert 'SpecialRoomDirector' in stage
    assert 'spawn_special_room' in builder
    assert 'spawn_special_reward' in stage
