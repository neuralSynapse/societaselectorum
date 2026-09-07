from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/"data"/"roguelite"

def load(name): return json.loads((DATA/f"{name}.json").read_text(encoding="utf-8"))

def test_exactly_eight_routes(): assert len(load("routes"))==8

def test_authorial_meta_content_is_labeled():
    for key in ("routes","curses","blessings","transformations"):
        assert all(r["provenance"]["level"]=="dramatizacao_electorum" for r in load(key))

def test_minimum_meta_content_counts():
    assert len(load("curses"))>=8
    assert len(load("blessings"))>=6
    assert len(load("transformations"))>=10

def test_gauntlets_are_runtime_data():
    gauntlets=load("gauntlets")
    assert len(gauntlets)>=4
    for g in gauntlets:
        assert g["effect"]["kind"]=="gauntlet"
        assert g["save_state"]["scope"]=="run"

def test_meta_run_director_exposes_required_operations():
    text=(ROOT/"scripts/progression/MetaRunDirector.gd").read_text(encoding="utf-8")
    for signature in ("func select_route(","func apply_curse(","func apply_blessing(","func evaluate_transformations(","func record_completion(","func start_gauntlet("):
        assert signature in text

def test_meta_run_never_exposes_institutional_progression_mutation():
    text=(ROOT/"scripts/progression/MetaRunDirector.gd").read_text(encoding="utf-8").lower()
    assert "real_progress_gate" not in text
    assert "institutional_grade" not in text
    assert "grant_grade" not in text
