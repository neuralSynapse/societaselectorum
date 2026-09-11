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


def test_narrator_tracks_visible_narrative_text_instead_of_combat_spam():
    narrator = read("autoload/NarratorDirector.gd")
    for node_name in ["Subtitle", "StoryMessage", "ChoicePrompt"]:
        assert node_name in narrator
    assert "_last_text_by_path" in narrator
    assert "is_visible_in_tree" in narrator
    assert "NarratorDirector" not in read("scripts/ui/HUDController.gd")


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
