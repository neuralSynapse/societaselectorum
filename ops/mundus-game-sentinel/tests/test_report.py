import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from report import build_report
from sentinel import REQUIRED_GATES

def test_report_refuses_green_when_gate_missing():
    gates={g:"GREEN" for g in REQUIRED_GATES}; gates.pop("UI_GREEN")
    r=build_report("chronica-3d",gates,[])
    assert r["status"]=="RED"
    assert "UI_GREEN" in r["missingGates"]

def test_report_refuses_unknown_or_red():
    gates={g:"GREEN" for g in REQUIRED_GATES}; gates["COMBAT_GREEN"]="UNKNOWN"
    assert build_report("chronica-3d",gates,[])["status"]=="RED"
    gates["COMBAT_GREEN"]="RED"
    assert build_report("chronica-3d",gates,[])["status"]=="RED"

def test_report_green_only_when_all_required_gates_are_green():
    gates={g:"GREEN" for g in REQUIRED_GATES}
    r=build_report("harun-survivor",gates,[{"kind":"screenshot","path":"x.png"}])
    assert r["status"]=="GREEN"
    assert r["missingGates"]==[]
