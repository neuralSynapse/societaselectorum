import json
import re
from pathlib import Path

ROOT = Path(__file__).parents[1]


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def load_json(rel):
    return json.loads(read(rel))


def test_project_godot_exists():
    assert (ROOT / "project.godot").is_file()


def test_main_scene_is_boot():
    text = read("project.godot")
    assert 'run/main_scene="res://scenes/boot/Boot.tscn"' in text


def test_required_autoloads_are_registered():
    text = read("project.godot")
    for name in ("GameState", "SaveService", "RogueliteContentService"):
        assert re.search(rf'^{name}="\*res://autoload/{name}\.gd"$', text, re.M), name


def test_first_person_player_contract():
    scene = read("scenes/player/Player.tscn")
    assert 'type="CharacterBody3D"' in scene
    assert 'type="Camera3D" parent="Neck"' in scene
    assert 'current = true' in scene
    controller = read("scripts/player/PlayerController.gd")
    assert "InputEventMouseMotion" in controller
    assert "rotate_y" in controller
    assert "neck.rotate_x" in controller


def test_boot_instantiates_player_scene():
    scene = read("scenes/boot/Boot.tscn")
    assert 'path="res://scenes/player/Player.tscn"' in scene
    assert 'instance=ExtResource("1_player")' in scene


def test_journey_has_15_substages_plus_initiation():
    journey = load_json("data/stages/student_journey.json")
    entries = journey["entries"]
    assert len(entries) == 16
    assert [e["index"] for e in entries] == list(range(16))
    assert sum(e["kind"] == "student_substage" for e in entries) == 15
    assert entries[-1]["kind"] == "initiation_room"


def test_final_game_state_remains_narrative_only():
    contract = load_json("data/game_contract.json")
    assert contract["journey"]["final_narrative_state"] == "PEREGRINUS_IGNIS_GAME"
    assert contract["journey"]["institutional_progression_write"] is False
    game_state = read("autoload/GameState.gd")
    assert 'PEREGRINUS_IGNIS_GAME' in game_state


def test_no_gameplay_script_mentions_real_progress_gate():
    scripts = list(ROOT.rglob("*.gd"))
    assert scripts
    offenders = [p.relative_to(ROOT).as_posix() for p in scripts if "real_progress_gate" in p.read_text(encoding="utf-8")]
    assert offenders == []


def test_save_version_is_consistent():
    contract = load_json("data/game_contract.json")
    save_service = read("autoload/SaveService.gd")
    game_state = read("autoload/GameState.gd")
    expected = contract["save_version"]
    assert f"const SAVE_VERSION := {expected}" in save_service
    assert f"const SAVE_VERSION := {expected}" in game_state


def test_save_is_local_user_path():
    text = read("autoload/SaveService.gd")
    assert 'user://chronica_harun_save_v1.json' in text
    assert "DATABASE_URL" not in text


def test_enemy_catalog_is_valid_and_explicit_about_recovery():
    data = load_json("data/enemies/student_enemies.json")
    assert data["expected_count"] >= 82
    assert data["recovery_status"] == "not_recovered"


def test_boss_catalog_is_valid_and_explicit_about_recovery():
    data = load_json("data/bosses/student_bosses.json")
    assert data["expected_count"] == 16
    assert data["expected_phases_per_boss"] == 3
    assert data["recovery_status"] == "not_recovered"


def test_roguelite_manifest_loads_all_expected_catalog_contracts():
    data = load_json("data/roguelite/catalog_manifest.json")
    expected = {
        "tarot_thoth": 78,
        "sigilla_goetica": 72,
        "pharmaka_hermetica": 21,
        "talismans_decanic": 36,
        "instrumenta": 32,
        "matrix_powers": 15,
        "mutations": 45,
        "daimones": 7,
    }
    assert data["expected_counts"] == expected
    assert data["recovery_status"] == "not_recovered"


def test_contract_preserves_required_counts_and_routes():
    contract = load_json("data/game_contract.json")
    assert contract["mode"] == "first_person_fps_roguelite"
    assert contract["journey"] == {
        "student_substages": 15,
        "initiation_room": True,
        "final_narrative_state": "PEREGRINUS_IGNIS_GAME",
        "institutional_progression_write": False,
    }
    assert contract["bestiary"] == {"enemies": 82, "bosses": 16, "boss_phases": 3}
    assert len(contract["special_rooms"]) == 19
    assert contract["routes"] == 8


def test_required_foundation_runtime_files_exist():
    required = [
        "scripts/progression/StageDirector.gd",
        "scripts/generation/StageFloorBuilder.gd",
        "scripts/content/BuildResolver.gd",
        "scripts/content/PowerMutationRuntime.gd",
        "scripts/content/DaimonRuntime.gd",
        "scripts/rooms/SpecialRoomDirector.gd",
        "scripts/vision/VisionDirector.gd",
        "scripts/meta/MetaRunDirector.gd",
    ]
    for rel in required:
        assert (ROOT / rel).is_file(), rel


def test_tscn_resource_paths_resolve():
    missing = []
    pattern = re.compile(r'path="res://([^"]+)"')
    for scene in ROOT.rglob("*.tscn"):
        for rel in pattern.findall(scene.read_text(encoding="utf-8")):
            if not (ROOT / rel).exists():
                missing.append((scene.relative_to(ROOT).as_posix(), rel))
    assert missing == []


def test_no_embedded_backend_secrets():
    forbidden = [
        re.compile(r"postgres(?:ql)?://", re.I),
        re.compile(r"DATABASE_URL\s*=", re.I),
        re.compile(r"NEON_DATABASE_URL\s*=", re.I),
        re.compile(r"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY"),
        re.compile(r"sk-[A-Za-z0-9]{20,}"),
    ]
    offenders = []
    for p in ROOT.rglob("*"):
        if p.is_file() and p.suffix.lower() in {".gd", ".json", ".godot", ".tscn", ".cfg", ".md"}:
            text = p.read_text(encoding="utf-8", errors="ignore")
            if any(rx.search(text) for rx in forbidden):
                offenders.append(p.relative_to(ROOT).as_posix())
    assert offenders == []


def test_backend_bridge_is_not_required_for_boot():
    project = read("project.godot")
    assert "BackendBridge" not in project
    boot = read("scripts/boot/Boot.gd")
    assert "HTTP" not in boot
    assert "backend" not in boot.lower()


def test_recovered_foundation_does_not_claim_enemy_or_boss_scenes():
    contract = load_json("data/game_contract.json")
    assert contract["recovery"]["enemy_scenes"] == "not_recovered"
    assert contract["recovery"]["boss_scenes"] == "not_recovered"


def test_provenance_contract_is_preserved():
    contract = load_json("data/game_contract.json")
    assert set(contract["provenance_fields"]) == {"fonte", "tradicao", "interpretacao", "dramatizacao_electorum"}
