# HĀRŪN Survivor V6 Reference Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar a V5.1 em uma V6 mobile full-screen com game feel, apresentação, familiares, boss flow, eventos e metajogo no nível do benchmark auditado, preservando identidade MUNDUS e isolamento de release.

**Architecture:** Manter V3/V4/V5 como core estável e carregar uma camada V6 modular por cima. Renderer, feel, HUD, eventos e meta ficam separados para reduzir regressões e permitir rollback simples. A RC pública será `/harun-survivor-v6.html`; a rota canônica só será promovida após gates locais e públicos.

**Tech Stack:** Canvas2D, DOM/CSS, WebAudio via `MUNDUSAudio`, localStorage, Playwright CI, WebsitePublisher.

**Spec:** `docs/superpowers/specs/2026-09-14-harun-survivor-v6-reference-parity-design.md`

## Global Constraints
- Preservar velocidade de movimento >=242.
- Não copiar assets, nomes, personagens, ícones, música, texto ou trade dress do benchmark.
- Mobile full-bleed com `100svh` e safe-area.
- Boss derrotado não reaparece na mesma onda.
- Eventos de sala nunca pausam boss wave.
- Metaprogressão é lúdica; `institutionalWrite=false`.
- Sem compra com dinheiro real.
- V5.1 permanece rollback-safe.

---

### Task 1: V6 visual renderer + full-bleed shell

**Files:**
- Create: `mundus/harun-survivor/js/art-v6.js`
- Create: `mundus/harun-survivor/css/survivor-v6.css`
- Create: `mundus/harun-survivor/v6.html`

**Interfaces:**
- Consumes: `window.HarunSurvivorArt`, `window.HarunSurvivorDebug`.
- Produces: `window.HarunV6Art={version,drawHero,drawEnemy,drawBoss,drawArena}` and `.v6-shell` styles.

- [ ] Write static gates that require `art-v6.js`, `survivor-v6.css`, `HarunV6Art`, `version:'6.0.0'`, and V6 assets in `v6.html`.
- [ ] Run static gates and verify failure before files exist.
- [ ] Implement layered 2.5D arena with wall pillars, chains, gate, torch light, floor depth, particles and vignette.
- [ ] Implement larger Hārūn silhouette with animated mantle, sash, head/hair, halo, ritual weapon, run bob and attack pose.
- [ ] Implement six enemy body families and a boss renderer with shadow, outline, hit flash and phase aura.
- [ ] Implement projectile/gem/pickup rendering with glow and trails.
- [ ] Implement mobile `100svh` full-bleed frame and safe-area CSS without hiding critical HUD.
- [ ] Run syntax/static gates and commit.

### Task 2: V6 combat feel + familiar bodies

**Files:**
- Create: `mundus/harun-survivor/js/feel-v6.js`
- Create: `mundus/harun-survivor/js/companions-v6.js`

**Interfaces:**
- Consumes: core run state, `HarunV5Systems`, `MUNDUSAudio`.
- Produces: `window.HarunV6Feel`, `window.HarunV6Companions`.

- [ ] Add failing browser assertions for normal/crit/heal/block feedback, companion count, trail canvas and boss telegraph layer.
- [ ] Implement damage text channels with scale punch and short lifetime.
- [ ] Implement impact bursts, line trails, projectile tails, poison pools, meteor telegraphs and enemy death puffs.
- [ ] Implement priority outline around Hārūn under high overlap.
- [ ] Render at least 12 visually distinct familiar bodies with formation motion and activation flashes.
- [ ] Keep familiar combat behavior from V5.1 and add audio/event telegraph hooks.
- [ ] Implement staged DANGER -> boss sigil -> boss materialization without blocking the core kill lifecycle.
- [ ] Run browser QA and commit.

### Task 3: V6 HUD, pause and cinematic choices

**Files:**
- Create: `mundus/harun-survivor/js/hud-v6.js`
- Create: `mundus/harun-survivor/js/events-v6.js`

**Interfaces:**
- Produces: `window.HarunV6HUD`, `window.HarunV6Events`.

- [ ] Add failing tests for skill-strip, full pause build grid, V6 event classes and reveal completion state.
- [ ] Recompose HUD: compact level/XP/resource bar, wave milestones, skill strip, boss priority bar and Sopro Vital.
- [ ] Build V6 pause overlay with acquired-skill icon grid, stats, continue and leave-run controls.
- [ ] Skin upgrade cards with rarity crowns/labels, large icons, concise effect text and mastery state.
- [ ] Add sequential card reveal beams, radial bursts and delayed text reveal.
- [ ] Add original event identities for Luminar blessing, Daimon pact, restorative encounter and sigilar chest.
- [ ] Add `Lv.Max` state once no skill can be upgraded.
- [ ] Run browser QA and commit.

### Task 4: V6 end-run + metagame

**Files:**
- Create: `mundus/harun-survivor/js/meta-v6.js`

**Interfaces:**
- Produces: `window.HarunV6Meta` with `open(tab)`, `state()`, `claimCheckin(day)`, `claimMission(id)`.

- [ ] Add failing tests for persisted check-in, missions, equipment slots, talent-card collection and end-run overlay.
- [ ] Implement staged victory/defeat summary with confetti, run badge, waves, chapter, damage/skills and rewards.
- [ ] Implement meta navigation: Campanha, Equipamento, Talentos, Jornada and Códice.
- [ ] Implement six equipment slots, rarity, level, inventory, filter and essence upgrade.
- [ ] Implement talent cards with stars, owned/locked state and essence-based draw.
- [ ] Implement 14-day check-in, daily/weekly missions and achievements with notification dots.
- [ ] Add energy, coin, essence and power summary to meta header; no real-money purchase flow.
- [ ] Run browser QA and commit.

### Task 5: Release candidate, public QA and canonical promotion

**Files:**
- Create: `mundus/harun-survivor/qa/playtest-v6.py`
- Create: `.github/workflows/mundus-survivor-v6-qa.yml`
- Modify: deployment docs/manifest as applicable.

**Interfaces:**
- Public RC: `https://project27912.websitepublisher.ai/harun-survivor-v6.html`
- Canonical after pass: `https://project27912.websitepublisher.ai/harun-survivor.html`

- [ ] Add Playwright gates for boot, viewport fill, movement >=242, familiar bodies, damage feedback, pause, event reveal, boss single-life lifecycle, end-run and meta persistence.
- [ ] Add 390×844 and 430×932 screenshot evidence.
- [ ] Add stress gate >=30 FPS median and compare to V5.
- [ ] Publish isolated V6 RC pinned to exact commit.
- [ ] Run public RC smoke and inspect screenshots visually.
- [ ] If green, promote canonical page to exact V6 commit and rerun public smoke on canonical.
- [ ] Record task/deployment history and keep rollback target to V5.1.
