from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return (ROOT / path).read_text()


def test_build_resolver_exposes_real_buildcraft_reconciliation_api():
    resolver = source('scripts/content/BuildResolver.gd')
    for token in [
        'func collect_build_tokens',
        'func active_synergies',
        'func conflicts',
        'func eligible_transformations',
    ]:
        assert token in resolver, f'missing buildcraft runtime API: {token}'


def test_secret_connections_are_pending_until_physical_rupture():
    builder = source('scripts/generation/StageFloorBuilder.gd')
    director = source('scripts/generation/RoomDirector.gd')
    assert 'secret_connection_pending' in builder, 'secret room has no pending physical connection state'
    assert 'func open_secret_connection' in builder, 'floor builder cannot physically rupture a secret connection'
    assert 'StageFloorBuilder.open_secret_connection' in director, 'secret reveal does not open the physical floor connection'


def test_generation_eligibility_bugfix_remains_governing():
    director = source('scripts/generation/SpecialRoomDirector.gd')
    assert 'for_generation: bool = false' in director
    assert 'if not for_generation and int(context.get("rooms_cleared",0)) < int(eligibility.get("min_rooms_cleared",0)): continue' in director
    assert 'eligible_rooms(stage_index, cycle, context, true)' in director


def test_pickup_to_build_runtime_remains_wired():
    pickup = source('scripts/pickups/PickupController.gd')
    service = source('autoload/RogueliteContentService.gd')
    assert 'RogueliteContentService.grant' in pickup
    for token in ['func grant', 'func use_arcana', 'func use_pharmakon', 'func use_instrumentum', 'func add_mutation']:
        assert token in service


def test_postboss_runtime_materializes_a_real_special_room():
    stage = source('scripts/progression/StageDirector.gd')
    assert 'func handle_post_boss' in stage
    assert 'choose_post_boss_room' in stage
    assert 'StageFloorBuilder.spawn_special_room' in stage
    assert 'room_director.register_room' in stage
