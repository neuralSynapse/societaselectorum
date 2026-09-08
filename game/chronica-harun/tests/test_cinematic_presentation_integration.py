from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
STORY = json.loads((ROOT / "data/narrative/chronica_story_bible.json").read_text(encoding="utf-8"))


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_cinematic_prologue_and_boot_contracts_integrate_without_regressing_save_recovery():
    prologue = STORY["prologue"]
    assert len(prologue) == 13
    assert [scene["order"] for scene in prologue] == list(range(13))
    assert sum(scene["duration_seconds"] for scene in prologue) == 500

    scene = read("scenes/boot/Main.tscn")
    script = read("scripts/boot/Main.gd")
    assert "NarrativeRuntime.tscn" in scene
    assert 'name="NarrativeRuntime"' in scene
    for token in [
        "@onready var narrative_runtime",
        "bind_stage_director(stage_director)",
        "start_entry_flow()",
        "gameplay_handoff_requested",
        "_set_gameplay_enabled",
    ]:
        assert token in script
    assert "var snapshot := SaveService.load_campaign()" in script
    assert "if snapshot.is_empty():" in script
    assert "GameState.load_save_data(snapshot)" in script


def test_cinematic_runtime_has_stage_camera_transitions_reveals_and_handoff():
    runtime_scene = read("scenes/narrative/NarrativeRuntime.tscn")
    presentation_scene = read("scenes/narrative/NarrativePresentation.tscn")
    director = read("scripts/narrative/CinematicPresentationDirector.gd")
    controller = read("scripts/narrative/NarrativePresentationController.gd")
    bridge = read("scripts/narrative/NarrativeRuntimeBridge.gd")

    for node in ["CinematicStage", "CameraRig", "CinematicCamera", "ProxyRoot", "KeyLight", "FillLight"]:
        assert f'name="{node}"' in runtime_scene
    for token in ["class_name CinematicPresentationDirector", "func stage_shot", "func begin_transition", "signal handoff_ready", "proxy_runtime"]:
        assert token in director
    for node in ["Blackout", "CinematicVeil", "RevealLabel", "FragmentStatus", "EvidenceLabel"]:
        assert f'name="{node}"' in presentation_scene
    for fn in ["begin_transition", "show_fragment_progress", "show_title_reveal", "show_command_reveal", "enter_final_black", "release_to_gameplay", "present_shot_mode"]:
        assert f"func {fn}" in controller
    assert 'subtitle_mode == "silence"' in controller
    for signal_name in ["cinematic_sequence_started", "cinematic_sequence_finished", "fragment_progress", "grimorium_title_reveal", "command_reveal", "gameplay_handoff_requested", "final_black_requested"]:
        assert f"signal {signal_name}" in bridge


def test_grimorium_skip_codex_epilogue_and_manifest_contracts_remain_exact():
    final_scene = STORY["prologue"][-1]
    grimoire = final_scene["grimoire"]
    assert grimoire["reveal_requires_all"] is True
    assert grimoire["fragment_ids"] == ["marginal_leaf", "burned_notebook", "cipher_plate", "merchant_letter", "broken_map"]
    assert final_scene["commands"] == ["VER", "GOVERNAR", "FAZER"]

    origin = read("scripts/narrative/HarunOriginDirector.gd")
    assert "can_reveal_title()" in origin
    assert 'GRIMORIUM_TITLE := "GRIMORIUM ASCENSIONIS"' in origin

    prologue_director = read("scripts/narrative/CosmogonyPrologueDirector.gd")
    bridge = read("scripts/narrative/NarrativeRuntimeBridge.gd")
    controller = read("scripts/narrative/NarrativePresentationController.gd")
    assert "if not skip_unlocked" in prologue_director
    assert 'story_state["skip_unlocked"] = true' in prologue_director
    assert "SaveService.save_campaign(GameState.to_save_data())" in bridge
    assert 'story_codex.unlock_by_key("scene:" + String(scene_id))' in bridge
    assert 'story_codex.unlock_by_key("stage:" + String(stage_id))' in bridge

    epilogue = STORY["epilogue"]
    assert epilogue["location"] == "Aleppo"
    assert epilogue["date_display"] == "c. 1585"
    assert epilogue["final_word"] == "LUCIFER"
    assert epilogue["cut_to_black_after_final_word"] is True
    assert "second_shadow" in STORY["recurring_motifs"]
    assert "final_black_requested.emit" in bridge
    assert "enter_final_black" in controller

    manifest = json.loads((ROOT / "data/narrative/cinematic_asset_manifest.json").read_text(encoding="utf-8"))
    assert len(manifest) == 72
    allowed = {"proxy_runtime", "final", "missing"}
    for row in manifest:
        assert row["asset_status"] in allowed
        assert "final_asset_paths" in row
        if row["asset_status"] == "final":
            assert row["final_asset_paths"], row["shot_id"]
