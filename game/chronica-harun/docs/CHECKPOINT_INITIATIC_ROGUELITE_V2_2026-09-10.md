# CHRONICA HARUN · CHECKPOINT INICIÁTICO ROGUELITE v2

**Data:** 2026-09-10  
**Projeto:** MUNDUS · CHRONICA HARUN  
**Autor real:** Frater Horus Phosphorus  
**Branch:** `feat/chronica-initiatic-roguelite-v2`

## 1. Cadeia canônica governante

**Portal 0 · Aspirante — Initiatio Luciferi → Estudante → I · Peregrinus Ignis**

- Portal 0 · Aspirante não é Grau.
- Initiatio Luciferi é a arquitetura/rito do Portal 0.
- Portal 0 recebe os três primeiros Pergaminhos/Claves: O Olho → A Chama → A Obra.
- Estudante não é Grau e recebe doze Pergaminhos formativos.
- O primeiro Grau formal é I · Peregrinus Ignis.
- ACTUS INGRESSUS fica superado como nomenclatura governante; saves intermediários permanecem migráveis.

## 2. Graus públicos

### Arbor Vitae I–XI
I Peregrinus Ignis; II Oculus Hori; III Architectus; IV Favilla Draconis; V Sol Internus; VI Lamina Voluntatis; VII Architectus Potestatis; VIII Clavis Potestatis; IX Horus Invictus; X Aurora Lux Ferre; XI Vigil Arcani.

### Arbor Mortis XII–XXII
XII Lilith; XIII Gamaliel; XIV Samael; XV A'arab Zaraq; XVI Thagirion; XVII Golachab; XVIII Gha'agsheblah; XIX Satariel; XX Ghagiel; XXI Thaumiel; XXII Adamas Ater.

### Arbor Draconis XXIII–XXXIII
XXIII Coniunctio Arborum; XXIV Axis Serpentis; XXV Athanor Vivus; XXVI Verbum Operans; XXVII Porta Mentis; XXVIII Imperium Vocis; XXIX Clavis Commercii; XXX Aurum Potestatis; XXXI Architectus Imperii; XXXII Custos Operis; XXXIII Ipsissimus.

Arbor Draconis permanece velada no jogo até a conclusão do Grau XXII.

## 3. Corpus de Pergaminhos

- I–III: Portal 0 · Aspirante — Initiatio Luciferi.
- IV–XV: Estudante.
- XVI–XXXIII: integrações distribuídas ao longo dos 33 Graus.
- Distribuição de gameplay inicial: Graus I, III, V, VII, IX, XI, XII, XIV, XVI, XVIII, XX, XXII, XXIII, XXV, XXVII, XXIX, XXXI e XXXIII.

## 4. Preservação

Preservar: cosmogênese, origem de Harun, escolhas, Caim, Lilith, Sophia, Yaldabaoth, Nadir, Story Bible, câmera 1ª/3ª pessoa, combate, kinesis, powers/mutações, saves, salas, bosses, áudio/VFX e catálogos roguelite existentes.

A progressão digital dramatiza a arquitetura, mas não concede Grau institucional real.

## 5. Roguelite

A inspiração de The Binding of Isaac é estritamente mecânica: salas conectadas, seeds, salas secretas, pools de pickups, ativos/passivos, consumíveis desconhecidos, sinergias, bosses e builds emergentes. Não copiar identidade ou conteúdo proprietário.

Todo o catálogo existente deve ganhar presença real nas runs: Tarot de Thoth, Pharmaka, Instrumenta, Relíquias, Talismãs, Sigilla, Daimones, Blessings, Curses, Transformations, Powers, Theophanies, Historical Echoes e salas especiais.

O catálogo real do Tarot no projeto possui 78 entradas e não deve ser truncado por uma contagem informal.

## 6. UI/UX

- Escolhas narrativas com prompt, opção, custo imediato e consequência separados, sem colisão de texto.
- ESC com Retomar; Jornada/Mapa; Build & Poderes; Tarot & Pharmaka; Codex; Personagens/Marcas; Controles; Configurações; Reiniciar Run; Voltar ao título.
- Jornada mostra Portal 0, Estudante e Graus visíveis; Draconis permanece velada até Grau XXII.
- Web restaura pointer lock somente após gesto válido do usuário.

## 7. Personagens e criaturas

O roster existente passa a ter presença narrativa contextual em salas e Graus. Harun permanece protagonista padrão. Caim, Lilith, Nadir, Seth, Sabaoth, Sophia, Thoth, Hórus, Belial, Paimon e Forma Baphomética podem surgir conforme marco e rota.

Apresentação de criaturas utiliza famílias adicionais: blind_archon, mirror_wraith, ember_tyrant, stone_witness, hollow_scribe, serpentine_authority, abyssal e draconic. Bosses recebem aura e variação visual por fase.

## 8. Arquivos governantes

- Spec: `docs/superpowers/specs/2026-09-10-chronica-initiatic-roguelite-v2-design.md`
- Plano: `docs/superpowers/plans/2026-09-10-chronica-initiatic-roguelite-v2.md`
- Progressão: `data/progression/initiatic_path.json`
- Serviço: `scripts/progression/InitiaticProgressionService.gd`
- Integração: `autoload/InitiaticRuntimeIntegrator.gd`
- Teste: `tests/test_initiatic_roguelite_v2_contract.py`

## 9. Drive

Tentativas de criar ou atualizar o checkpoint no Google Drive em 10/09/2026 foram recusadas pelo provedor por quota de armazenamento excedida e, em documento mestre existente, por permissão de edição da API. O snapshot exato foi preservado no repositório para não perder decisão canônica. Um arquivo Markdown idêntico foi preparado para upload assim que a quota permitir.

## 10. Critério de entrega

Somente considerar a frente concluída com testes, validadores, Godot import, boot, captura visual, export Web e deploy frescos em verde, mais confirmação do link público da Societas servindo a build resultante.
