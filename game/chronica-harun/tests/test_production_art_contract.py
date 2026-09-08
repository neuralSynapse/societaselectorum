from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("generate_models", ROOT / "tools" / "generate_models.py")
assert SPEC and SPEC.loader
GM = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GM)


def _enemy_row(enemy_id: str, silhouette: str, stage_id: str = "o_olho", role: str = "common") -> dict:
    return {
        "id": enemy_id,
        "display_name": enemy_id,
        "stage_id": stage_id,
        "role": role,
        "family": silhouette,
        "visual_profile": {"silhouette": silhouette, "emission_cap": 0.32},
    }


def _boss_row(boss_id: str, silhouette: str, stage_id: str) -> dict:
    return {
        "id": boss_id,
        "display_name": boss_id,
        "stage_id": stage_id,
        "silhouette": silhouette,
    }


def test_generator_declares_production_candidate_not_final_art() -> None:
    assert GM.PRODUCTION_CLASS == "procedural_production_candidate"
    assert GM.BLENDER_USED is False
    assert "final" not in GM.PRODUCTION_CLASS.lower()


def test_seven_archontic_forms_have_dedicated_builders() -> None:
    required = {
        "ram_archon",
        "asinine_archon",
        "hyena_archon",
        "seven_head_serpent",
        "draconic_archon",
        "simian_archon",
        "fire_face",
    }
    assert required <= set(GM.ENEMY_BUILDERS)
    functions = [GM.ENEMY_BUILDERS[name] for name in sorted(required)]
    assert len({fn.__name__ for fn in functions}) == 7


def test_priority_bosses_have_explicit_builder_contract() -> None:
    assert GM.BOSS_PRIORITY_BUILDERS == {
        "blind_observer": "blind_observer_candidate",
        "impulse_archon": "impulse_archon_candidate",
        "inert_stone_guardian": "inert_stone_guardian_candidate",
    }
    for builder_name in GM.BOSS_PRIORITY_BUILDERS.values():
        assert builder_name in GM.BOSS_BUILDERS


def test_material_library_obeys_atmosphere_limits() -> None:
    charcoal = GM.production_material("charcoal")
    gold = GM.production_material("burnt_gold")
    ember = GM.production_material("heated_metal")

    assert charcoal.roughnessFactor >= 0.72
    assert gold.metallicFactor <= 0.55
    assert ember.roughnessFactor >= 0.55

    for material in (charcoal, gold, ember):
        emission = getattr(material, "emissiveFactor", None)
        if emission is not None:
            assert max(float(v) for v in emission[:3]) <= 0.18


def test_priority_enemy_candidates_are_grounded_and_readable() -> None:
    cases = [
        ("athoth", "ram_archon"),
        ("eloaios", "asinine_archon"),
        ("astaphaios", "hyena_archon"),
        ("yao", "seven_head_serpent"),
        ("sabaoth", "draconic_archon"),
        ("adonin", "simian_archon"),
        ("sabbataios", "fire_face"),
    ]
    signatures = set()
    for enemy_id, silhouette in cases:
        scene = GM.enemy_scene(_enemy_row(enemy_id, silhouette))
        metrics = GM.scene_metrics(scene)
        assert metrics["geometry_count"] >= 5
        assert metrics["height"] <= 4.5
        assert metrics["min_y"] >= -0.08
        assert metrics["max_y"] > 0.8
        signatures.add(metrics["silhouette_signature"])
    assert len(signatures) == len(cases)


@pytest.mark.parametrize(
    "boss_id,silhouette,stage_id",
    [
        ("blind_observer", "orbital_eye", "o_olho"),
        ("impulse_archon", "horned_flame", "a_chama"),
        ("inert_stone_guardian", "stone_colossus", "a_fundacao"),
    ],
)
def test_priority_boss_candidates_have_boss_scale_without_absurd_bounds(
    boss_id: str, silhouette: str, stage_id: str
) -> None:
    scene = GM.boss_scene(_boss_row(boss_id, silhouette, stage_id))
    metrics = GM.scene_metrics(scene)
    assert metrics["geometry_count"] >= 10
    assert 1.8 <= metrics["height"] <= 7.0
    assert metrics["min_y"] >= -0.08
    assert metrics["silhouette_signature"]
