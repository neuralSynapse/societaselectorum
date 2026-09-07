#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

EXPECTED_COUNTS = {
    'data/stages/student_journey.json': 16,
    'data/bosses/student_bosses.json': 16,
    'data/roguelite/tarot_thoth.json': 78,
    'data/roguelite/sigilla_goetia.json': 72,
    'data/roguelite/pharmaka.json': 21,
    'data/roguelite/talismans_decanic.json': 36,
    'data/roguelite/instrumenta.json': 32,
    'data/roguelite/powers.json': 15,
    'data/roguelite/daimones.json': 7,
    'data/roguelite/curses.json': 8,
    'data/roguelite/blessings.json': 6,
    'data/roguelite/routes.json': 8,
    'data/roguelite/gauntlets.json': 4,
}

REQUIRED_SPECIAL_ROOMS = {
    'arcana','reliquary','instrumentarium','laboratorium','sigillar','market',
    'bibliotheca','speculum','planetary','trial','cursed','secret','super_secret',
    'archon','theophany','historical_echo','initiation','solar_benediction','chthonic_pact'
}

FORBIDDEN_INSTITUTIONAL_WRITES = {
    'institutional_grade', 'certified_grade', 'initiation_certificate',
    'real_progress_gate_write', 'set_real_progress_gate('
}

REQUIRED_RUNTIME_FILES = [
    'project.godot',
    'scripts/player/PlayerController.gd',
    'scripts/generation/StageFloorBuilder.gd',
    'scripts/generation/SpecialRoomDirector.gd',
    'scripts/progression/StageDirector.gd',
    'scripts/progression/MetaRunDirector.gd',
    'scripts/narrative/VisionDirector.gd',
    'scripts/content/TransformationDirector.gd',
    'scripts/content/BuildResolver.gd',
    'scripts/content/PowerMutationRuntime.gd',
    'scripts/content/DaimonRuntime.gd',
    'autoload/GameState.gd',
    'autoload/ContentRegistry.gd',
    'autoload/RogueliteContentService.gd',
    'autoload/SaveService.gd',
    'distribution/release_manifest.json',
    'export_presets.cfg',
]


def _load_json(root: Path, rel: str, errors: list[str]) -> Any:
    path = root / rel
    if not path.exists():
        errors.append(f'missing file: {rel}')
        return None
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except Exception as exc:
        errors.append(f'invalid json {rel}: {exc}')
        return None


def _unique_ids(rows: list[dict], label: str, errors: list[str]) -> None:
    ids = [str(row.get('id','')) for row in rows]
    if any(not value for value in ids):
        errors.append(f'{label}: empty id')
    if len(ids) != len(set(ids)):
        errors.append(f'{label}: duplicate ids')


