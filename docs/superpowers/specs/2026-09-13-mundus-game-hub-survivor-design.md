# MUNDUS Game Hub + Survivor Rebuild Design

**Status:** Approved v1.0 on 2026-09-13

## Goal

Turn WebsitePublisher project 27912 into a clear MUNDUS game launcher while keeping each game technically isolated, then rebuild the Hārūn mobile survivor with an original in-project visual language and a gameplay/presentation cadence comparable to the supplied reference videos without copying their copyrighted art, characters, maps, names, or assets.

## Product architecture

The root `/` becomes the MUNDUS Game Hub. It never boots a game runtime directly. It exposes three active experiences and an archive area:

1. `CHRONICA HĀRŪN · 3D / FPS` → `/chronica-harun-3d.html`
2. `HĀRŪN · Cidadela das Cinzas · 2D` → `/harun-roguelite.html`
3. `HĀRŪN · Cidadela Viva · Survivor` → `/harun-survivor.html`
4. Archived builds/utilities remain available only under the Archive tab.

Each game owns its runtime, visual assets/modules, and localStorage namespace. The hub knows game metadata but never imports a game runtime.

## Safe migration

The current WebsitePublisher root game is copied byte-for-byte to `/chronica-harun-3d.html` before `/index.html` is replaced. Existing `harun-roguelite.html`, `mundus-fps.html`, and technical cleanup pages stay untouched. `survivor-lab.html` is preserved as a legacy lab while the canonical survivor page becomes `/harun-survivor.html`.

## Hub UX

The hub uses a premium dark MUNDUS presentation with tabs `JOGOS`, `EM DESENVOLVIMENTO`, and `ARQUIVO`. Each game card shows title, subtitle, platform, build state, concise description, local progress when available, and a single clear entry action. Mobile and desktop layouts must both remain readable.

## Survivor visual direction

The survivor must not load or recolor the previously imported Hārūn PNG characters. Its characters and enemies are rendered from dedicated procedural/vector drawing code inside the game project.

Target presentation:

- portrait 9:16 arena;
- stylized chibi/2.5D figures with layered body construction, silhouette, clothing, face, weapon, rim light, soft ground shadow, idle bob, walk squash/stretch, hit flash, and death feedback;
- distinct enemy families with unique shapes and movement reads;
- bosses significantly larger with telegraphs and multi-phase patterns;
- soft scene lighting, decorative edge props, floor depth, particles, trails, glowing projectiles, rings, beams, explosions, and screen feedback;
- cards enter over a dimmed arena with rarity-specific column light, border/glow, icon panel, level, and mastery state.

## Survivor gameplay cadence

The run loop is:

`move → auto-attack → survive dense wave → collect essence → level up → choose upgrade → resume instantly → difficulty spike → boss/event → next act`.

The campaign layer adds stage selection, persistent meta progression, collection/talents, rewards, and replay incentives. The first vertical slice keeps 50 waves divided into five acts, boss encounters at 10/20/30/40/50, upgrade rarity, level 1–5 mastery, synergies, pact/blessing events, persistent best-wave/victory statistics, and a campaign/meta shell.

## Reference parity targets

The supplied videos are used as behavioral/visual-reference material for cadence and presentation only. Required parity targets include:

- compact top HUD with level/XP/currency and wave milestones;
- visible joystick and low-clutter playfield;
- escalating enemy density;
- varied enemy movement and projectile behaviors;
- highly legible large VFX;
- upgrade interruption with three cards and rarity language;
- animated card reveal/light columns;
- boss warning (`DANGER`-equivalent in original MUNDUS wording), boss bar, and telegraphs;
- special post-boss events;
- reward/roulette/meta progression surfaces outside the run.

## Isolation and save keys

Suggested namespaces:

- FPS: `chronica_harun_3d_*`
- 2D roguelite: keep current `harun_*` keys for backward compatibility
- survivor canonical: `harun_survivor_v2_*`
- hub: `mundus_hub_*`

No survivor code may depend on imported character PNGs from the 2D roguelite or FPS.

## Acceptance criteria

- Opening project 27912 root shows a launcher, not a game.
- All three active games can be entered from the hub and return paths are obvious.
- The old FPS root build is preserved at its own URL before root replacement.
- Survivor canonical page does not reference `harun-peregrino-v1.png`, `harun-espectro-cinza-v1.png`, `harun-observador-cego-v1.png`, `harun-censor-cinzas-v1.png`, or `harun-vidente-sal-v1.png`.
- Survivor characters are recognizably illustrated figures, not circles/placeholders.
- Upgrade reveal, boss warning, VFX density, wave cadence, and meta surfaces visibly approach the supplied reference standard while remaining original.
- Existing Hārūn 2D and 3D games remain independently playable and unchanged except for navigation entry points.