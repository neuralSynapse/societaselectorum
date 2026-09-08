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
    assert "current_stage_id = StringName(PEREGRINUS_IGNIS_GAME)" in game_state


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
        source = path.read_text(encoding="utf-8")
        for pattern in patterns:
            for resource in pattern.findall(source):
                relative = resource.removeprefix("res://")
                if not (ROOT / relative).exists():
                    missing.append(f"{path.relative_to(ROOT)} -> {resource}")

    assert not missing, "\n".join(missing)
