# FRONT B RESTORE · CHRONICA HARUN Godot

The real recovered Godot source required by Front B is now persisted on this branch as a compact base64-encoded tarball.

## Download / restore

Fetch:

`chronica-handoff/CHRONICA_HARUN_FRONT_B_SOURCE_MIN_2026-09-07.tar.gz.b64`

Then:

```bash
base64 -d CHRONICA_HARUN_FRONT_B_SOURCE_MIN_2026-09-07.tar.gz.b64 > CHRONICA_HARUN_FRONT_B_SOURCE_MIN_2026-09-07.tar.gz
mkdir chronica-harun-godot
cd chronica-harun-godot
tar -xzf ../CHRONICA_HARUN_FRONT_B_SOURCE_MIN_2026-09-07.tar.gz
python tools/generate_recovered_content.py
python tools/generate_models.py
pytest -q
```

After the two generators run, the restored tree contains the requested combat source and generated data/assets, including:

- `project.godot`
- `data/enemies/student_enemies.json`
- `data/bosses/student_bosses.json`
- `scenes/enemies/`
- `scenes/bosses/`
- `scripts/ai/`
- `scripts/combat/`
- player/projectile/room/stage runtimes
- enemy/boss model generation

Package SHA-256:

`56ea873e24c727eaa14fe84f79680177285b4b07688b1b8d6990a5a7f599dda3`

Recovered source Git HEAD used to create the pack:

`82449af8f83c10b46b4e4d907e2f1aea39bdee48`

Gameplay reconstruction base:

`f4647798046254baff3447d9e224dd4fdb52d548`

Verification before packaging:

```text
On branch feat/chronica-narrative-integration
nothing to commit, working tree clean
```

```text
82449af feat: add cinematic presentation and story codex runtime
0f2e5c6 feat: integrate canonical CHRONICA narrative runtime
f464779 feat: reconstruct playable Godot runtime and generated models
15bb60f chore: recover CHRONICA HARUN Godot checkpoint
0650de3 chore: initialize Godot recovery workspace
```

```text
.....................................................                    [100%]
53 passed in 0.10s
```

The older declared commits `ed9570e`, `62be8b4`, `c229ccd`, `9a418c3`, `e01f1dc`, `94ed311`, `e3b38a9`, `5259c0b`, `52a2295` were checked and are absent from the recovered object database. Their intended state was reconstructed into the recovery commits above.

Do not substitute the browser game for this Godot source. Do not merge this handoff branch into `main`.
