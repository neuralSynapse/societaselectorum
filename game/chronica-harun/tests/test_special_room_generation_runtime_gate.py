from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTOR = ROOT / "scripts/generation/SpecialRoomDirector.gd"


def test_floor_generation_does_not_apply_rooms_cleared_access_gate():
    """Runtime access gates must not make a room physically impossible to generate."""
    text = DIRECTOR.read_text(encoding="utf-8")
    assert "for_generation: bool = false" in text
    assert "if not for_generation and int(context.get(\"rooms_cleared\",0)) < int(eligibility.get(\"min_rooms_cleared\",0)): continue" in text
    assert "eligible_rooms(stage_index, cycle, context, true)" in text
