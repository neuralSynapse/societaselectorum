import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from sentinel import default_state, apply_gate_results, advance_if_green, REQUIRED_GATES

def green(): return {g:"GREEN" for g in REQUIRED_GATES}

def test_queue_starts_3d_then_roguelite_then_survivor():
    s=default_state(); assert s["activeGame"]=="chronica-3d"; assert s["queue"]==["chronica-3d","harun-roguelite","harun-survivor"]

def test_red_does_not_advance():
    s=default_state(); gates=green(); gates["COMBAT_GREEN"]="RED"; apply_gate_results(s,"chronica-3d",gates)
    assert advance_if_green(s) is False; assert s["activeGame"]=="chronica-3d"; assert s["status"]=="RED"

def test_blocked_does_not_advance():
    s=default_state(); s["status"]="BLOCKED"; assert advance_if_green(s) is False; assert s["activeGame"]=="chronica-3d"

def test_complete_green_advances_and_wraps_cycle():
    s=default_state()
    for expected_next in ["harun-roguelite","harun-survivor","chronica-3d"]:
        game=s["activeGame"]; apply_gate_results(s,game,green()); assert advance_if_green(s) is True; assert s["activeGame"]==expected_next
    assert s["cycle"]==2

def test_missing_gate_is_not_green():
    s=default_state(); gates=green(); gates.pop("UI_GREEN"); apply_gate_results(s,"chronica-3d",gates)
    assert s["status"]=="RED"; assert not advance_if_green(s)
