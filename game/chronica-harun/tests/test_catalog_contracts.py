from pathlib import Path
import json
import pytest

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "roguelite"
CATALOG_FILES = {"gauntlets":"gauntlets.json","tarot":"tarot.json","sigilla":"sigilla.json","pharmaka":"pharmaka.json","talismans":"talismans.json","instrumenta":"instrumenta.json","powers":"powers.json","mutations":"mutations.json","daimones":"daimones.json","relics":"relics.json","transformations":"transformations.json","curses":"curses.json","blessings":"blessings.json","routes":"routes.json","special_rooms":"special_rooms.json"}
REQUIRED = {"id","name","rarity","pool","eligibility","effect","cost","duration","stacking","synergies","exclusions","vfx_hook","sfx_hook","save_state","codex","provenance"}
EXPECTED = {"gauntlets":4,"tarot":78,"sigilla":72,"pharmaka":21,"talismans":36,"instrumenta":32,"powers":15,"mutations":45,"daimones":7,"relics":9,"transformations":12,"curses":8,"blessings":6,"routes":8,"special_rooms":20}

@pytest.fixture
def catalogs(): return {k: json.loads((DATA/v).read_text(encoding="utf-8")) for k,v in CATALOG_FILES.items()}

def test_required_catalog_counts(catalogs):
    for key,count in EXPECTED.items(): assert len(catalogs[key])==count,(key,len(catalogs[key]),count)

def test_all_records_have_common_runtime_contract(catalogs):
    for key,records in catalogs.items():
        for record in records:
            missing=REQUIRED-set(record); assert not missing,(key,record.get("id"),sorted(missing))

def test_ids_are_globally_unique(catalogs):
    ids=[r["id"] for records in catalogs.values() for r in records]; assert len(ids)==len(set(ids))

def test_every_record_has_runtime_hooks_and_save_contract(catalogs):
    for records in catalogs.values():
        for r in records:
            assert r["effect"]["kind"]
            assert r["vfx_hook"].startswith("vfx.") and r["sfx_hook"].startswith("sfx.")
            assert r["save_state"]["scope"] in {"run","campaign","none"}
            assert r["provenance"]["level"] in {"fonte","tradicao","interpretacao","dramatizacao_electorum"}

def test_tarot_structure_is_complete(catalogs):
    tarot=catalogs["tarot"]
    assert sum(1 for c in tarot if c["arcana_class"]=="atu")==22
    assert sum(1 for c in tarot if c["arcana_class"]=="minor")==56
    for suit in ("wands","cups","swords","disks"):
        cards=[c for c in tarot if c.get("suit")==suit]
        assert len(cards)==14
        assert {c["rank"] for c in cards}=={"ace","2","3","4","5","6","7","8","9","10","princess","prince","queen","knight"}

def test_court_cards_are_not_plain_numeric_modifiers(catalogs):
    courts=[c for c in catalogs["tarot"] if c.get("rank") in {"princess","prince","queen","knight"}]
    assert len(courts)==16
    assert all(c["effect"]["kind"] in {"manifest_field","combo_engine","resource_aura","suit_finisher"} for c in courts)

def test_meta_counts_meet_minimums(catalogs):
    assert len(catalogs["relics"])>=9 and len(catalogs["transformations"])>=10 and len(catalogs["curses"])>=8 and len(catalogs["blessings"])>=6 and len(catalogs["routes"])==8
