from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_narrator_is_autoloaded_and_has_web_and_native_backends():
    project = read("project.godot")
    assert 'NarratorDirector="*res://autoload/NarratorDirector.gd"' in project
    assert "general/text_to_speech=true" in project
    narrator = read("autoload/NarratorDirector.gd")
    assert "DisplayServer.tts_speak" in narrator
    assert "speechSynthesis" in narrator
    assert "JavaScriptBridge.eval" in narrator
    assert "func estimate_duration" in narrator
    assert "func stop" in narrator
    assert "pt-BR" in narrator


def test_narrator_tracks_visible_narrative_text_instead_of_combat_spam():
    narrator = read("autoload/NarratorDirector.gd")
    for node_name in ["Subtitle", "StoryMessage", "ChoicePrompt", "Message"]:
        assert node_name in narrator
    assert "_last_text_by_path" in narrator
    assert "is_visible_in_tree" in narrator
    assert 'return "\\n" in raw_text' in narrator
    assert "line_timer" in narrator
    assert "hide_timer" in narrator
    assert "_estimated_queue_until_msec" in narrator
    hud = read("scripts/ui/HUDController.gd")
    # HUD may ask the narrator for a read-time estimate so acquisition text stays
    # visible long enough, but it must never trigger speech directly from combat UI.
    assert "NarratorDirector.speak" not in hud


def test_thoth_is_not_the_generic_capsule_placeholder_anymore():
    encounters = read("scripts/narrative/CharacterEncounterDirector.gd")
    assert "_build_thoth_echo" in encounters
    for token in ["ThothRobe", "IbisHead", "IbisBeak", "LunarDisk", "ScribeTablet", "StaffOfThoth"]:
        assert token in encounters
    assert '"ASPECTO DE THOTH · PERCEPÇÃO"' in encounters


def test_gothic_beams_do_not_use_an_invalid_up_vector_when_vertical():
    room = read("scripts/generation/RoomShell.gd")
    beam = room[room.index("func _add_beam_between"):]
    assert "direction_normalized" in beam[:1800]
    assert "safe_up" in beam[:1800]
    assert "absf(direction_normalized.dot(Vector3.UP))" in beam[:1800]