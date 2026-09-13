# CHRONICA HĀRŪN · Consumables, Cain Rite and Runtime Performance Spec

Date: 2026-09-13
Status: APPROVED DESIGN / IMPLEMENTATION BASELINE
Live deployment: WebsitePublisher project 27912
Mirror branch: feat/chronica-web-runtime

## Goal

Finish the playable web runtime so the systemic depth inspired by Binding of Isaac is expressed through CHRONICA HĀRŪN's own canon and interface, without copying Isaac assets, names, layouts, UI or proprietary identity.

## Locked invariants

- Hārūn is fictional. Real author credit remains Frater Horus Phosphorus.
- Aleppo c. 1578 remains the historical setting.
- O OLHO is perception only and never an offensive projectile.
- A physical weapon is acquired before the first mandatory combat.
- Melee reach remains approximately 1.65 m.
- There are 16 stages/themes. Peregrinus Ignis is only reached after the Câmara de Iniciação.
- First person remains the default camera; shoulder camera is optional.
- WebsitePublisher project 27912 remains the live web deployment during this work.
- All production patches use optimistic concurrency and must re-read current hashes immediately before mutation.
- User-authorized Thoth card artwork may be used. Isaac proprietary artwork/assets may not be copied.

## Ritual Hand and consumables

The runtime uses a four-slot Mão Ritual shared by Arcana and Pharmaka. Pickups are physical. When full, the player chooses a slot to replace or leaves the offered object in the world. A dropped/replaced object remains reclaimable.

Arcana are consumed on use. Permanent discovery does not grant free reuse in later runs. The permanent collection and current-run state are separate.

All 78 Thoth cards must be present: 22 Atu and 56 Minor/Court cards. Each resolves to a distinct named gameplay behavior through the data-driven Tarot effect registry. PT-BR is primary.

The six authorized atlas rows must map exactly 78 cards in canonical order, 13 cards per row. The game must use the real authorized crop in choice UI, Ritual Hand, world pickup and Ritual Collection. A symbolic fallback is allowed only on explicit asset load failure.

## Pharmaka

Exactly 21 canonical Pharmaka from the alpha contract must be available offline as well as through remote refresh. Each keeps its canonical formula/effect. Appearance is shuffled deterministically per run, not the formula itself. A Pharmakon is unknown before first consumption in a run; after use, that formula is identified for that run. Permanent collection records discovery and use separately.

## Collection

TAB opens ARCANA & PHARMAKA. It must show 78 Arcana and 21 Pharmaka even if remote content fails. Unknown entries use locked silhouettes. Discovered Arcana show authorized card art, name and effect. Discovered-but-unidentified Pharmaka remain unnamed until use. Collection persistence survives run reset.

## Cain rite reconstruction

Stage 1 contains the controlled reconstruction described by the user: collect three physical relics, assemble them in a receptacle, awaken a non-killable pursuing presence, cross under pursuit, collect the witness in the next safe room, and receive the Marca de Caim. The mark ends the pursuit and provides a 12% gameplay damage reduction.

Exact historical names of the three objects, receptacle, pursuer and witness were not found in verifiable snapshots. Until documentary recovery, functional labels are mandatory. No invented traditional entity name may be substituted.

## Performance

Combat must not run every expensive subsystem at display-frame cadence. AI uses the adaptive aiHz scheduler and updates only active enemies in the current room. Environment animation uses a lower-frequency scheduler. Combat rooms cap DPR and suppress motes/volumetrics/dynamic enemy and hit lights. Inactive-room decoration is culled. GPU materials are prewarmed where possible.

Adaptive quality uses hysteresis and must not flap tiers on short frame spikes.

## System parity completion

Runtime, not catalog existence, is the measure of completion. The audit covers: Ritual Hand, identification, loot pools, swap/drop choices, reward choices, relic synergies, transformations, secret/super-secret access, alternate-route state, post-boss choices, unlock conditions, completion memory, gauntlet/boss-rush analogue, multiple ending state and metaprogression.

Where a catalog exists but no runtime effect exists, the feature is considered incomplete.

## Verification contract

Pure modules expose deterministic validation where practical. Runtime diagnostics must validate exact catalog counts (78/21), card-art mapping, Cain state machine, performance policy and required effect API hooks. Production completion additionally requires live source re-read and no boot-contract regressions. Visual browser QA remains explicitly unverified until an actual browser session is available.