#!/usr/bin/env python3
import argparse,json,urllib.request,urllib.error
from pathlib import Path
BASE="https://project27912.websitepublisher.ai"
GAME_CONFIG={
 "chronica-3d":{"route":"/chronica-harun-3d.html","criticalAssets":["chronica-canon.js","chronica-parity.js","chronica-v2.js"]},
 "harun-roguelite":{"route":"/harun-roguelite.html","criticalAssets":["harun-roguelite.js"]},
 "harun-survivor":{"route":"/harun-survivor.html","criticalAssets":["harun-survivor-data-v3.js","harun-survivor-art-v3.js","harun-survivor-engine-v3.js","harun-survivor-v3.css"]}}

def evaluate_page(game,status,html,failed_requests):
    cfg=GAME_CONFIG[game]; errors=[]; runtime="GREEN" if status==200 and "<html" in html.lower() else "RED"; missing=[a for a in cfg["criticalAssets"] if a not in html]; failed=[x for x in failed_requests if any(a in x for a in cfg["criticalAssets"])]; asset="GREEN" if not missing and not failed else "RED"
    if runtime=="RED": errors.append(f"HTTP/HTML invalid: {status}")
    if missing: errors.append("Missing critical asset refs: "+", ".join(missing))
    if failed: errors.append("Failed critical requests: "+", ".join(failed))
    return {"gameId":game,"url":BASE+cfg["route"],"status":status,"gates":{"RUNTIME_GREEN":runtime,"ASSET_GREEN":asset},"errors":errors}
def fetch(game,timeout=25):
    url=BASE+GAME_CONFIG[game]["route"]; req=urllib.request.Request(url,headers={"User-Agent":"MUNDUS-Game-Sentinel/1.0"})
    try:
        with urllib.request.urlopen(req,timeout=timeout) as r: return evaluate_page(game,getattr(r,"status",200),r.read().decode("utf-8","replace"),[])
    except urllib.error.HTTPError as e: return evaluate_page(game,e.code,"",[])
    except Exception as e:
        out=evaluate_page(game,0,"",[]); out["errors"].append(f"{type(e).__name__}: {e}"); return out
def main():
    p=argparse.ArgumentParser(); p.add_argument("--game",choices=[*GAME_CONFIG,"all"],default="all"); p.add_argument("--out"); a=p.parse_args(); games=list(GAME_CONFIG) if a.game=="all" else [a.game]; results=[fetch(g) for g in games]; payload={"ok":all(all(v=="GREEN" for v in r["gates"].values()) for r in results),"results":results}; text=json.dumps(payload,ensure_ascii=False,indent=2)
    if a.out: Path(a.out).write_text(text+"\n",encoding="utf-8")
    print(text); return 0 if payload["ok"] else 1
if __name__=="__main__": raise SystemExit(main())
