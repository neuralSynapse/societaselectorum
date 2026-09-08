#!/usr/bin/env python3
"""Generate deterministic CHRONICA 3D production candidates.

These are deliberately classified as procedural production candidates, never final art.
The output paths are stable so future Blender-authored GLBs can replace them 1:1.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

from production_art_core import (  # noqa: E402
    BLENDER_USED, GENERATOR_VERSION, PALETTE, PRODUCTION_CLASS, add,
    box, export_scene, ground_scene, production_material, scene_metrics, transform,
)
from production_art_enemies import (  # noqa: E402
    ENEMY_BUILDERS, canonical_enemy_builder, enemy_scene,
)
from production_art_bosses import (  # noqa: E402
    BOSS_BUILDERS, BOSS_PRIORITY_BUILDERS, boss_builder_name, boss_scene,
)

ROOT = Path(__file__).resolve().parents[1]
ENEMY_DATA = ROOT / "data/enemies/student_enemies.json"
BOSS_DATA = ROOT / "data/bosses/student_bosses.json"
ENEMY_OUT = ROOT / "art/generated/enemies"
BOSS_OUT = ROOT / "art/generated/bosses"
VIEWMODEL_OUT = ROOT / "art/generated/viewmodel"
PRODUCTION_OUT = ROOT / "art/production"

PRIORITY_STAGES = {"o_olho", "a_chama", "a_fundacao", "a_obra"}
ARCHONTIC_BUILDERS = {
    "ram_archon", "asinine_archon", "hyena_archon", "seven_head_serpent",
    "draconic_archon", "simian_archon", "fire_face",
}


def ensure_model_paths(rows: list[dict], kind: str) -> bool:
    changed = False
    plural = "enemies" if kind == "enemy" else "bosses"
    for row in rows:
        wanted = f"res://art/generated/{plural}/{row['id']}.glb"
        if row.get("model_path") != wanted:
            row["model_path"] = wanted
            changed = True
    return changed


def asset_status(kind: str, row: dict, builder_name: str) -> str:
    if kind == "boss" and str(row["id"]) in BOSS_PRIORITY_BUILDERS:
        return "priority_candidate"
    if kind == "enemy" and (str(row.get("stage_id", "")) in PRIORITY_STAGES or builder_name in ARCHONTIC_BUILDERS):
        return "priority_candidate"
    return "general_candidate"


def export_rows(rows: list[dict], out: Path, kind: str) -> dict[str, dict]:
    manifest: dict[str, dict] = {}
    for row in rows:
        if kind == "enemy":
            silhouette = str(row.get("visual_profile", {}).get("silhouette", row.get("family", "walker")))
            builder_name = canonical_enemy_builder(silhouette)
            scene = enemy_scene(row)
        else:
            silhouette = str(row.get("silhouette", "sevenfold_throne"))
            builder_name = boss_builder_name(row)
            scene = boss_scene(row)
        metrics = export_scene(scene, out / f"{row['id']}.glb")
        metrics.update({
            "kind": kind,
            "display_name": row.get("display_name", row["id"]),
            "stage_id": row.get("stage_id", ""),
            "source_silhouette": silhouette,
            "builder": builder_name,
            "production_class": PRODUCTION_CLASS,
            "status": asset_status(kind, row, builder_name),
            "blender_used": BLENDER_USED,
        })
        manifest[str(row["id"])] = metrics
    return manifest


def viewmodel_scene():
    import trimesh
    sc = trimesh.Scene()
    skin = production_material("bone_ash")
    cuff = production_material("charcoal")
    copper = production_material("copper")
    for side in (-1, 1):
        prefix = "left" if side < 0 else "right"
        add(sc, box((.16,.64,.18)), f"{prefix}_forearm", transform(side*.27,.39,.17,rz=-side*.11), skin)
        add(sc, box((.24,.22,.26)), f"{prefix}_hand", transform(side*.24,.77,-.02,rz=-side*.05), skin)
        for finger in range(4):
            x = side*(.15 + finger*.035)
            add(sc, box((.035,.25,.045)), f"{prefix}_finger_{finger}", transform(x,.92,-.08,rz=-side*(.05+finger*.01)), skin)
        add(sc, box((.20,.11,.22)), f"{prefix}_cuff", transform(side*.29,.12,.19), cuff)
        add(sc, box((.06,.09,.025)), f"{prefix}_cuff_seal", transform(side*.29,.12,.065), copper)
    return ground_scene(sc)


def animation_contracts() -> dict:
    common = {
        "idle": {"required": True, "root_motion": False, "mechanical_timing_source": "gameplay_data"},
        "locomotion": {"required": True, "root_motion": False, "mechanical_timing_source": "movement_system"},
        "windup": {"required": True, "root_motion": False, "mechanical_timing_source": "AttackStateMachine"},
        "attack": {"required": True, "root_motion": False, "mechanical_timing_source": "AttackStateMachine"},
        "recovery": {"required": True, "root_motion": False, "mechanical_timing_source": "AttackStateMachine"},
        "hit_reaction": {"required": True, "root_motion": False, "mechanical_timing_source": "combat_runtime"},
        "death": {"required": True, "root_motion": False, "mechanical_timing_source": "combat_runtime"},
    }
    boss = dict(common)
    boss["phase_transition"] = {"required": True, "root_motion": False, "mechanical_timing_source": "boss_phase_runtime"}
    return {
        "schema": 1,
        "production_class": PRODUCTION_CLASS,
        "blender_used": BLENDER_USED,
        "note": "Naming and semantic contract only. No rig or final animation is claimed.",
        "enemy_clips": common,
        "boss_clips": boss,
    }


def viewmodel_contract(metrics: dict) -> dict:
    return {
        "schema": 1,
        "production_class": PRODUCTION_CLASS,
        "blender_used": BLENDER_USED,
        "asset": "res://art/generated/viewmodel/first_person_hands.glb",
        "classification": "procedural production candidate",
        "composition": ["left_forearm", "left_hand", "right_forearm", "right_hand"],
        "camera_rule": "render in a dedicated first-person layer; world collision remains separate; this mesh is not a world-space camera-child contract",
        "scale_meters": 1.0,
        "forward_axis": "-Z",
        "up_axis": "+Y",
        "sockets": {"right_grip": [0.22,0.84,-0.08], "left_grip": [-0.22,0.84,-0.08]},
        "metrics": metrics,
    }


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    enemies = json.loads(ENEMY_DATA.read_text(encoding="utf-8"))
    bosses = json.loads(BOSS_DATA.read_text(encoding="utf-8"))
    enemy_changed = ensure_model_paths(enemies, "enemy")
    boss_changed = ensure_model_paths(bosses, "boss")
    if enemy_changed:
        ENEMY_DATA.write_text(json.dumps(enemies, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    if boss_changed:
        BOSS_DATA.write_text(json.dumps(bosses, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")

    enemy_manifest = export_rows(enemies, ENEMY_OUT, "enemy")
    boss_manifest = export_rows(bosses, BOSS_OUT, "boss")
    viewmodel_metrics = export_scene(viewmodel_scene(), VIEWMODEL_OUT / "first_person_hands.glb")

    write_json(ENEMY_OUT / "manifest.json", enemy_manifest)
    write_json(BOSS_OUT / "manifest.json", boss_manifest)
    write_json(PRODUCTION_OUT / "animation_contracts.json", animation_contracts())
    write_json(PRODUCTION_OUT / "fps_viewmodel_contract.json", viewmodel_contract(viewmodel_metrics))
    write_json(PRODUCTION_OUT / "production_art_manifest.json", {
        "schema": 1,
        "generator_version": GENERATOR_VERSION,
        "production_class": PRODUCTION_CLASS,
        "blender_used": BLENDER_USED,
        "final_art_claimed": False,
        "palette": PALETTE,
        "counts": {"enemies": len(enemy_manifest), "bosses": len(boss_manifest), "viewmodel": 1},
        "priority": {
            "stages": sorted(PRIORITY_STAGES),
            "bosses": sorted(BOSS_PRIORITY_BUILDERS),
            "archontic_builders": sorted(ARCHONTIC_BUILDERS),
        },
        "enemies": enemy_manifest,
        "bosses": boss_manifest,
        "viewmodel": viewmodel_metrics,
    })
    print(f"generated {len(enemy_manifest)} enemy GLBs and {len(boss_manifest)} boss GLBs")
    print(f"production_class={PRODUCTION_CLASS} blender_used={BLENDER_USED}")


if __name__ == "__main__":
    main()
