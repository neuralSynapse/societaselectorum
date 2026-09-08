from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def text(rel):
    return (ROOT / rel).read_text()


def test_playable_runtime_has_combat_entities_projectiles_pickups_and_hud():
    required = [
        'scripts/combat/Health.gd',
        'scripts/combat/AttackStateMachine.gd',
        'scripts/combat/Projectile.gd',
        'scripts/ai/EnemyBrain.gd',
        'scripts/ai/DataEnemy.gd',
        'scripts/content/EnemyFactory.gd',
        'scripts/bosses/DataBossController.gd',
        'scripts/pickups/PickupController.gd',
        'scripts/ui/HUDController.gd',
        'scripts/generation/RoomDirector.gd',
        'autoload/AudioDirector.gd',
        'scenes/vfx/Projectile.tscn',
        'scenes/pickups/WorldPickup.tscn',
        'scenes/ui/HUD.tscn',
    ]
    for rel in required:
        assert (ROOT / rel).exists(), rel


def test_player_contract_has_real_first_person_combat_inputs_and_health():
    script = text('scripts/player/PlayerController.gd')
    scene = text('scenes/player/Player.tscn')
    for token in [
        'primary_attack_requested', 'power_requested', 'instrument_requested',
        'consume_requested', 'rupture_charge_requested', 'func apply_damage',
        'Input.MOUSE_MODE_CAPTURED', 'pitch = clamp',
    ]:
        assert token in script
    for token in ['Camera3D', 'Health', 'ViewModelRoot', 'InteractionRay']:
        assert token in scene
    assert 'invert_y := false' in script


def test_enemy_and_boss_runtime_are_data_driven_and_world_space():
    enemy = text('scripts/ai/DataEnemy.gd')
    factory = text('scripts/content/EnemyFactory.gd')
    boss = text('scripts/bosses/DataBossController.gd')
    for token in ['configure_from_data', 'AttackStateMachine', 'global_position', 'distance_to_target']:
        assert token in enemy
    assert 'ContentRegistry.get_enemy' in factory
    assert 'model_path' in factory
    for token in ['ContentRegistry.get_boss', 'phase_changed', 'boss_defeated', 'AttackStateMachine']:
        assert token in boss


def test_stage_director_connects_encounters_rewards_mutations_daimon_and_transformations():
    script = text('scripts/progression/StageDirector.gd')
    for token in [
        'func configure', '_spawn_combat_room', '_spawn_boss', 'EnemyFactory.spawn',
        'DataBossController', 'spawn_special_reward', 'RogueliteContentService.grant',
        'PowerMutationRuntime', 'DaimonRuntime', 'TransformationDirector',
        'room_director.register_enemy', 'hud.show_boss',
    ]:
        assert token in script


def test_room_runtime_physically_locks_encounters_and_secret_openings():
    director = text('scripts/generation/RoomDirector.gd')
    shell = text('scenes/rooms/RoomShell.tscn')
    for fn in ['activate_room', 'lock_room', 'clear_room', 'open_secret', 'register_enemy']:
        assert f'func {fn}' in director
    for token in ['EncounterTrigger', 'NorthWall', 'SouthWall', 'EastWall', 'WestWall', 'DoorSet']:
        assert token in shell


def test_main_boot_instantiates_stage_player_hud_and_vision_runtime():
    main = text('scripts/boot/Main.gd')
    scene = text('scenes/boot/Main.tscn')
    for token in ['StageDirector', 'VisionDirector', 'MetaRunDirector', 'WorldRoot', 'UIRoot']:
        assert token in scene or token in main
    assert 'stage_director.configure' in main
