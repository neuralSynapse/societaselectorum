from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ROG = ROOT / 'data' / 'roguelite'

CONTRACT = {
    'id','name','rarity','pool','eligibility','effect','cost','duration','stacking',
    'synergies','exclusions','vfx_hook','sfx_hook','save_state','codex','provenance'
}


def load(name):
    return json.loads((ROG / name).read_text())


def test_front_c_runtime_contracts_are_preserved_in_governing_tree():
    files = [
        'tarot_thoth.json','sigilla_goetia.json','pharmaka.json','talismans_decanic.json',
        'instrumenta.json','powers.json','daimones.json','relics.json','transformations.json',
        'curses.json','blessings.json','routes.json'
    ]
    for name in files:
        rows = load(name)
        assert rows, name
        for row in rows:
            missing = CONTRACT - row.keys()
            assert not missing, (name, row.get('id'), sorted(missing))


def test_front_c_final_counts_and_postboss_exclusivity():
    assert len(load('tarot_thoth.json')) == 78
    assert len(load('sigilla_goetia.json')) == 72
    assert len(load('pharmaka.json')) == 21
    assert len(load('talismans_decanic.json')) == 36
    assert len(load('instrumenta.json')) == 32
    assert len(load('powers.json')) == 15
    assert len(load('daimones.json')) == 7
    assert len(load('relics.json')) == 9
    assert len(load('transformations.json')) >= 12
    assert len(load('curses.json')) == 8
    assert len(load('blessings.json')) == 6
    assert len(load('routes.json')) == 8
    rooms = load('special_rooms.json')
    assert len(rooms) >= 20
    post = [r for r in rooms if r.get('exclusive_group') == 'postboss_path']
    assert len(post) == 3
    assert {r['id'] for r in post} == {'pneumatic','chthonic','pact_table'}


def test_front_c_runtime_bridge_exists_and_knows_every_effect_kind():
    bus = (ROOT/'scripts/content/GameplayEffectBus.gd').read_text()
    room_rt = (ROOT/'scripts/rooms/SpecialRoomRuntime.gd').read_text()
    director = (ROOT/'scripts/generation/SpecialRoomDirector.gd').read_text()
    assert 'MAX_SECRET_ROOMS = 2' in director
    assert 'func dispatch' in bus
    assert 'func resolve_room' in room_rt
    effect_kinds = set()
    for name in ['tarot_thoth.json','sigilla_goetia.json','pharmaka.json','talismans_decanic.json','instrumenta.json','powers.json','daimones.json','relics.json','transformations.json','curses.json','blessings.json','routes.json']:
        for row in load(name):
            effect = row.get('effect', {})
            if isinstance(effect, dict) and effect.get('kind'):
                effect_kinds.add(effect['kind'])
    for kind in effect_kinds:
        assert f'"{kind}"' in bus, kind


def test_game_state_has_front_c_save_load_contract():
    state = (ROOT/'autoload/GameState.gd').read_text()
    for token in ['func snapshot_run','func restore_run','func save_run','func load_run']:
        assert token in state
