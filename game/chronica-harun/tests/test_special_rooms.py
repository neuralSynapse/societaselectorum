from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/"data"/"roguelite"

def rooms(): return json.loads((DATA/"special_rooms.json").read_text(encoding="utf-8"))

def test_all_required_special_rooms_exist():
    names={r["name"] for r in rooms()}
    required={"Câmara do Arcano","Reliquarium","Instrumentarium","Laboratorium","Câmara Sigillar","Mercado de Essência","Bibliotheca","Speculum","Câmara Planetária","Câmara de Provação","Câmara Maldita","Sala Secreta","Sala Duplamente Secreta","Câmara do Arconte","Câmara Teofânica","Câmara Histórica","Câmara de Iniciação"}
    assert required <= names

def test_every_room_has_runtime_room_contract():
    fields={"spawn_condition","entry","risk","reward","runtime_event","persistent_state","map_icon","discovery_feedback","room_role"}
    for room in rooms(): assert fields <= set(room), (room["id"], fields-set(room))

def test_secret_rooms_require_physical_openers():
    secret=[r for r in rooms() if r["room_role"] in {"secret","super_secret"}]
    assert len(secret)==2
    physical={"ritual_bomb","rupture_charge","wall_break"}
    for room in secret:
        assert room["entry"]["mode"]=="hidden_wall"
        assert physical & set(room["entry"]["accepted_openers"])
        assert "secret" not in room["entry"].get("label","").lower()

def test_runtime_hard_caps_secret_rooms_at_two():
    text=(ROOT/"scripts/generation/SpecialRoomDirector.gd").read_text(encoding="utf-8")
    assert "const MAX_SECRET_ROOMS := 2" in text
    assert "min(layout_secret_capacity, MAX_SECRET_ROOMS)" in text

def test_postboss_rooms_are_conditioned_and_mutually_exclusive():
    post=[r for r in rooms() if r["postboss"]]
    assert len(post)==3
    assert {r["name"] for r in post}=={"Câmara Pneumática","Câmara Ctônica","Mesa do Pacto"}
    assert all(r["exclusive_group"]=="postboss_path" for r in post)
    assert all("postboss:cleared" in r["eligibility"]["requires_tags"] for r in post)

def test_special_room_runtime_and_floor_bridge_exist():
    assert (ROOT/"scripts/rooms/SpecialRoomRuntime.gd").exists()
    assert (ROOT/"scenes/rooms/SpecialRoomRuntime.tscn").exists()
    builder=(ROOT/"scripts/generation/StageFloorBuilder.gd").read_text(encoding="utf-8")
    assert "SpecialRoomDirector" in builder
    assert "build_floor_rooms" in builder
