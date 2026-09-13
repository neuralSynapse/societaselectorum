import json
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from validate_canon import validate_adapter, validate_all

def load(name):
    return json.loads((ROOT/name).read_text(encoding="utf-8"))

def test_validate_all_is_clean():
    assert validate_all(ROOT) == []

def test_validator_rejects_reordered_stage():
    c=load("canon-contract.json"); a=load("adapters/chronica-3d.json")
    a["units"][0]["canonStageIds"], a["units"][1]["canonStageIds"] = a["units"][1]["canonStageIds"], a["units"][0]["canonStageIds"]
    assert any(e["code"]=="CANON_ORDER_DRIFT" for e in validate_adapter(c,a))

def test_validator_rejects_institutional_write():
    c=load("canon-contract.json"); a=load("adapters/harun-roguelite.json"); a["institutionalWrite"]=True
    assert any(e["code"]=="INSTITUTIONAL_WRITE_FORBIDDEN" for e in validate_adapter(c,a))

def test_validator_rejects_closed_aleppo_chronology_override():
    c=load("canon-contract.json"); a=load("adapters/harun-survivor.json"); a["canonOverrides"]={"aleppoAbsoluteChronology":"1585"}
    assert any(e["code"]=="CANON_OVERRIDE_FORBIDDEN" for e in validate_adapter(c,a))

def test_validator_rejects_unknown_provenance():
    c=load("canon-contract.json"); a=load("adapters/harun-survivor.json"); a["units"][0]["provenance"]="ancient_secret"
    assert any(e["code"]=="UNKNOWN_PROVENANCE" for e in validate_adapter(c,a))
