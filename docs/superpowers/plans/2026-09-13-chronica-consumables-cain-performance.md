# CHRONICA HĀRŪN · Consumables, Cain Rite and Performance Completion Plan

> Spec: `docs/superpowers/specs/2026-09-13-chronica-consumables-cain-performance.md`
> Execution mode: inline, approved by user on 2026-09-13.
> Live target: WebsitePublisher project 27912. Mirror target: `feat/chronica-web-runtime` only. No merge to main.

## Task 1 · Characterize current production contracts

1. Re-read live page and all affected assets immediately before mutation.
2. Add deterministic contract checks for 78 Tarot entries, 21 Pharmaka, all 78 card-art indexes, Cain rite state machine, Ritual Hand capacity/persistence and required runtime effect hooks.
3. Confirm the checks expose the current failures before changing implementation: symbolic card art and incomplete local Pharmaka fallback.

## Task 2 · Restore authorized Thoth art end to end

Files: WebsitePublisher `js/chronica-card-art.js`, `js/chronica-v2.js`, UI consumers, page cache versions as needed.

1. Make `artFor()` return an authorized atlas mapping for every index 0–77.
2. Generate CSS background crop using each 13-card row atlas and exact horizontal cell position.
3. Keep symbolic rendering only as explicit load/error fallback.
4. Ensure choice UI, Ritual Hand, Ritual Collection and physical world-drop card all consume the same art manifest.
5. Validate first/last card and all 78 indexes.

## Task 3 · Guarantee all 21 canonical Pharmaka offline and in runtime

Files: WebsitePublisher `js/chronica-local-catalogs.js`, `js/chronica-pharmaka.js`, content diagnostics.

1. Replace the 14-item local fallback with the exact 21-item canonical alpha catalog.
2. Preserve canonical effect meaning; only visual appearance is shuffled per run.
3. Verify each benefit and side-effect dispatches to a real runtime hook.
4. Verify first-use identification is per-run and collection discovery/use is permanent.

## Task 4 · Close Tarot and effect API gaps

Files: `js/chronica-tarot.js`, `js/chronica-parity.js`, `js/chronica-v2.js`, `js/chronica-pocket-controller.js` only where needed.

1. Enumerate every Tarot API call and ensure `pocketEffectApi()` implements or forwards it.
2. Remove silent no-op outcomes for temporary flags such as double instrument, syzygy/art, fortify, heavy/luck/fire-aura where the card description promises an effect.
3. Keep data-driven effect families rather than 78 duplicated functions.
4. Add deterministic effect-probe diagnostics that do not write campaign progress.

## Task 5 · Cain rite and combat performance hardening

Files: `js/chronica-cain-rite.js`, `js/chronica-performance.js`, `js/chronica-v2.js`, diagnostics.

1. Preserve the current controlled reconstruction and functional labels while historical names remain unverified.
2. Verify the exact sequence: three relics → receptacle → pursuer → next safe room → witness → mark → pursuit ends.
3. Verify the pursuer cannot become an ordinary combat target.
4. Verify the 12% mark protection is applied once.
5. Verify AI scheduler, current-room-only AI, combat DPR cap, dynamic-light suppression and room culling.

## Task 6 · Runtime parity audit beyond consumables

Files: `js/chronica-parity.js`, `js/chronica-special-room.js`, `js/chronica-build-effects.js`, local catalogs and diagnostics as required.

1. Audit feature implementation by executable runtime, not JSON presence.
2. Close isolated gaps for reward pools, special rooms, relic synergies, transformations, routes, post-boss choices, unlock/completion memory, gauntlet/boss-rush analogue, endings and metaprogression only when the necessary canonical data already exists.
3. Do not copy Isaac proprietary UI/content. Use CHRONICA nomenclature and canon.

## Task 7 · Production verification and mirror

1. Re-read every mutated WebsitePublisher asset and confirm expected version hashes/content.
2. Re-read the live page and verify cache-busting points at the final asset versions.
3. Run module validators/diagnostics and confirm no contract regression.
4. Mirror the final modular source/docs to `feat/chronica-web-runtime` without merging main.
5. Report `VISUAL QA NOT VERIFIED` unless a real browser QA session becomes available.