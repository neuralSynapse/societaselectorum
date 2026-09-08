from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _json(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_release_camera_contract_matches_runtime_modes() -> None:
    camera = _json("data/settings/camera_modes.json")
    release = _json("distribution/release_manifest.json")
    contract = release["runtime_contract"]

    runtime_modes = set(camera["modes"])
    assert camera["default"] == "first_person"
    assert "over_shoulder" in runtime_modes
    assert camera["rules"]["switch_allowed_during_gameplay"] is True

    assert contract["first_person_only"] is False
    assert contract["default_camera"] == camera["default"]
    assert set(contract["camera_modes"]) == runtime_modes
