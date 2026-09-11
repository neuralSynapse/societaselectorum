from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def test_project_boot_autoload_input_and_camera_contract() -> None:
    project = _read("project.godot")
    assert 'run/main_scene="res://scenes/boot/Main.tscn"' in project

    for autoload in (
        "GameState",
        "SaveService",
        "ContentRegistry",
        "RogueliteContentService",
        "AudioDirector",
    ):
        assert f'{autoload}="*res://autoload/{autoload}.gd"' in project

    for action in (
        "move_left",
        "move_right",
        "move_forward",
        "move_back",
        "jump",
        "interact",
        "primary_attack",
        "power",
        "instrument",
        "consume",
        "sprint",
        "rupture_charge",
        "pause",
        "camera_toggle",
        "kinesis_1",
        "kinesis_2",
        "kinesis_3",
    ):
        assert f"{action}=" in project

    camera = json.loads(_read("data/settings/camera_modes.json"))
    assert camera["default"] == "first_person"
    assert camera["modes"]["first_person"]["distance"] == 0.0
    assert camera["rules"]["enemies_never_parented_to_camera"] is True


def test_roster_keeps_harun_caim_lilith_contract() -> None:
    roster = json.loads(_read("data/characters/playable_roster.json"))
    by_id = {row["id"]: row for row in roster}

    assert {"harun", "caim", "lilith"} <= set(by_id)
    assert by_id["harun"]["unlock"]["kind"] == "default"
    assert by_id["caim"]["unlock"] == {"kind": "stage_mark", "id": "a_balanca"}
    assert by_id["lilith"]["unlock"] == {"kind": "stage_mark", "id": "a_eleicao"}


def test_save_schema_version_is_consistent_and_load_is_strict() -> None:
    save_service = _read("autoload/SaveService.gd")
    release_manifest = json.loads(_read("distribution/release_manifest.json"))

    match = re.search(r"const CAMPAIGN_VERSION := (\d+)", save_service)
    assert match is not None
    assert int(match.group(1)) == release_manifest["save_schema_version"]

    assert 'int(data.get("campaign_version", -1)) != CAMPAIGN_VERSION' in save_service
    assert 'user://chronica_harun_campaign.json' in save_service


def test_boot_falls_back_from_absent_corrupt_or_incompatible_campaign() -> None:
    boot = _read("scripts/boot/Main.gd")
    assert "var snapshot := SaveService.load_campaign()" in boot
    assert "if snapshot.is_empty():" in boot
    assert "GameState.start_new_campaign()" in boot
    assert "GameState.load_save_data(snapshot)" in boot


def test_loaded_campaign_reconciles_stage_index_and_journey_state() -> None:
    game_state = _read("autoload/GameState.gd")
    assert "func _reconcile_loaded_journey() -> void:" in game_state
    load_body = game_state.split("func load_save_data(snapshot: Dictionary) -> void:", 1)[1].split("func snapshot_run()", 1)[0]
    assert "_reconcile_loaded_journey()" in load_body
    assert "if journey_state == PEREGRINUS_IGNIS_GAME:" in game_state
    assert "journey_state = JOURNEY_DEGREE" in game_state
    assert 'current_stage_id = StringName(row.get("id", "grade_01_peregrinus_ignis"))' in game_state


def test_student_journey_chain_and_narrative_final_state_are_consistent() -> None:
    journey = json.loads(_read("data/stages/student_journey.json"))
    assert len(journey) == 16
    assert [row["index"] for row in journey] == list(range(16))
    for index, row in enumerate(journey[:-1]):
        assert row["next_stage"] == journey[index + 1]["id"]
    assert journey[-1]["id"] == "initiation_chamber"
    assert journey[-1]["next_stage"] == "PEREGRINUS_IGNIS_GAME"


def test_retry_reload_saves_without_advancing_campaign() -> None:
    stage_director = _read("scripts/progression/StageDirector.gd")
    retry_body = stage_director.split("func retry_current_stage() -> void:", 1)[1].split("\nfunc ", 1)[0]
    assert "SaveService.save_campaign(GameState.to_save_data())" in retry_body
    assert "get_tree().reload_current_scene()" in retry_body
    assert "complete_stage" not in retry_body
    assert "stage_index" not in retry_body


def test_new_campaign_reset_is_campaign_only_and_preserves_input_settings() -> None:
    game_state = _read("autoload/GameState.gd")
    body = game_state.split("func start_new_campaign(seed: int = 0) -> void:", 1)[1].split("\nfunc ", 1)[0]
    for expected in (
        'selected_character_id = &"harun"',
        'current_stage_id = &"o_olho"',
        "stage_index = 0",
        "cycle = 0",
        "journey_state = JOURNEY_PORTAL_0",
        "completion_marks.clear()",
        "completion_marks_by_character.clear()",
        "run_build.clear()",
        "meta_progression.clear()",
        "_reset_run_stats()",
    ):
        assert expected in body
    assert "InputMap" not in body
    assert "ProjectSettings" not in body
    assert "camera" not in body.lower()


def test_no_institutional_progression_or_required_backend_dependency_in_runtime() -> None:
    runtime_files = list((ROOT / "autoload").glob("*.gd")) + list((ROOT / "scripts").rglob("*.gd"))
    forbidden = (
        "real_progress_gate",
        "database_url",
        "service_role",
        "supabase_service",
        "neon_database_url",
    )
    for path in runtime_files:
        source = path.read_text(encoding="utf-8").lower()
        for token in forbidden:
            assert token not in source, f"{token} leaked into {path.relative_to(ROOT)}"

    boot_and_autoloads = [_read("scripts/boot/Main.gd")]
    boot_and_autoloads.extend(path.read_text(encoding="utf-8") for path in (ROOT / "autoload").glob("*.gd"))
    joined = "\n".join(boot_and_autoloads).lower()
    assert "httprequest" not in joined
    assert "https://" not in joined
    assert "http://" not in joined


def test_no_privileged_secret_material_is_embedded_in_runtime_distribution() -> None:
    forbidden = (
        re.compile(r"postgres(?:ql)?://", re.I),
        re.compile(r"DATABASE_URL\s*=", re.I),
        re.compile(r"NEON_DATABASE_URL\s*=", re.I),
        re.compile(r"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY"),
        re.compile(r"service[_-]?role\s*[:=]\s*['\"][A-Za-z0-9._-]{12,}", re.I),
        re.compile(r"sk-[A-Za-z0-9]{20,}"),
    )
    offenders: list[str] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".gd", ".json", ".godot", ".tscn", ".cfg"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if any(pattern.search(text) for pattern in forbidden):
            offenders.append(path.relative_to(ROOT).as_posix())
    assert not offenders, "\n".join(offenders)


def test_static_scene_and_preload_resource_references_resolve() -> None:
    candidates = list((ROOT / "scenes").rglob("*.tscn")) + list((ROOT / "autoload").glob("*.gd")) + list(
        (ROOT / "scripts").rglob("*.gd")
    )
    patterns = (
        re.compile(r'path="(res://[^"]+)"'),
        re.compile(r'preload\("(res://[^"]+)"\)'),
    )
    missing: list[str] = []
    for path in candidates:
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in patterns:
            for match in pattern.finditer(text):
                resource = match.group(1)
                relative = resource.removeprefix("res://")
                if not (ROOT / relative).exists():
                    missing.append(f"{path.relative_to(ROOT)} -> {resource}")
    assert not missing, "\n".join(missing)