def validate(root: Path) -> list[str]:
    root = Path(root)
    errors: list[str] = []

    for rel in REQUIRED_RUNTIME_FILES:
        if not (root / rel).exists():
            errors.append(f'missing runtime file: {rel}')

    loaded: dict[str, list[dict]] = {}
    for rel, expected in EXPECTED_COUNTS.items():
        rows = _load_json(root, rel, errors)
        if not isinstance(rows, list):
            continue
        loaded[rel] = rows
        if len(rows) != expected:
            errors.append(f'{rel}: expected {expected}, got {len(rows)}')
        _unique_ids(rows, rel, errors)

    journey = loaded.get('data/stages/student_journey.json', [])
    if journey:
        stage_ids = [row.get('id') for row in journey]
        for index, row in enumerate(journey[:-1]):
            if row.get('next_stage') != stage_ids[index + 1]:
                errors.append(f'journey chain break: {row.get("id")} -> {row.get("next_stage")}')
        if journey[-1].get('next_stage') != 'PEREGRINUS_IGNIS_GAME':
            errors.append('journey final state is not PEREGRINUS_IGNIS_GAME')

    enemies = _load_json(root, 'data/enemies/student_enemies.json', errors)
    if isinstance(enemies, list):
        if len(enemies) < 82:
            errors.append(f'enemy catalog expected >=82, got {len(enemies)}')
        _unique_ids(enemies, 'student enemies', errors)
        for row in enemies:
            if not row.get('attack'):
                errors.append(f'enemy missing attack: {row.get("id")}')
            if not row.get('visual_profile'):
                errors.append(f'enemy missing visual profile: {row.get("id")}')

    bosses = loaded.get('data/bosses/student_bosses.json', [])
    for boss in bosses:
        phases = boss.get('phases', [])
        if len(phases) != 3:
            errors.append(f'boss {boss.get("id")}: expected 3 phases')
        attack_ids: list[str] = []
        for phase in phases:
            attacks = phase.get('attacks', [])
            if not attacks:
                errors.append(f'boss {boss.get("id")}: empty phase attacks')
            attack_ids.extend(str(a.get('id','')) for a in attacks)
        if len(set(attack_ids)) < 3:
            errors.append(f'boss {boss.get("id")}: fewer than 3 distinct attacks')

    powers = loaded.get('data/roguelite/powers.json', [])
    mutation_count = sum(len(row.get('mutations', [])) for row in powers)
    if powers and mutation_count != 45:
        errors.append(f'power mutations: expected 45, got {mutation_count}')

    tarot = loaded.get('data/roguelite/tarot_thoth.json', [])
    if tarot:
        atu = [r for r in tarot if r.get('group') == 'atu']
        minor = [r for r in tarot if r.get('group') == 'minor']
        if len(atu) != 22 or len(minor) != 56:
            errors.append(f'tarot split expected 22 Atu + 56 Minor, got {len(atu)} + {len(minor)}')

    special = _load_json(root, 'data/roguelite/special_rooms.json', errors)
    if isinstance(special, list):
        _unique_ids(special, 'special rooms', errors)
        present = {str(row.get('id')) for row in special}
        missing = sorted(REQUIRED_SPECIAL_ROOMS - present)
        if missing:
            errors.append('special rooms missing: ' + ', '.join(missing))
        for row in special:
            for field in ('eligibility','access','risk','reward_pool','telegraph','min_stage','max_per_floor'):
                if field not in row:
                    errors.append(f'special room {row.get("id")}: missing {field}')
            chance = row.get('base_chance')
            if not isinstance(chance, (int,float)) or not 0 <= float(chance) <= 1:
                errors.append(f'special room {row.get("id")}: invalid base_chance')

    theophanies = _load_json(root, 'data/roguelite/theophanies.json', errors)
    echoes = _load_json(root, 'data/roguelite/historical_echoes.json', errors)
    for label, rows, minimum in (('theophanies',theophanies,18),('historical echoes',echoes,6)):
        if isinstance(rows, list):
            if len(rows) < minimum:
                errors.append(f'{label}: expected at least {minimum}, got {len(rows)}')
            _unique_ids(rows, label, errors)
            for row in rows:
                if not row.get('conditions'):
                    errors.append(f'{label} {row.get("id")}: missing conditions')
                if not row.get('codex_note'):
                    errors.append(f'{label} {row.get("id")}: missing codex_note')

    transforms = _load_json(root, 'data/roguelite/transformations.json', errors)
    if isinstance(transforms, list):
        if len(transforms) < 10:
            errors.append(f'transformations: expected >=10, got {len(transforms)}')
        for row in transforms:
            profile = row.get('visual_profile', {})
            for field in ('mesh_overlay','material_shift','vfx'):
                if not profile.get(field):
                    errors.append(f'transformation {row.get("id")}: missing visual {field}')

    codex = _load_json(root, 'data/codex/full_codex.json', errors)
    if isinstance(codex, list):
        labels = {row.get('provenance_class') for row in codex}
        required_labels = {'source','tradition','interpretation','electorum_dramatization'}
        if not required_labels.issubset(labels):
            errors.append('codex missing provenance layers')
        if any(not row.get('source_note') for row in codex):
            errors.append('codex contains entries without source_note')

    release = _load_json(root, 'distribution/release_manifest.json', errors)
    if isinstance(release, dict):
        if set(release.get('quality_presets',{})) != {'1080p','1440p','4k'}:
            errors.append('release quality presets must be 1080p/1440p/4k')
        if int(release.get('save_schema_version',0)) < 2:
            errors.append('release save_schema_version must be >=2')
        backend = release.get('backend',{})
        if backend.get('no_embedded_secrets') is not True or backend.get('database_url_client_side') is not False:
            errors.append('release backend secret boundary invalid')

    project_text = (root / 'project.godot').read_text(encoding='utf-8', errors='ignore') if (root/'project.godot').exists() else ''
    for token in ('GameState=', 'SaveService=', 'ContentRegistry=', 'RogueliteContentService='):
        if token not in project_text:
            errors.append(f'project missing autoload {token[:-1]}')

    player_path = root/'scripts/player/PlayerController.gd'
    if player_path.exists():
        player = player_path.read_text(encoding='utf-8', errors='ignore').lower()
        for token in ('camera3d','mouse','move_and_slide','input.get_vector'):
            if token not in player:
                errors.append(f'first-person player missing {token}')
        if 'third_person' in player:
            errors.append('third-person contract detected')

    runtime_text = '\n'.join(
        path.read_text(encoding='utf-8', errors='ignore')
        for path in root.rglob('*.gd')
    ).lower()
    for token in FORBIDDEN_INSTITUTIONAL_WRITES:
        if token in runtime_text:
            errors.append(f'forbidden institutional write token: {token}')

    # Historical figures must be narrative/event content, never default enemy spawns.
    vision_path = root/'scripts/narrative/VisionDirector.gd'
    if vision_path.exists():
        vision = vision_path.read_text(encoding='utf-8', errors='ignore')
        if 'spawn_enemy' in vision:
            errors.append('VisionDirector must not default historical/theophanic entries to enemies')

    # Distribution contract must expose both desktop platforms.
    export_path = root/'export_presets.cfg'
    if export_path.exists():
        export_text = export_path.read_text(encoding='utf-8', errors='ignore')
        for token in ('Windows Desktop','Linux/X11','CHRONICA_HARUN.exe','CHRONICA_HARUN.x86_64'):
            if token not in export_text:
                errors.append(f'export preset missing {token}')

    return errors


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    errors = validate(root)
    if errors:
        print('COMPLETE GAME VALIDATION: FAIL')
        for error in errors:
            print(' -', error)
        return 1
    print('COMPLETE GAME VALIDATION: PASS')
    print(' - Student journey and 82+ enemy forms')
    print(' - 16 bosses / 3 phases')
    print(' - 78 Tarot / 72 Sigilla / 21 Pharmaka / 36 Talismans')
    print(' - 32 Instrumenta / 45 mutations / 7 Daimones')
    print(' - special rooms / visions / meta-run / transformations')
    print(' - Windows + Linux distribution contract')
    print(' - no gameplay institutional-grade writes')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
