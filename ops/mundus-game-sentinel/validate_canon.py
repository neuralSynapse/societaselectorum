#!/usr/bin/env python3
import json
from pathlib import Path

ADAPTERS=["adapters/chronica-3d.json","adapters/harun-roguelite.json","adapters/harun-survivor.json"]

def _load(path): return json.loads(Path(path).read_text(encoding="utf-8"))
def _err(game_id,code,message): return {"gameId":game_id,"gate":"CANON_GREEN","code":code,"message":message}

def validate_contract(contract):
    errors=[]; ids=[x.get("id") for x in contract.get("stages",[])]; rules=contract.get("rules",{})
    if len(ids)!=16 or len(set(ids))!=16: errors.append(_err("shared","CONTRACT_STAGE_COUNT","Contract must contain 16 unique canonical stages"))
    if rules.get("institutionalWrite") is not False or rules.get("realProgressGateWrite") is not False: errors.append(_err("shared","INSTITUTIONAL_WRITE_FORBIDDEN","Shared canon cannot grant institutional progress"))
    if rules.get("storyResultState")!="PEREGRINUS_IGNIS_GAME": errors.append(_err("shared","STORY_RESULT_DRIFT","Final story state must remain PEREGRINUS_IGNIS_GAME"))
    if rules.get("aleppoAbsoluteChronology")!="open": errors.append(_err("shared","ALEPPO_CHRONOLOGY_DRIFT","Aleppo absolute chronology must remain open"))
    return errors

def validate_adapter(contract,adapter):
    game=adapter.get("gameId","unknown"); errors=[]; canonical=[x["id"] for x in contract.get("stages",[])]; seen=[sid for u in adapter.get("units",[]) for sid in u.get("canonStageIds",[])]
    if seen!=canonical: errors.append(_err(game,"CANON_ORDER_DRIFT",f"Adapter stage order/coverage differs: {seen}"))
    if len(seen)!=len(set(seen)): errors.append(_err(game,"CANON_DUPLICATE_STAGE","Adapter repeats canonical stages"))
    if adapter.get("institutionalWrite") is not False: errors.append(_err(game,"INSTITUTIONAL_WRITE_FORBIDDEN","Adapter cannot write institutional progress"))
    overrides=adapter.get("canonOverrides") or {}
    if overrides: errors.append(_err(game,"CANON_OVERRIDE_FORBIDDEN",f"Adapters cannot override canon: {sorted(overrides)}"))
    allowed=set(contract.get("provenance",[]))
    for unit in adapter.get("units",[]):
        p=unit.get("provenance")
        if p is not None and p not in allowed: errors.append(_err(game,"UNKNOWN_PROVENANCE",f"Unknown provenance {p!r} in {unit.get('id')}"))
        if unit.get("institutionalWrite") not in (None,False): errors.append(_err(game,"INSTITUTIONAL_WRITE_FORBIDDEN",f"Unit {unit.get('id')} writes institutional progress"))
    return errors

def validate_all(root=None):
    root=Path(root or Path(__file__).resolve().parent); contract=_load(root/"canon-contract.json"); errors=validate_contract(contract)
    for rel in ADAPTERS: errors.extend(validate_adapter(contract,_load(root/rel)))
    return errors

def main():
    errors=validate_all(); print(json.dumps({"ok":not errors,"gate":"CANON_GREEN","errors":errors},ensure_ascii=False,indent=2)); return 0 if not errors else 1

if __name__=="__main__": raise SystemExit(main())
