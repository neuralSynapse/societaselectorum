from pathlib import Path
import importlib.util

ROOT = Path(__file__).resolve().parents[1]


def load_validator():
    spec = importlib.util.spec_from_file_location('complete_validator', ROOT/'tools/validate_complete_game.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_complete_validator_reports_no_errors():
    module = load_validator()
    assert module.validate(ROOT) == []


def test_runtime_qa_doc_is_explicit_about_godot_binary_status():
    text = (ROOT/'docs/desktop-release-qa.md').read_text().lower()
    assert 'godot headless' in text
    assert 'não executado' in text or 'executado' in text
    assert 'mouse look' in text and 'projéteis' in text and 'save/load' in text
