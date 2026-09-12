# CHRONICA HĀRŪN Ritual Pocket / Arcana / Pharmaka Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar Bolso Ritual compartilhado, 78 Arcana consumíveis, 21 Pharmaka identificáveis, coleção persistente e integração ao runtime web de CHRONICA HĀRŪN, preservando o cânone e removendo Caim dos rosters inimigos.

**Architecture:** Criar módulos JS focados e testáveis, mantendo `chronica-v2.js` como runtime 3D e `chronica-parity.js` como ponte, mas retirando deles a responsabilidade de estado de consumíveis. Dados vêm dos catálogos canônicos da alpha; UI usa um manifesto de assets sem falsificar arte ausente.

**Tech Stack:** JavaScript ES2020, localStorage, DOM/CSS, WebsitePublisher project 27912, Three.js runtime existente, Node.js para testes puros dos módulos.

**Spec:** `docs/superpowers/specs/2026-09-12-chronica-ritual-pocket-arcana-pharmaka-design.md`

## Global Constraints

- PT-BR é o idioma padrão; inglês continua opcional.
- Caim é iniciador canônico e nunca inimigo genérico.
- O OLHO permanece percepção, nunca projétil.
- Não copiar assets/nomenclatura/UI proprietários de Binding of Isaac.
- Sem alegar arte Thoth real sem arquivo autorizado identificado.
- Catálogo sem caminho de runtime não conta como implementado.
- Alterações no WebsitePublisher usam leitura atual + `version_hash` antes de patch.

---

### Task 1: Canon Guard para Caim

**Files:**
- Create: `web/tests/chronica-canon-guard.test.cjs` (local TDD staging)
- Modify: `js/chronica-traditional-rosters.js` no WebsitePublisher

**Interfaces:**
- Produces: `CHRONICA_TRADITIONAL_ROSTERS.rosters` sem `cain_archon`/`Cain` em inimigos ou bosses.

- [ ] **Step 1: Write the failing test**
```js
const assert = require('node:assert/strict');
const rosters = require('./fixtures/traditional-rosters.json');
const flat = JSON.stringify(rosters).toLowerCase();
assert.equal(flat.includes('cain_archon'), false);
assert.equal(/"cain"/.test(flat), false);
```
- [ ] **Step 2:** Run `node web/tests/chronica-canon-guard.test.cjs`; expected FAIL against current roster.
- [ ] **Step 3:** Replace Caim slot with a documented non-Caim authority/entity while preserving six encounters for stage 3.
- [ ] **Step 4:** Re-run test; expected PASS.
- [ ] **Step 5:** Read back WebsitePublisher asset and verify Caim absent from roster declarations.

### Task 2: Pure Ritual Pocket State Module

**Files:**
- Create: `js/chronica-consumables.js`
- Create: local `web/tests/chronica-consumables.test.cjs`

**Interfaces:**
- Produces: `CHRONICA_CONSUMABLES.create(storage)` with `getPocket()`, `offer(item)`, `swap(item)`, `consume(handler)`, `discover(item)`, `identifyPharmakon(id)`, `isIdentified(id)`, `collection()`.

- [ ] **Step 1:** Write failing tests for empty pocket, pickup, occupied offer, swap, consume, run identification and persistent discovery.
- [ ] **Step 2:** Run tests and confirm failures are from missing module/API.
- [ ] **Step 3:** Implement minimal module with separate run-state and persistent collection keys.
- [ ] **Step 4:** Run tests; all PASS.
- [ ] **Step 5:** Refactor only after green.

### Task 3: Arcana Runtime Effects

**Files:**
- Create: `js/chronica-tarot.js`
- Create: local `web/tests/chronica-tarot.test.cjs`

**Interfaces:**
- Consumes: canonical `tarot_thoth.json` shape.
- Produces: `CHRONICA_TAROT.effectFor(card)` and `apply(card, api)`.

