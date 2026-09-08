from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def text(rel):
    return (ROOT / rel).read_text()


def load(rel):
    return json.loads((ROOT / rel).read_text())


def test_content_service_exposes_active_use_and_meta_grant_apis():
    script = text('autoload/RogueliteContentService.gd')
    for fn in [
        'grant', 'use_arcana', 'use_pharmakon', 'use_instrumentum',
        'recharge_instrument', 'bind_sigillum', 'equip_talisman',
        'equip_relic', 'set_daimon', 'add_mutation', 'set_route',
    ]:
        assert f'func {fn}' in script
    for category in ['blessings', 'curses', 'routes', 'transformations']:
        assert f'"{category}"' in script


def test_all_atu_and_instrument_effect_ids_have_explicit_dispatch():
    script = text('autoload/RogueliteContentService.gd')
    tarot = load('data/roguelite/tarot_thoth.json')
    instrumenta = load('data/roguelite/instrumenta.json')
    for row in tarot:
        if row.get('group') == 'atu':
            assert '"' + row['effect_id'] + '"' in script
    for row in instrumenta:
        assert '"' + row['effect_id'] + '"' in script


def test_stage_director_executes_content_effect_requests_against_world_state():
    script = text('scripts/progression/StageDirector.gd')
    assert 'RogueliteContentService.effect_requested.connect' in script
    assert 'func _on_content_effect' in script
    for action in ['reveal_secrets', 'ritual_explosion', 'freeze_room', 'dominate', 'heal_and_reward']:
        assert action in script
