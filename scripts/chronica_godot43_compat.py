#!/usr/bin/env python3
"""Apply deterministic Godot 4.3 parser-compatibility normalizations.

This release-only transform operates on the extracted build workspace. It does
not change gameplay logic or source catalogs. Each edit is an exact replacement
proven necessary by the target-branch Godot 4.3 import log.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

FIXES = {
    "scripts/progression/StageDirector.gd": [
        (
            "                    var d := enemy.global_position - player.global_position; d.y = 0.0",
            "                    var d: Vector3 = enemy.global_position - player.global_position\n                    d.y = 0.0",
        ),
        (
            '        var index := abs(GameState.run_seed + int(GameState.run_stats.get("rooms_cleared", 0)) + String(room_id).hash() + category.hash()) % ids.size()',
            '        var index: int = abs(GameState.run_seed + int(GameState.run_stats.get("rooms_cleared", 0)) + String(room_id).hash() + category.hash()) % ids.size()',
        ),
    ],
    "scripts/kinesis/KinesisProgressionDirector.gd": [
        (
            '    var payload := ability.get("ability", {}).duplicate(true)',
            '    var payload: Dictionary = ability.get("ability", {}).duplicate(true)',
        ),
    ],
    "scripts/quantum/QuantumRiftDirector.gd": [
        (
            "        var kind := archetypes[rng.randi_range(0, archetypes.size()-1)]",
            "        var kind: String = String(archetypes[rng.randi_range(0, archetypes.size()-1)])",
        ),
    ],
    "scripts/narrative/TemporalRiftDirector.gd": [
        (
            '    var total := row.get("mission", {}).get("objectives", []).size()',
            '    var total: int = row.get("mission", {}).get("objectives", []).size()',
        ),
        (
            "    var completed := completed_objectives.size() >= total and not force_retreat",
            "    var completed: bool = completed_objectives.size() >= total and not force_retreat",
        ),
    ],
    "scripts/generation/StageFloorBuilder.gd": [
        (
            "    var host_id := attachment_ids[index % attachment_ids.size()]",
            "    var host_id: String = String(attachment_ids[index % attachment_ids.size()])",
        ),
    ],
}


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, default=Path("game/chronica-harun"))
    parser.add_argument("--report", type=Path, default=Path(".release/godot43-compat.json"))
    args = parser.parse_args()

    report = {"project": str(args.project), "files": [], "replacement_count": 0}

    for rel, replacements in FIXES.items():
        path = args.project / rel
        if not path.is_file():
            raise SystemExit(f"compat target missing: {path}")

        text = path.read_text(encoding="utf-8")
        before_sha = digest(text)
        file_count = 0

        for old, new in replacements:
            old_present = old in text
            new_present = new in text
            if old_present:
                count = text.count(old)
                if count != 1:
                    raise SystemExit(f"expected exactly one old pattern in {rel}, found {count}")
                text = text.replace(old, new, 1)
                file_count += 1
            elif new_present:
                # Idempotent reruns are allowed, but we still prove the normalized form exists.
                continue
            else:
                raise SystemExit(f"neither old nor normalized parser pattern found in {rel}: {old}")

        path.write_text(text, encoding="utf-8")
        after_sha = digest(text)
        report["replacement_count"] += file_count
        report["files"].append(
            {
                "path": rel,
                "sha256_before": before_sha,
                "sha256_after": after_sha,
                "replacements_applied": file_count,
                "status": "NORMALIZED" if before_sha != after_sha else "ALREADY_NORMALIZED",
            }
        )

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"GODOT43_COMPAT_LITERAL=PASS files={len(report['files'])} "
        f"replacements={report['replacement_count']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
