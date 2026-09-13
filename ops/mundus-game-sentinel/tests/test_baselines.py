import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from baselines import can_repair, update_green_baseline, repair_attempt_allowed

def test_repair_requires_known_baseline():
    assert can_repair({},"chronica-3d") is False

def test_green_baseline_enables_repair():
    data={}; update_green_baseline(data,"chronica-3d",{"pageVersion":"abc","repoSha":"123"})
    assert can_repair(data,"chronica-3d") is True

def test_same_failure_same_repair_is_not_repeated_forever():
    log=[{"gameId":"chronica-3d","failureFingerprint":"deadbeef","repairKey":"patch-a","result":"failed"}]
    assert repair_attempt_allowed(log,"chronica-3d","deadbeef","patch-a") is False
    assert repair_attempt_allowed(log,"chronica-3d","deadbeef","patch-b") is True
