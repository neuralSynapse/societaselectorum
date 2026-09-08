# CHRONICA HARUN · NARRATIVE INTEGRATION GUIDE

**Branch de origem:** `feat/chronica-narrative-integration`  
**Regra:** integrar depois das frentes Foundation / Combat / Roguelite, sem reescrever seus domínios.

## 1. Unidade de integração

Instanciar `res://scenes/narrative/NarrativeRuntime.tscn` no fluxo principal do jogo. O runtime contém Cosmogonia, origem de Harun, Story Director, Codex, **65 planos** cinematográficos e o sistema das **16 decisões** estratégicas.

## 2. Sinais estáveis

`NarrativeRuntimeBridge` expõe:

- `narration_lines`
- `cinematic_visual`
- `cinematic_audio`
- `story_message`
- `transition_requested`
- `story_state_saved`
- `narrative_consequence_requested`

As outras frentes consomem esses sinais. A narrativa **não editar** diretamente combate, IA, drops, rota ou regras institucionais.

## 3. Consequências das escolhas

`NarrativeChoiceDirector` persiste somente em `meta_progression["story"]["narrative_choices"]` e emite `narrative_consequence_requested(external_hook, payload)`.

A Frente C / MetaRun converte `external_hook` em modificadores mecânicos. Isso mantém o cânone separado da implementação de buildcraft e evita conflito de merge.

## 4. Gatilhos de Jornada

- `threshold`: entrada da etapa.
- `combat_1 entered`: `wound`.
- `combat_1 cleared`: `revelation` + decisão estratégica.
- salas trial/speculum/cursed/archon/historical: `inversion`.
- boss room: `boss_intro`.
- stage complete: `boss_truth` + `completion`.
- após Câmara de Iniciação: estado narrativo `PEREGRINUS_IGNIS_GAME` e epílogo de Aleppo.

## 5. Cinemática

`CinematicShotDirector` consome `shots` do Story Bible. Cada plano declara:

- duração;
- câmera;
- evento visual;
- evento de áudio;
- tensão;
- transição;
- função dramática.

A apresentação pode usar proxies durante desenvolvimento, mas não deve trocar um contrato visual por bloom genérico. O manifesto de produção está em `data/narrative/cinematic_asset_manifest.json`.

## 6. Integração com áudio

`cinematic_audio` entrega evento semântico e tensão. O AudioDirector da branch integrada decide clip, bus, spatialization e ducking. Narrativa não deve importar diretamente arquivos de áudio pertencentes à Frente B/áudio.

## 7. Integração com câmera/VFX

`cinematic_visual` entrega `shot`, `camera`, `transition` e `tension`. A camada visual resolve Camera3D, AnimationPlayer, WorldEnvironment e VFX. Narrativa não toca o camera kernel FPS usado durante gameplay.

## 8. Persistência

Toda persistência narrativa passa por `GameState.meta_progression["story"]` e `SaveService.save_campaign(GameState.to_save_data())`.

O gameplay jamais escreve certificação de Grau institucional. `PEREGRINUS_IGNIS_GAME` é somente estado narrativo do videogame.

## 9. Arquivos que a integração NÃO deve reescrever por conveniência

Não alterar automaticamente:

- `scripts/combat/**`
- `scripts/ai/**`
- `scenes/enemies/**`
- `scenes/bosses/**`
- catálogos roguelite da Frente C
- backend / Neon / Vercel
- `real_progress_gate`

Se houver conflito, adaptar a ponte narrativa, não substituir o subsistema proprietário.

## 10. Acceptance

A integração só é considerada concluída quando:

1. prólogo inicia em nova campanha;
2. primeira exibição não pode ser pulada e libera skip depois;
3. os 65 planos percorrem suas durações sem quebrar a câmera de gameplay;
4. as 16 decisões aparecem uma única vez por etapa e persistem;
5. `narrative_consequence_requested` chega ao MetaRun sem escrita institucional;
6. o epílogo dispara depois de `PEREGRINUS_IGNIS_GAME`;
7. save/load preserva cenas, fragmentos, Codex e escolhas;
8. suíte e validadores continuam verdes.
