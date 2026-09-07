#!/usr/bin/env python3
"""Recover the exact CHRONICA v4 release archive from Git-tracked base64 chunks.

No bytes are guessed. A candidate is accepted only when its decoded byte count and
SHA-256 match the governing manifest. Oversized transport files are searched for
an exact contiguous base64 window whose decoded SHA-256 matches the manifest.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import pathlib
import re
import subprocess
import sys
from typing import Iterable

DEFAULT_MANIFEST = pathlib.Path("handoff/chronica-playable/v4/manifest.json")
DEFAULT_OUTPUT = pathlib.Path("chronica-release-v4-xz.tar.xz")
CANDIDATE_PATHS = (
    "handoff/chronica-playable-v4/chunks/{name}",
    "handoff/chronica-playable/v4/{name}",
    "handoff/chronica-playable/v4-chunks/{name}",
    "handoff/chronica-playable/v3-chunks/{name}",
)
DEFAULT_REFS = (
    "HEAD",
    "origin/release/chronica-playable-alpha-v4-2026-09-07",
    "origin/release/chronica-playable-alpha-v2-2026-09-07",
    "origin/release/chronica-playable-alpha-2026-09-07",
    "origin/release/chronica-playable-alpha-2026-09-07-fix",
    "origin/feat/chronica-roguelite-depth",
    "origin/feat/chronica-combat-entities",
    "origin/feat/chronica-foundation-audit",
    "origin/handoff/chronica-godot-real-source-2026-09-07",
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_show(ref: str, path: str) -> bytes | None:
    proc = subprocess.run(
        ["git", "show", f"{ref}:{path}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return proc.stdout if proc.returncode == 0 else None


def ref_exists(ref: str) -> bool:
    proc = subprocess.run(
        ["git", "rev-parse", "--verify", "--quiet", ref],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return proc.returncode == 0


def compact_ascii(raw: bytes) -> str | None:
    try:
        text = raw.decode("ascii")
    except UnicodeDecodeError:
        return None
    compact = re.sub(r"\s+", "", text)
    if not re.fullmatch(r"[A-Za-z0-9+/=]*", compact):
        return None
    return compact


def exact_window(compact: str, expected_chars: int, expected_bytes: int, expected_sha: str) -> tuple[str, bytes, int] | None:
    if len(compact) < expected_chars:
        return None

    starts: Iterable[int]
    if len(compact) == expected_chars:
        starts = (0,)
    else:
        starts = range(0, len(compact) - expected_chars + 1)

    for start in starts:
        window = compact[start : start + expected_chars]
        try:
            decoded = base64.b64decode(window, validate=True)
        except Exception:
            continue
        if len(decoded) != expected_bytes:
            continue
        if sha256(decoded) == expected_sha:
            return window, decoded, start
    return None


def load_manifest(path: pathlib.Path) -> dict:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    required = {"archive_sha256", "archive_bytes", "chunks", "source_head"}
    missing = required.difference(manifest)
    if missing:
        raise SystemExit(f"manifest missing keys: {sorted(missing)}")
    if not isinstance(manifest["chunks"], list) or len(manifest["chunks"]) != 16:
        raise SystemExit("manifest must contain exactly 16 chunk records")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=pathlib.Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output", type=pathlib.Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--normalized-dir", type=pathlib.Path, default=pathlib.Path(".release/chunks"))
    parser.add_argument("--report", type=pathlib.Path, default=pathlib.Path(".release/source-recovery.json"))
    parser.add_argument("--ref", action="append", dest="refs", help="extra/ref override; repeatable")
    args = parser.parse_args()

    manifest = load_manifest(args.manifest)
    refs = args.refs if args.refs else list(DEFAULT_REFS)
    refs = [r for r in refs if ref_exists(r)]
    if not refs:
        raise SystemExit("no candidate Git refs are available")

    args.normalized_dir.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    recovered_raw: list[bytes] = []
    report: dict = {
        "manifest": str(args.manifest),
        "archive_expected_bytes": manifest["archive_bytes"],
        "archive_expected_sha256": manifest["archive_sha256"],
        "source_head": manifest["source_head"],
        "refs_checked": refs,
        "chunks": [],
    }

    for item in manifest["chunks"]:
        name = item["name"]
        expected_chars = int(item["base64_chars"])
        expected_bytes = int(item["decoded_bytes"])
        expected_sha = item["sha256"]
        found = None
        attempts = []

        for ref in refs:
            for template in CANDIDATE_PATHS:
                path = template.format(name=name)
                raw = git_show(ref, path)
                if raw is None:
                    continue
                compact = compact_ascii(raw)
                attempt = {"ref": ref, "path": path, "stored_bytes": len(raw)}
                if compact is None:
                    attempt["status"] = "INVALID_BASE64_TEXT"
                    attempts.append(attempt)
                    continue
                attempt["compact_chars"] = len(compact)
                match = exact_window(compact, expected_chars, expected_bytes, expected_sha)
                if match is None:
                    attempt["status"] = "HASH_OR_SIZE_MISMATCH"
                    attempts.append(attempt)
                    continue
                window, decoded, start = match
                attempt["status"] = "EXACT_SHA256_MATCH"
                attempt["window_start"] = start
                attempt["window_chars"] = len(window)
                attempts.append(attempt)
                found = (ref, path, window, decoded, start)
                break
            if found:
                break

        if not found:
            report["chunks"].append({
                "name": name,
                "status": "MISSING_EXACT_CHUNK",
                "expected_decoded_bytes": expected_bytes,
                "expected_sha256": expected_sha,
                "attempts": attempts,
            })
            args.report.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
            print(f"BLOCKER: {name} has no exact SHA-256-matching candidate in Git history", file=sys.stderr)
            return 20

        ref, path, window, decoded, start = found
        normalized_path = args.normalized_dir / name
        normalized_path.write_text(window + "\n", encoding="ascii")
        recovered_raw.append(decoded)
        report["chunks"].append({
            "name": name,
            "status": "RECOVERED_EXACT",
            "source_ref": ref,
            "source_path": path,
            "window_start": start,
            "decoded_bytes": len(decoded),
            "decoded_sha256": sha256(decoded),
        })
        print(f"RECOVERED {name}: {ref}:{path} window_start={start} sha256={expected_sha}")

    archive = b"".join(recovered_raw)
    actual_bytes = len(archive)
    actual_sha = sha256(archive)
    report["archive_actual_bytes"] = actual_bytes
    report["archive_actual_sha256"] = actual_sha
    report["archive_status"] = (
        "EXACT" if actual_bytes == int(manifest["archive_bytes"]) and actual_sha == manifest["archive_sha256"] else "MISMATCH"
    )
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")

    if actual_bytes != int(manifest["archive_bytes"]):
        print(f"archive size mismatch: expected {manifest['archive_bytes']} got {actual_bytes}", file=sys.stderr)
        return 21
    if actual_sha != manifest["archive_sha256"]:
        print(f"archive sha256 mismatch: expected {manifest['archive_sha256']} got {actual_sha}", file=sys.stderr)
        return 22

    args.output.write_bytes(archive)
    print(f"ARCHIVE OK bytes={actual_bytes} sha256={actual_sha} output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
