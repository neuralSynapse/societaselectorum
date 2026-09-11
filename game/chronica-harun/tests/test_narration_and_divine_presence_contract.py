from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_narrator_is_autoloaded_and_has_web_and_native_backends():
    project = read("project.godot")
    assert 'NarratorDirector="*res://autoload/NarratorDirector.gd"' in project
    narrator = read("autoload/NarratorDirector.gd")
    assert "DisplayServer.tts_speak" in narrator
    assert "speechSynthesis" in narrator
    assert "JavaScriptBridge.eval" in narrator
    assert "func estimate_duration" in narrator
    assert "func stop" in narrator
    assert "pt-BR" in narrator


def test_narrative_text_is_spoken_when_it_is_shown():
    presentation = read("scripts/narrative/NarrativePresentationController.gd")
    assert "NarratorDirector.speak" in presentation
    next_line = presentation[presentation.index("func _next_line"):]
    assert "NarratorDirector.speak" in next_line[:1600]
    show_message = presentation[presentation.index("func show_story_message"):]
    assert "NarratorDirector.speak" in show_message[:800]
    present_choice = presentation[presentation.index("func present_choice"):]
    assert "NarratorDirector.speak" in present_choice[:1200]
    assert "NarratorDirector.stop" in presentation


def test_character_encounter_lines_are_spoken_too():
    runtime = read("autoload/InitiaticRuntimeIntegrator.gd")
    block = runtime[runtime.index("func _on_encounter_started"):]
    assert "NarratorDirector.speak" in block[:1000]


def test_thoth_is_not_the_generic_capsule_placeholder_anymore():
    encounters = read("scripts/narrative/CharacterEncounterDirector.gd")
    assert "_build_thoth_echo" in encounters
    for token in ["ThothRobe", "IbisHead", "IbisBeak", "LunarDisk", "ScribeTablet", "StaffOfThoth"]:
        assert token in encounters
    assert '"ASPECTO DE THOTH · PERCEPÇÃO"' in encounters
