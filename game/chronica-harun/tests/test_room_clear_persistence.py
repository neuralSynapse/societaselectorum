from pathlib import Path

GAME = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (GAME / rel).read_text(encoding="utf-8")


def test_cleared_rooms_remain_open_on_reentry_and_survive_room_instance_refresh():
    director = read("scripts/generation/RoomDirector.gd")
    assert "cleared_rooms" in director
    assert "cleared_rooms[room_id] = true" in director
    assert "if bool(cleared_rooms.get(room_id, false))" in director
    activate = director[director.index("func activate_room"):director.index("func lock_room")]
    assert "room.set_locked(false)" in activate
    assert "return" in activate
    register = director[director.index("func register_room"):director.index("func register_enemy")]
    assert "cleared_rooms.get(room.room_id, false)" in register
    assert "room.mark_cleared()" in register or "room.cleared = true" in register


def test_reentry_never_locks_a_room_already_marked_cleared_on_the_room_node():
    director = read("scripts/generation/RoomDirector.gd")
    activate = director[director.index("func activate_room"):director.index("func lock_room")]
    assert "room.cleared" in activate
    cleared_check = activate.index("room.cleared")
    lock_call = activate.index("lock_room(room_id)")
    assert cleared_check < lock_call
