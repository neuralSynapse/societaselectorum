#!/usr/bin/env python3
import argparse,json,hashlib
from pathlib import Path
from datetime import datetime,timezone

GAMES=["chronica-3d","harun-roguelite","harun-survivor"]
REQUIRED_GATES=["CANON_GREEN","RUNTIME_GREEN","ASSET_GREEN","INPUT_GREEN","COMBAT_GREEN","PROGRESSION_GREEN","UI_GREEN","PLATFORM_GREEN","REGRESSION_GREEN"]
LEVEL3_GATES=["PERFORMANCE_GREEN","ASYNC_RUNTIME_GREEN","DEVICE_MATRIX_GREEN","SECURITY_GREEN"]

def now(): return datetime.now(timezone.utc).isoformat()
def default_game(): return {"status":"QUEUED","gates":{g:"UNKNOWN" for g in REQUIRED_GATES},"lastGreenAt":None,"failureFingerprint":None,"repairAttempts":0,"lastRepair":None}
def default_state(): return {"schemaVersion":1,"cycle":1,"activeGame":GAMES[0],"queue":GAMES[:],"status":"QUEUED","lastRunAt":None,"lastGreenAt":None,"canonContractVersion":"1.0.0","baseline":{},"games":{g:default_game() for g in GAMES},"failureFingerprint":None,"repairAttempts":0,"lastRepair":None,"nextGame":GAMES[1],"notes":[]}
def fingerprint(game,gates):
    failed=sorted((k,v) for k,v in gates.items() if v!="GREEN")
    return hashlib.sha256(json.dumps([game,failed],sort_keys=True).encode()).hexdigest()[:16] if failed else None
def normalize_gates(gates): return {g:gates.get(g,"UNKNOWN") for g in REQUIRED_GATES}
def all_green(gates):
    gates=normalize_gates(gates); return all(gates[g]=="GREEN" for g in REQUIRED_GATES)
def level3_all_green(state,game):
    if int(state.get("sentinelLevel",1))<3: return True
    gates=state.get("games",{}).get(game,{}).get("level3Gates",{})
    return all(gates.get(g,"UNKNOWN")=="GREEN" for g in LEVEL3_GATES)
def apply_gate_results(state,game,gates):
    if game!=state["activeGame"]: raise ValueError(f"Only active game may be updated: {state['activeGame']}")
    normalized=normalize_gates(gates); record=state["games"][game]; record["gates"]=normalized; state["lastRunAt"]=now(); fp=fingerprint(game,normalized); record["failureFingerprint"]=fp; state["failureFingerprint"]=fp
    if all_green(normalized) and level3_all_green(state,game):
        record["status"]="GREEN"; state["status"]="GREEN"; record["lastGreenAt"]=state["lastRunAt"]; state["lastGreenAt"]=state["lastRunAt"]
    elif all_green(normalized):
        record["status"]="VERIFYING"; state["status"]="VERIFYING"
    else: record["status"]="RED"; state["status"]="RED"
    return state["status"]
def advance_if_green(state):
    game=state["activeGame"]
    if state.get("status")!="GREEN" or not all_green(state["games"][game]["gates"]) or not level3_all_green(state,game): return False
    idx=GAMES.index(game); next_idx=(idx+1)%len(GAMES)
    if next_idx==0: state["cycle"]=int(state.get("cycle",1))+1
    state["activeGame"]=GAMES[next_idx]; state["nextGame"]=GAMES[(next_idx+1)%len(GAMES)]; state["status"]="QUEUED"; state["failureFingerprint"]=None
    target=state["games"][state["activeGame"]]
    if target["status"]!="BLOCKED": target["status"]="QUEUED"
    return True
def mark_blocked(state,note):
    game=state["activeGame"]; state["status"]="BLOCKED"; state["games"][game]["status"]="BLOCKED"; state["notes"].append({"at":now(),"game":game,"note":note}); return state
def record_repair(state,summary):
    game=state["activeGame"]; state["repairAttempts"]=int(state.get("repairAttempts",0))+1; state["games"][game]["repairAttempts"]=int(state["games"][game].get("repairAttempts",0))+1; item={"at":now(),"game":game,"summary":summary,"fingerprint":state.get("failureFingerprint")}; state["lastRepair"]=item; state["games"][game]["lastRepair"]=item; return item
def load_state(path):
    path=Path(path); return json.loads(path.read_text(encoding="utf-8")) if path.exists() else default_state()
def save_state(path,state): Path(path).write_text(json.dumps(state,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
def validate_state(state):
    errors=[]
    if state.get("activeGame") not in GAMES: errors.append("unknown activeGame")
    if state.get("queue")!=GAMES: errors.append("queue drift")
    for g in GAMES:
        if g not in state.get("games",{}): errors.append(f"missing game {g}")
        else:
            missing=[x for x in REQUIRED_GATES if x not in state["games"][g].get("gates",{})]
            if missing: errors.append(f"{g} missing gates {missing}")
            if int(state.get("sentinelLevel",1))>=3:
                missing_l3=[x for x in LEVEL3_GATES if x not in state["games"][g].get("level3Gates",{})]
                if missing_l3: errors.append(f"{g} missing L3 gates {missing_l3}")
    return errors
def main():
    root=Path(__file__).resolve().parent; p=argparse.ArgumentParser(); p.add_argument("command",choices=["check","advance","show"]); p.add_argument("--state",default=str(root/"state.json")); a=p.parse_args(); s=load_state(a.state)
    if a.command=="check":
        errs=validate_state(s); print(json.dumps({"ok":not errs,"activeGame":s.get("activeGame"),"status":s.get("status"),"errors":errs},ensure_ascii=False,indent=2)); return 0 if not errs else 1
    if a.command=="advance":
        changed=advance_if_green(s); save_state(a.state,s); print(json.dumps({"advanced":changed,"activeGame":s["activeGame"],"cycle":s["cycle"]},ensure_ascii=False)); return 0
    print(json.dumps(s,ensure_ascii=False,indent=2)); return 0
if __name__=="__main__": raise SystemExit(main())
