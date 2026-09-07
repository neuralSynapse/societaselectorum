import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _all_gdscript_text() -> str:
    return "\n".join(path.read_text(encoding="utf-8") for path in ROOT.rglob("*.gd"))


def test_no_dictionary_get_or_add_dependency():
    offenders = []
    for path in ROOT.rglob("*.gd"):
        text = path.read_text(encoding="utf-8")
        if ".get_or_add(" in text:
            offenders.append(str(path.relative_to(ROOT)))
    assert offenders == [], f"unsupported Dictionary.get_or_add usage: {offenders}"


def test_smoke_scene_and_script_exist():
    assert (ROOT / "scripts/boot/DepthRuntimeSmoke.gd").is_file()
    assert (ROOT / "scenes/boot/DepthRuntimeSmoke.tscn").is_file()


def test_local_save_roundtrip_api_is_present():
    text = (ROOT / "autoload/GameState.gd").read_text(encoding="utf-8")
    assert "func save_run(" in text
    assert "func load_run(" in text
    assert "FileAccess.open(" in text
    assert "JSON.stringify(" in text
    assert "JSON.parse_string(" in text


def test_project_autoload_paths_resolve():
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    autoload_paths = re.findall(r'=\"\*res://([^\"]+)\"', project)
    assert autoload_paths, "project.godot must declare autoloads"
    missing = [path for path in autoload_paths if not (ROOT / path).is_file()]
    assert missing == [], f"missing autoload resources: {missing}"


def test_no_institutional_write_surface():
    text = _all_gdscript_text()
    forbidden = (
        "real_progress_gate =",
        "set_real_progress",
        "grant_institutional_grade",
        "grant_grade(",
        "institutional_grade =",
    )
    assert not any(token in text for token in forbidden)


def test_all_runtime_catalogs_are_json_serializable_with_unique_ids():
    data_dir = ROOT / "data/roguelite"
    seen = set()
    for path in sorted(data_dir.glob("*.json")):
        records = json.loads(path.read_text(encoding="utf-8"))
        assert isinstance(records, list), path.name
        json.dumps(records, ensure_ascii=False)
        for record in records:
            content_id = record["id"]
            assert content_id not in seen, f"duplicate id {content_id} in {path.name}"
            seen.add(content_id)
    assert seen, "no runtime content records found"


def test_smoke_runtime_exercises_all_front_c_subsystems():
    smoke = (ROOT / "scripts/boot/DepthRuntimeSmoke.gd").read_text(encoding="utf-8")
    required_tokens = (
        "BuildResolver",
        "SpecialRoomDirector",
        "SpecialRoomRuntime",
        "MetaRunDirector",
        "save_run",
        "load_run",
        "open_secret",
        "enter_room",
        "evaluate_transformations",
    )
    missing = [token for token in required_tokens if token not in smoke]
    assert missing == [], f"smoke runtime missing integrations: {missing}"
