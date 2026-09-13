#!/usr/bin/env python3
import json, hashlib
from datetime import datetime, timezone
from pathlib import Path
from sentinel import REQUIRED_GATES

def _now(): return datetime.now(timezone.utc).isoformat()
def _fingerprint(game,gates):
    bad=sorted((g,gates.get(g,"MISSING")) for g in REQUIRED_GATES if gates.get(g)!="GREEN")
    return hashlib.sha256(json.dumps([game,bad],sort_keys=True).encode()).hexdigest()[:16] if bad else None

def build_report(game,gates,evidence,notes=None):
    normalized={g:gates.get(g,"MISSING") for g in REQUIRED_GATES}
    missing=[g for g in REQUIRED_GATES if g not in gates]
    failing=[g for g in REQUIRED_GATES if normalized[g]!="GREEN"]
    return {"schemaVersion":1,"generatedAt":_now(),"gameId":game,"status":"GREEN" if not failing else "RED","gates":normalized,"missingGates":missing,"failingGates":failing,"failureFingerprint":_fingerprint(game,normalized),"evidence":list(evidence or []),"notes":list(notes or [])}

def to_markdown(report):
    lines=[f"# MUNDUS Game Sentinel · {report['gameId']}","",f"Status: **{report['status']}**",f"Gerado: {report['generatedAt']}",""]
    lines.append("## Gates")
    lines += [f"- {g}: {v}" for g,v in report["gates"].items()]
    if report["evidence"]:
        lines += ["","## Evidências"]+[f"- {e.get('kind','evidence')}: {e.get('path') or e.get('detail') or e}" for e in report["evidence"]]
    if report["notes"]: lines += ["","## Notas"]+[f"- {n}" for n in report["notes"]]
    return "\n".join(lines)+"\n"

def write_report(report,out_dir):
    out=Path(out_dir); out.mkdir(parents=True,exist_ok=True); (out/"latest-report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8"); (out/"latest-report.md").write_text(to_markdown(report),encoding="utf-8")

if __name__=="__main__":
    import argparse
    p=argparse.ArgumentParser(); p.add_argument("game"); p.add_argument("gates_json"); p.add_argument("--out",default=str(Path(__file__).resolve().parent/"artifacts")); a=p.parse_args(); gates=json.loads(Path(a.gates_json).read_text(encoding="utf-8")); r=build_report(a.game,gates,[]); write_report(r,a.out); print(json.dumps(r,ensure_ascii=False,indent=2)); raise SystemExit(0 if r["status"]=="GREEN" else 1)
