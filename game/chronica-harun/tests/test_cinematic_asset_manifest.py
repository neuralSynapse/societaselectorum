from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]


def test_cinematic_asset_manifest_covers_every_prologue_shot():
    story=json.loads((ROOT/'data/narrative/chronica_story_bible.json').read_text())
    manifest=json.loads((ROOT/'data/narrative/cinematic_asset_manifest.json').read_text())
    expected=[shot['id'] for scene in story['prologue'] for shot in scene['shots']] + [shot['id'] for shot in story['epilogue']['shots']]
    assert len(expected)==72
    assert [row['shot_id'] for row in manifest]==expected
    for row in manifest:
        assert row['scene_id']
        assert row['camera_contract']
        assert row['visual_contract']
        assert row['audio_contract']
        assert row['transition']
        assert row['priority'] in ['A','B','C']
        assert row['runtime_owner']=='narrative'


def test_integration_guide_names_stable_cross_front_hooks():
    text=(ROOT/'docs/canon/NARRATIVE_INTEGRATION_GUIDE_2026-09-07.md').read_text()
    for token in ['NarrativeRuntime.tscn','narrative_consequence_requested','cinematic_visual','cinematic_audio','PEREGRINUS_IGNIS_GAME','não editar','65 planos','16 decisões']:
        assert token in text
