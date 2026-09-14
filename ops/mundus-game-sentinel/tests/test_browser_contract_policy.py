import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_browser_smoke_cannot_relax_shared_canon_contract():
    contract = json.loads((ROOT / "canon-contract.json").read_text(encoding="utf-8"))
    smoke = (ROOT / "browser-smoke.spec.mjs").read_text(encoding="utf-8")
    version = contract["contractVersion"]
    stage_count = len(contract["stages"])

    # Five current device-matrix scenarios must all prove the same governing story contract.
    assert smoke.count(f"canonContract:'{version}'") == 5
    assert smoke.count(f"canonicalStages:{stage_count}") == 5
    assert "matches immutable shared canon contract" in smoke

    # Prevent the previously observed false-green policy from returning silently.
    assert "canonContract:'4.0.0'" not in smoke
    assert "if(cfg.canonContract!==undefined)" not in smoke
    assert "if(cfg.canonicalStages!==undefined)" not in smoke
    assert "expect(canon?.canonContract" in smoke
    assert "expect(canon?.canonicalStages" in smoke
