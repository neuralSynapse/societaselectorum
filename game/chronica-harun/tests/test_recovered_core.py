from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text())


def test_project_has_required_autoloads_and_first_person_contract():
    project = (ROOT / 'project.godot').read_text()
    for token in ['GameState=', 'SaveService=', 'ContentRegistry=', 'RogueliteContentService=']:
        assert token in project
    player = (ROOT / 'scripts/player/PlayerController.gd').read_text()
    for token in ['Input.get_vector', 'mouse', 'Camera3D', 'move_and_slide']:
        assert token.lower() in player.lower()
    assert 'third_person' not in player.lower()


def test_student_journey_core_counts_and_chain():
    journey = load('data/stages/student_journey.json')
    enemies = load('data/enemies/student_enemies.json')
    bosses = load('data/bosses/student_bosses.json')
    assert len(journey) == 16
    assert len(enemies) >= 82
    assert len(bosses) == 16
    ids = [x['id'] for x in journey]
    for i, row in enumerate(journey[:-1]):
        assert row['next_stage'] == ids[i+1]
    assert journey[-1]['next_stage'] == 'PEREGRINUS_IGNIS_GAME'
    assert all(len(b['phases']) == 3 for b in bosses)


def test_roguelite_catalog_counts_are_preserved():
    counts = {
        'data/roguelite/tarot_thoth.json': 78,
        'data/roguelite/sigilla_goetia.json': 72,
        'data/roguelite/pharmaka.json': 21,
        'data/roguelite/talismans_decanic.json': 36,
        'data/roguelite/instrumenta.json': 32,
        'data/roguelite/powers.json': 15,
        'data/roguelite/daimones.json': 7,
        'data/roguelite/curses.json': 8,
        'data/roguelite/blessings.json': 6,
        'data/roguelite/routes.json': 8,
    }
    for rel, count in counts.items():
        assert len(load(rel)) == count, rel
    powers = load('data/roguelite/powers.json')
    assert sum(len(p['mutations']) for p in powers) == 45
