import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EXPECTED = [
    "o_olho","a_chama","a_fundacao","a_eleicao","a_balanca","a_vontade",
    "o_carater","a_disciplina","a_clareza","a_transmutacao","o_corpo",
    "a_obra","a_fortuna","a_influencia","o_legado","initiation_chamber"
]

def load(name):
    return json.loads((ROOT/name).read_text(encoding="utf-8"))

def flatten(adapter):
    out=[]
    for unit in adapter["units"]:
        out.extend(unit["canonStageIds"])
    return out

def test_contract_has_canonical_16_stage_order_and_game_only_result():
    c=load("canon-contract.json")
    assert c["contractVersion"]
    assert [x["id"] for x in c["stages"]] == EXPECTED
    assert c["rules"]["storyResultState"] == "PEREGRINUS_IGNIS_GAME"
    assert c["rules"]["institutionalWrite"] is False
    assert c["rules"]["aleppoAbsoluteChronology"] == "open"

def test_every_adapter_covers_same_canonical_story_once_in_order():
    for name in [
        "adapters/chronica-3d.json",
        "adapters/harun-roguelite.json",
        "adapters/harun-survivor.json",
    ]:
        a=load(name)
        assert a["institutionalWrite"] is False
        assert flatten(a) == EXPECTED, name
        assert len(flatten(a)) == len(set(flatten(a)))

def test_genre_identity_stays_distinct():
    modes={load(x)["genre"] for x in [
        "adapters/chronica-3d.json",
        "adapters/harun-roguelite.json",
        "adapters/harun-survivor.json",
    ]}
    assert modes == {"3d_fps","2d_roguelite","mobile_survivor"}
