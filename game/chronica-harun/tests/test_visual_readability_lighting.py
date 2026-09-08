from pathlib import Path
import re

MAIN_SCENE = Path(__file__).resolve().parents[1] / "scenes" / "boot" / "Main.tscn"


def _node_block(text: str, node_name: str) -> str:
    marker = f'[node name="{node_name}"'
    start = text.find(marker)
    assert start >= 0, f"missing node {node_name}"
    next_node = text.find("\n[node ", start + len(marker))
    return text[start:] if next_node < 0 else text[start:next_node]


def _float_property(block: str, prop: str) -> float:
    match = re.search(rf"^{re.escape(prop)}\s*=\s*([0-9.]+)\s*$", block, re.MULTILINE)
    assert match, f"missing {prop}"
    return float(match.group(1))


def test_main_world_has_readability_key_and_fill_lighting():
    text = MAIN_SCENE.read_text(encoding="utf-8")
    key = _node_block(text, "KeyLight")
    fill = _node_block(text, "ReadabilityFill")

    assert _float_property(key, "light_energy") >= 1.0
    assert _float_property(fill, "light_energy") >= 0.35
    assert "shadow_enabled = false" in fill


def test_main_world_has_warm_global_readability_light():
    text = MAIN_SCENE.read_text(encoding="utf-8")
    warm = _node_block(text, "ReadabilityWarmFill")

    assert _float_property(warm, "light_energy") >= 0.2
    assert _float_property(warm, "omni_range") >= 20.0
    assert 'light_color = Color(' in warm
