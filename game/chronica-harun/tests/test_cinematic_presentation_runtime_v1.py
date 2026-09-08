from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
STORY = json.loads((ROOT / "data/narrative/chronica_story_bible.json").read_text(encoding="utf-8"))


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_prologue_order_and_duration_contract_remain_canonized():
    prologue = STORY["prologue"]
    assert len(prologue) == 13
    assert [scene["order"] for scene in prologue] == list(range(13))
    assert sum(scene["duration_seconds"] for scene in prologue) == 500
    assert [scene["id"] for scene in prologue][-3:] == [
        "lineage_of_mark",
        "dismembered_book",
        "see_govern_make",
    ]


def test_main_boot_instances_and_starts_narrative_runtime_before_gameplay_handoff():
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


def test_runtime_has_dedicated_cinematic_stage_and_camera_director():
    scene = read("scenes/narrative/NarrativeRuntime.tscn")
    director = read("scripts/narrative/CinematicPresentationDirector.gd")
    assert "CinematicPresentationDirector.gd" in scene
    for node in ["CinematicStage", "CameraRig", "CinematicCamera", "ProxyRoot", "KeyLight", "FillLight"]:
        assert f'name="{node}"' in scene
    for token in [
        "class_name CinematicPresentationDirector",
        "func stage_shot",
        "func begin_transition",
        "signal proxy_asset_used",
        "signal handoff_ready",
        "proxy_runtime",
    ]:
        assert token in director


def test_presentation_supports_blackout_sparse_silence_reveals_and_fragments():
    scene = read("scenes/narrative/NarrativePresentation.tscn")
    script = read("scripts/narrative/NarrativePresentationController.gd")
    for node in ["Blackout", "CinematicVeil", "RevealLabel", "FragmentStatus", "EvidenceLabel"]:
        assert f'name="{node}"' in scene
    for fn in [
        "begin_transition",
        "show_fragment_progress",
        "show_title_reveal",
        "show_command_reveal",
        "enter_final_black",
        "release_to_gameplay",
        "present_shot_mode",
    ]:
        assert f"func {fn}" in script
    assert 'subtitle_mode == "silence"' in script


def test_bridge_exposes_cinematic_lifecycle_fragment_commands_handoff_and_final_black():
    bridge = read("scripts/narrative/NarrativeRuntimeBridge.gd")
    for signal_name in [
        "cinematic_sequence_started",
        "cinematic_sequence_finished",
        "fragment_progress",
        "grimorium_title_reveal",
        "command_reveal",
        "gameplay_handoff_requested",
        "final_black_requested",
    ]:
        assert f"signal {signal_name}" in bridge
    assert "cinematic_shots.sequence_started.connect" in bridge
    assert "cinematic_shots.sequence_finished.connect" in bridge


def test_grimorium_requires_five_fragments_then_exact_command_order():
    final_scene = STORY["prologue"][-1]
    grimoire = final_scene["grimoire"]
    assert grimoire["reveal_requires_all"] is True
    assert grimoire["fragment_ids"] == [
        "marginal_leaf",
        "burned_notebook",
        "cipher_plate",
        "merchant_letter",
        "broken_map",
    ]
    assert final_scene["commands"] == ["VER", "GOVERNAR", "FAZER"]
    origin = read("scripts/narrative/HarunOriginDirector.gd")
    assert "can_reveal_title()" in origin
    assert 'GRIMORIUM_TITLE := "GRIMORIUM ASCENSIONIS"' in origin


def test_skip_first_run_lock_and_unlock_persistence_remain_present():
    director = read("scripts/narrative/CosmogonyPrologueDirector.gd")
    bridge = read("scripts/narrative/NarrativeRuntimeBridge.gd")
    assert "if not skip_unlocked" in director
    assert 'story_state["skip_unlocked"] = true' in director
    assert 'completion_persist_requested.emit(&"skip_unlocked", true)' in director
    assert "SaveService.save_campaign(GameState.to_save_data())" in bridge


def test_codex_unlocks_stay_bound_to_scene_stage_and_epilogue_runtime_events():
    bridge = read("scripts/narrative/NarrativeRuntimeBridge.gd")
    assert 'story_codex.unlock_by_key("scene:" + String(scene_id))' in bridge
    assert 'story_codex.unlock_by_key("stage:" + String(stage_id))' in bridge
    assert 'story_codex.unlock_by_key("epilogue:" + String(epilogue.get("id", "aleppo_1585")))' in bridge
    for forbidden in ["institutional_grade", "certified_grade", "real_progress_gate"]:
        assert forbidden not in bridge.lower()


def test_epilogue_requires_lucifer_then_final_black_before_continuity_handoff():
    epilogue = STORY["epilogue"]
    assert epilogue["location"] == "Aleppo"
    assert epilogue["date_display"] == "c. 1585"
    assert epilogue["final_word"] == "LUCIFER"
    assert epilogue["cut_to_black_after_final_word"] is True
    assert "second_shadow" in STORY["recurring_motifs"]
    bridge = read("scripts/narrative/NarrativeRuntimeBridge.gd")
    presentation = read("scripts/narrative/NarrativePresentationController.gd")
    assert "final_black_requested.emit" in bridge
    assert "enter_final_black" in presentation


def test_manifest_labels_proxy_vs_final_assets_explicitly():
    manifest = json.loads((ROOT / "data/narrative/cinematic_asset_manifest.json").read_text(encoding="utf-8"))
    assert len(manifest) == 72
    allowed = {"proxy_runtime", "final", "missing"}
    for row in manifest:
        assert row["asset_status"] in allowed
        assert "final_asset_paths" in row
        if row["asset_status"] == "final":
            assert row["final_asset_paths"], row["shot_id"]


def test_ci_gate_fails_explicitly_on_godot_script_errors():
    workflow = (REPO_ROOT / ".github/workflows/chronica-cinematics-v1.yml").read_text(encoding="utf-8")
    assert "if grep -E 'SCRIPT ERROR:|Parse Error:|Failed to load script" in workflow
    assert "then exit 1; fi" in workflow
    assert "! grep -E 'SCRIPT ERROR:" not in workflow
