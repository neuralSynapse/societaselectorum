import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_windows_native_runtime_harness_covers_required_contracts():
    script_path = ROOT / "runtime_qa/windows_native/WindowsNativeQA.gd"
    scene_path = ROOT / "runtime_qa/windows_native/WindowsNativeQA.tscn"
    assert script_path.exists(), "Windows-native Godot QA harness script is missing"
    assert scene_path.exists(), "Windows-native Godot QA harness scene is missing"

    script = script_path.read_text(encoding="utf-8")
    required = [
        'OS.get_name()',
        '"Windows"',
        'application/run/main_scene',
        'res://scenes/boot/Main.tscn',
        'user://chronica_harun_campaign.json',
        'ProjectSettings.globalize_path',
        'start_new_campaign',
        'save_campaign',
        'load_campaign',
        'reload_current_scene',
        'camera_toggle',
        'first_person',
        'over_shoulder',
        'WINDOWS_QA_SAVE_LOAD_PASS',
        'WINDOWS_QA_RETRY_PASS',
        'WINDOWS_QA_INPUT_PASS',
        'WINDOWS_QA_CAMERA_PASS',
        'WINDOWS_QA_RUNTIME_PASS',
    ]
    for token in required:
        assert token in script, f"runtime harness missing token: {token}"

    for action in [
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
    ]:
        assert f'"{action}"' in script, f"runtime harness does not assert input action {action}"


def test_windows_release_probe_validates_pe_launch_resources_zip_hash_and_visual_truthfulness():
    probe_path = ROOT / "tools/windows_release_probe.ps1"
    assert probe_path.exists(), "Windows release probe is missing"
    probe = probe_path.read_text(encoding="utf-8")

    required = [
        "CHRONICA_HARUN.exe",
        "0x8664",
        "0x20b",
        "MZ",
        "PE",
        "FileVersionInfo",
        "EnumResourceNames",
        "RT_GROUP_ICON",
        "Start-Process",
        "Compress-Archive",
        "Expand-Archive",
        "Get-FileHash",
        "SHA256",
        "VISUAL QA NOT VERIFIED",
        "NOT TESTABLE IN CI",
        "release-probe.json",
    ]
    for token in required:
        assert token in probe, f"release probe missing token: {token}"


def test_windows_export_preset_has_release_metadata_without_inventing_icon():
    preset = _text("export_presets.cfg")
    assert 'export_path="build/windows/CHRONICA_HARUN.exe"' in preset
    assert 'application/icon=""' in preset, "QA front must not invent a non-canonical release icon"
    for token in [
        'application/file_version="0.12.0.0"',
        'application/product_version="0.12.0.0"',
        'application/company_name="SOCIETAS ELECTORUM"',
        'application/product_name="CHRONICA HARUN"',
        'application/file_description="CHRONICA HARUN"',
    ]:
        assert token in preset, f"Windows export preset missing release metadata: {token}"


def test_release_manifest_describes_actual_camera_modes():
    manifest = json.loads(_text("distribution/release_manifest.json"))
    runtime = manifest["runtime_contract"]
    assert runtime.get("default_camera_mode") == "first_person"
    assert runtime.get("camera_modes") == ["first_person", "over_shoulder"]
    assert "first_person_only" not in runtime
