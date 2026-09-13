#!/usr/bin/env python3
import json
from datetime import datetime, timezone
from pathlib import Path

def now(): return datetime.now(timezone.utc).isoformat()
def can_repair(data,game): return bool((data or {}).get("games",{}).get(game,{}).get("green"))
def update_green_baseline(data,game,snapshot):
    data.setdefault("schemaVersion",1); record=data.setdefault("games",{}).setdefault(game,{})
    record["green"]={**dict(snapshot or {}),"capturedAt":now()}; return record["green"]
def repair_attempt_allowed(log,game,failure_fingerprint,repair_key):
    for row in reversed(list(log or [])):
        if row.get("gameId")==game and row.get("failureFingerprint")==failure_fingerprint and row.get("repairKey")==repair_key and row.get("result") in {"failed","regressed"}: return False
    return True
def append_repair(path,item):
    row={"at":now(),**dict(item)}; Path(path).parent.mkdir(parents=True,exist_ok=True)
    with Path(path).open("a",encoding="utf-8") as f: f.write(json.dumps(row,ensure_ascii=False)+"\n")
    return row
