from pathlib import Path
import hashlib, json

ROOT = Path(__file__).resolve().parents[1]


def load(rel):
    return json.loads((ROOT / rel).read_text())


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def test_every_enemy_and_boss_has_unique_nonempty_glb_and_manifest():
    enemies = load('data/enemies/student_enemies.json')
    bosses = load('data/bosses/student_bosses.json')
    enemy_manifest = load('art/generated/enemies/manifest.json')
    boss_manifest = load('art/generated/bosses/manifest.json')
    enemy_hashes = []
    boss_hashes = []
    for row in enemies:
        assert row['model_path'].startswith('res://art/generated/enemies/')
        path = ROOT / row['model_path'].replace('res://', '')
        assert path.exists() and path.stat().st_size > 700
        h = digest(path); enemy_hashes.append(h)
        assert enemy_manifest[row['id']]['sha256'] == h
        assert enemy_manifest[row['id']]['vertices'] > 20
    for row in bosses:
        assert row['model_path'].startswith('res://art/generated/bosses/')
        path = ROOT / row['model_path'].replace('res://', '')
        assert path.exists() and path.stat().st_size > 1000
        h = digest(path); boss_hashes.append(h)
        assert boss_manifest[row['id']]['sha256'] == h
        assert boss_manifest[row['id']]['vertices'] > 30
    assert len(set(enemy_hashes)) == len(enemy_hashes)
    assert len(set(boss_hashes)) == len(boss_hashes)


def test_generators_cover_readability_families_without_emissive_materials():
    enemy_generator = (ROOT / 'tools/generate_models.py').read_text()
    boss_generator = (ROOT / 'tools/generate_models.py').read_text()
    for token in ['crawler','eye','ritualist','shade','chain','beast','winged','construct','chorus','serpent','fire','walker']:
        assert token in enemy_generator
    for token in ['orbital_eye','horned_flame','stone_colossus','living_seal','mask_swarm','split_daemon','sevenfold_throne']:
        assert token in boss_generator
    assert 'emissiveFactor' not in enemy_generator
