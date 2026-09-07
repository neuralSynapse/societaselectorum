from pathlib import Path
import json, re

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/"data"/"roguelite"

def load_catalogs():
    return {p.stem:json.loads(p.read_text(encoding="utf-8")) for p in DATA.glob("*.json")}

def supported_kinds():
    text=(ROOT/"scripts/content/BuildResolver.gd").read_text(encoding="utf-8")
    m=re.search(r'const SUPPORTED_EFFECT_KINDS := \[(.*?)\]\n',text,re.S)
    assert m, "SUPPORTED_EFFECT_KINDS constant missing"
    return set(re.findall(r'"([^"]+)"',m.group(1)))

def test_every_content_effect_is_dispatchable():
    cats=load_catalogs(); supported=supported_kinds()
    missing=sorted({r["effect"]["kind"] for rs in cats.values() for r in rs} - supported)
    assert not missing, missing

def test_sigilla_have_72_distinct_runtime_signatures():
    sigilla=load_catalogs()["sigilla"]
    assert len({r["effect"]["benefit"]["signature"] for r in sigilla})==72

def test_synergy_and_exclusion_references_are_ids_or_tags():
    cats=load_catalogs(); ids={r["id"] for rs in cats.values() for r in rs}
    for rs in cats.values():
        for r in rs:
            for ref in r["synergies"]: assert ref.startswith("tag:") or ref in ids, (r["id"],ref)
            for ref in r["exclusions"]: assert ref.startswith("tag:") or ref in ids, (r["id"],ref)

def test_all_mutations_bind_to_existing_power_and_runtime_hook():
    cats=load_catalogs(); powers={r["id"] for r in cats["powers"]}
    hooks={"modify_damage","on_player_damaged","on_room_cleared","on_dodge","on_enemy_killed","on_projectile_about_to_hit","passive_flags"}
    for m in cats["mutations"]:
        assert m["effect"]["parent_power"] in powers
        assert m["effect"]["hook"] in hooks

def test_instrumenta_have_32_distinct_actions():
    instrumenta=load_catalogs()["instrumenta"]
    assert len({r["effect"]["kind"] for r in instrumenta})==32