- [ ] **Step 1:** Write failing tests proving distinct behavior for at least Fool, Magus, Priestess, Empress, Chariot, Death, Tower, Sun, Aeon and Universe.
- [ ] **Step 2:** Verify RED.
- [ ] **Step 3:** Implement effect dispatcher covering every `effect_id` in the 78-card catalog, with explicit fallback error for unknown IDs.
- [ ] **Step 4:** Verify all 78 catalog entries resolve to an effect handler.
- [ ] **Step 5:** Verify GREEN.

### Task 4: Pharmaka Runtime + Identification

**Files:**
- Create: `js/chronica-pharmaka.js`
- Create: local `web/tests/chronica-pharmaka.test.cjs`

**Interfaces:**
- Consumes: canonical `pharmaka.json` shape.
- Produces: `displayName(item,{identified})`, `apply(item,api)`, `appearanceSeed(runSeed,item)`.

- [ ] **Step 1:** Write failing tests for benefit + side effect, unidentified label, stable run appearance, and post-use identification.
- [ ] **Step 2:** Verify RED.
- [ ] **Step 3:** Implement all benefit/side-effect vocabulary used by the 21 catalog entries.
- [ ] **Step 4:** Verify every catalog entry maps without fallback.
- [ ] **Step 5:** Verify GREEN.

### Task 5: Collection / Archive UI

**Files:**
- Create: `js/chronica-collection.js`
- Modify: `index.html`
- Modify: `css/chronica-v2.css`

**Interfaces:**
- Consumes: `CHRONICA_CONSUMABLES.collection()` and canonical catalogs.
- Produces: modal grid with tabs `ARCANA`, `PHARMAKA`; discovered items visible; unknown items masked.

- [ ] **Step 1:** Write DOM-free renderer tests for discovered/unknown card models.
- [ ] **Step 2:** Verify RED.
- [ ] **Step 3:** Implement renderer and collection modal.
- [ ] **Step 4:** Add keyboard access and close behavior without breaking pointer lock restoration.
- [ ] **Step 5:** Verify renderer tests + read-back HTML/CSS.

### Task 6: Asset Manifest for Authorized Thoth Art

**Files:**
- Create: `data/arcana-art-manifest.json`
- Create: `js/chronica-card-art.js`

**Interfaces:**
- Produces: `artFor(cardId)` returning `{status:'authorized'|'missing', url, alt}`.

- [ ] **Step 1:** Write failing test that missing art never returns a fabricated “real” image.
- [ ] **Step 2:** Verify RED.
- [ ] **Step 3:** Implement manifest resolver and fallback card back.
- [ ] **Step 4:** Populate only assets actually located/authorized; leave others `missing`.
- [ ] **Step 5:** Verify GREEN.

### Task 7: Integrate Pocket Into 3D Runtime

**Files:**
- Modify: `js/chronica-v2.js`
- Modify: `js/chronica-parity.js`
- Modify: `index.html`
- Modify: `css/chronica-v2.css`

**Interfaces:**
- Pickup -> `CHRONICA_CONSUMABLES.offer`.
- Use -> current pocket dispatcher -> Tarot/Pharmaka module -> consume.
- HUD -> pocket icon/name/identified state.

- [ ] **Step 1:** Add integration tests around a fake game API for pickup/use/consume/swap.
- [ ] **Step 2:** Verify RED.
- [ ] **Step 3:** Replace permanent Arcana assignment flow with pocket flow while preserving existing stage reward systems.
- [ ] **Step 4:** Add Pharmaka drops/choices from real catalog and identification on use.
- [ ] **Step 5:** Verify tests, syntax and asset read-back.

### Task 8: Performance and Regression Verification

**Files:**
- No new production file required.

- [ ] **Step 1:** Run all local Node tests for new modules.
- [ ] **Step 2:** Parse all updated JS with `node --check`.
- [ ] **Step 3:** Re-read WebsitePublisher page/assets and verify version hashes match uploaded content.
- [ ] **Step 4:** Verify index still loads `chronica-v2.js`, never `harun-roguelite.js`.
- [ ] **Step 5:** Verify Caim absent from enemy rosters, present only in appropriately separated lore/iniciation context.
- [ ] **Step 6:** If browser connector is unavailable, report literal `VISUAL QA NOT VERIFIED`.
