from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def test_export_presets_have_windows_and_linux_desktop_targets():
    text = (ROOT / 'export_presets.cfg').read_text()
    assert 'Windows Desktop' in text
    assert 'Linux/X11' in text
    assert 'CHRONICA_HARUN.exe' in text
    assert 'CHRONICA_HARUN.x86_64' in text


def test_release_manifest_declares_quality_save_and_backend_contracts():
    row = json.loads((ROOT / 'distribution/release_manifest.json').read_text())
    assert set(row['quality_presets']) == {'1080p','1440p','4k'}
    assert row['save_schema_version'] >= 2
    assert row['backend']['health_url'].startswith('https://')
    assert row['backend']['no_embedded_secrets'] is True
    assert row['launcher']['public_game_url'].endswith('/mundus/chronica-harun.html')
