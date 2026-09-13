# HĀRŪN Survivor V5 · Epic Systems Design

## Goal
Elevate Cidadela Viva from a wave survivor into a room-driven ritual roguelite-survivor with persistent MUNDUS identity, while preserving the existing mobile 9:16 combat core.

## Canon progression
1. Pré-Ingressus: O OLHO → A CHAMA → A FUNDAÇÃO → Ritual Inicial Básico.
2. INGRESSUS: Pergaminho I · Heru-pa-khered (Hórus Criança) → Pergaminho II · Heru-sa-Aset → Pergaminho III · Heru-Behdeti → Ritual do ACTUS INGRESSUS.
3. ESTUDANTE: 12 Pergaminhos — A Eleição, A Balança, A Vontade, O Caráter, A Disciplina, A Clareza, A Transmutação, O Corpo, A Obra, A Fortuna, A Influência, O Legado — com rito de selamento por Pergaminho e rito final de passagem.
4. Graus I–XXXIII permanecem lúdicos; Estudante não é Grau; Grau I = Peregrinus Ignis; XXXIII = Ipsissimus; conteúdo institucional reservado continua selado.
5. Grafia canônica: CAIM.

## Runtime systems
- Music/SFX always-on after first user gesture through shared MUNDUS Audio Core; music, SFX, UI and ambience have separate logical channels.
- ESC opens Livro Negro instead of a bare pause; TAB expands the current floor map.
- Permanent minimap shows current room, discovered rooms and special rooms.
- Procedural non-repeating floor graph per traversal, with room types inspired by roguelite grammar but original MUNDUS content: arena, Relicário, Mercatorium, Scriptorium, Pacto, Sacrifício, Trono, Provação, Fortuna, Observatorium, Cofre Sigilar, Câmara Velada, Câmara de Repouso and Fenda.
- Room transitions vary by narrative context: trapdoor/descent, portal, ascent, sky passage, mirror, dimensional rift, throne gate, solar passage.
- 78 Thoth cards with per-run no-repeat draw pool; selecting one immediately dismisses the other choices.
- Families of Familiars, Seres, Daimons and Pactos with distinct benefits/costs and Livro Negro registry.
- Loot exists in-world: XP, coins/essence, keys/fragments, cards, relics, companions, pacts and MAGNES ELECTORUM; magnet pulls all collectible XP/currency/drop entities to Hārūn.
- Stage-specific enemy ecology. Initial approved roster candidates are encoded for O Olho, A Chama and A Fundação; later stages derive pools from phase/order/theme rather than one universal enemy pool.
- Faster player locomotion and tighter combat cadence than V4.

## Cross-game contract
- CHRONICA 3D, Roguelite 2D and Survivor should share MUNDUS audio conventions and persistent music after user gesture.
- Systems are reused conceptually, never by copying copyrighted Isaac art, item names, layouts or text.
- `institutionalWrite=false` remains mandatory in public game state.

## QA gates
- No JS page errors.
- ESC opens Livro Negro during a run and resumes safely on close.
- TAB expands/collapses map.
- 78 tarot definitions, no duplicate draw within a run, unchosen cards disappear immediately.
- Floor layouts and room IDs are unique within a generated traversal.
- Audio context becomes running after a user gesture and music state follows menu/combat/boss/ritual.
- Movement speed is materially higher than V4 baseline.
- Magnet collects all current gem/currency drops.
- Mobile 390×844 has no horizontal overflow.
- Stress test remains >=45 FPS on CI reference runner.
