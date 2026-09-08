#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[1]
ENEMY_DATA = ROOT / "data/enemies/student_enemies.json"
BOSS_DATA = ROOT / "data/bosses/student_bosses.json"
ENEMY_DIR = ROOT / "art/generated/enemies"
BOSS_DIR = ROOT / "art/generated/bosses"
PRODUCTION_DIR = ROOT / "art/production"
EXPECTED_ENEMIES = 82
EXPECTED_BOSSES = 16
PRODUCTION_CLASS = "procedural_production_candidate"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def local_res(path: str) -> Path:
    require(path.startswith("res://"), f"non-res model path: {path}")
    return ROOT / path.removeprefix("res://")


def load_glb(path: Path) -> trimesh.Scene:
    require(path.exists(), f"missing asset: {path.relative_to(ROOT)}")
    scene = trimesh.load(path, force="scene")
    require(isinstance(scene, trimesh.Scene), f"not a scene: {path}")
    require(bool(scene.geometry), f"empty geometry: {path}")
    bounds = np.asarray(scene.bounds, dtype=float)
    require(bounds.shape == (2, 3) and np.isfinite(bounds).all(), f"invalid bounds: {path}")
    return scene


def validate_asset(path: Path, kind: str) -> None:
    scene = load_glb(path)
    bounds = np.asarray(scene.bounds, dtype=float)
    extents = bounds[1] - bounds[0]
    require(float(bounds[0][1]) >= -0.12, f"ungrounded {kind}: {path.name} min_y={bounds[0][1]}")
    require(float(extents[1]) > 0.25, f"collapsed {kind}: {path.name}")
    require(float(extents[1]) <= (7.0 if kind == "boss" else 4.5), f"absurd height {kind}: {path.name}={extents[1]}")
    require(float(extents.max()) <= (9.0 if kind == "boss" else 6.0), f"absurd scale {kind}: {path.name}={extents}")
    for geom in scene.geometry.values():
        require(len(geom.vertices) > 0 and len(geom.faces) > 0, f"empty primitive in {path.name}")
        material = getattr(geom.visual, "material", None)
        require(material is not None, f"missing material in {path.name}")
        emission = getattr(material, "emissiveFactor", None)
        if emission is not None:
            require(max(float(v) for v in emission[:3]) <= 0.18001, f"emission wash in {path.name}: {emission}")


def main() -> None:
    enemies = json.loads(ENEMY_DATA.read_text(encoding="utf-8"))
    bosses = json.loads(BOSS_DATA.read_text(encoding="utf-8"))
    require(len(enemies) == EXPECTED_ENEMIES, f"enemy catalog count {len(enemies)} != {EXPECTED_ENEMIES}")
    require(len(bosses) == EXPECTED_BOSSES, f"boss catalog count {len(bosses)} != {EXPECTED_BOSSES}")
    require(len({row["id"] for row in enemies}) == EXPECTED_ENEMIES, "duplicate enemy ids")
    require(len({row["id"] for row in bosses}) == EXPECTED_BOSSES, "duplicate boss ids")

    enemy_glbs = sorted(ENEMY_DIR.glob("*.glb"))
    boss_glbs = sorted(BOSS_DIR.glob("*.glb"))
    require(len(enemy_glbs) == EXPECTED_ENEMIES, f"generated enemy count {len(enemy_glbs)}")
    require(len(boss_glbs) == EXPECTED_BOSSES, f"generated boss count {len(boss_glbs)}")

    for row in enemies:
        path = local_res(str(row["model_path"]))
        require(path == ENEMY_DIR / f"{row['id']}.glb", f"enemy path contract drift: {row['id']}")
        validate_asset(path, "enemy")
    for row in bosses:
        path = local_res(str(row["model_path"]))
        require(path == BOSS_DIR / f"{row['id']}.glb", f"boss path contract drift: {row['id']}")
        validate_asset(path, "boss")

    manifest = json.loads((PRODUCTION_DIR / "production_art_manifest.json").read_text(encoding="utf-8"))
    require(manifest["production_class"] == PRODUCTION_CLASS, "wrong production class")
    require(manifest["blender_used"] is False, "pipeline must not claim Blender")
    require(manifest["final_art_claimed"] is False, "pipeline must not claim final art")
    require(manifest["counts"] == {"enemies": 82, "bosses": 16, "viewmodel": 1}, "manifest counts drift")
    require(len(manifest["enemies"]) == 82 and len(manifest["bosses"]) == 16, "manifest asset coverage drift")

    statuses = {entry["status"] for entry in [*manifest["enemies"].values(), *manifest["bosses"].values()]}
    require(statuses <= {"priority_candidate", "general_candidate"}, f"unexpected status: {statuses}")
    require("residual_placeholder" not in statuses, "old placeholder remains")
    for entry in [*manifest["enemies"].values(), *manifest["bosses"].values()]:
        require(entry["production_class"] == PRODUCTION_CLASS, "per-asset class drift")
        require(entry["blender_used"] is False, "per-asset Blender falsehood")
        require(float(entry["max_emission"]) <= 0.18001, "manifest emission cap exceeded")

    expected_boss_builders = {
        "blind_observer": "blind_observer_candidate",
        "impulse_archon": "impulse_archon_candidate",
        "inert_stone_guardian": "inert_stone_guardian_candidate",
    }
    for bid, builder in expected_boss_builders.items():
        entry = manifest["bosses"][bid]
        require(entry["builder"] == builder, f"priority boss builder drift: {bid}")
        require(entry["status"] == "priority_candidate", f"priority boss status drift: {bid}")
        require(int(entry["geometry_count"]) >= 10, f"priority boss underbuilt: {bid}")

    required_archons = {"ram_archon","asinine_archon","hyena_archon","seven_head_serpent","draconic_archon","simian_archon","fire_face"}
    used_builders = {entry["builder"] for entry in manifest["enemies"].values()}
    require(required_archons <= used_builders, f"missing archontic builder coverage: {required_archons-used_builders}")

    animation = json.loads((PRODUCTION_DIR / "animation_contracts.json").read_text(encoding="utf-8"))
    common = {"idle","locomotion","windup","attack","recovery","hit_reaction","death"}
    require(common <= set(animation["enemy_clips"]), "enemy animation contract incomplete")
    require(common | {"phase_transition"} <= set(animation["boss_clips"]), "boss animation contract incomplete")
    require(animation["blender_used"] is False, "animation contract Blender falsehood")

    viewmodel_contract = json.loads((PRODUCTION_DIR / "fps_viewmodel_contract.json").read_text(encoding="utf-8"))
    viewmodel_path = local_res(viewmodel_contract["asset"])
    validate_asset(viewmodel_path, "enemy")
    require("dedicated first-person layer" in viewmodel_contract["camera_rule"], "viewmodel camera separation missing")
    require(viewmodel_contract["blender_used"] is False, "viewmodel Blender falsehood")

    print("ASSET_PATHS_ENEMIES=82/82")
    print("ASSET_PATHS_BOSSES=16/16")
    print("BLENDER_USED=false")
    print("FINAL_ART_CLAIMED=false")
    print("PRODUCTION ART VALIDATION: PASS")


if __name__ == "__main__":
    main()
