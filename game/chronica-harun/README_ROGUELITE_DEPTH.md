# CHRONICA HARUN · Roguelite Depth

Implementação isolada da Frente C em Godot 4, dedicada a buildcraft, salas especiais, segredos, rotas, transformações e metarun. Esta pasta não substitui narrativa, combate, inimigos nem backend.

## Runtime

- `autoload/RogueliteContentService.gd`: carrega e indexa os catálogos.
- `scripts/content/BuildResolver.gd`: resolve custos, stacking, exclusões, sinergias e efeitos.
- `scripts/generation/SpecialRoomDirector.gd`: seleciona salas, limita segredos a dois e governa pós-boss.
- `scripts/rooms/SpecialRoomRuntime.gd`: aplica entrada, custo, risco, recompensa e estado de descoberta.
- `scripts/progression/MetaRunDirector.gd`: rotas, maldições, bênçãos, transformações, completion marks e gauntlets.
- `autoload/GameState.gd`: estado serializável e save/load local em JSON.
- `scripts/boot/DepthRuntimeSmoke.gd`: smoke end-to-end sem combate ou inimigos.

## Catálogos materializados

O gerador `tools/generate_roguelite_catalogs.py` produz os JSON canônicos de runtime para Tarot, Sigilla, Pharmaka, Talismãs, Instrumenta, Poderes-Matriz, Mutações, Daimones, Relíquias, Transformações, Maldições, Bênçãos, Rotas, Salas Especiais e Gauntlets.

## Verificação

```bash
python game/chronica-harun/tools/generate_roguelite_catalogs.py
pytest -q game/chronica-harun/tests
godot --headless --path game/chronica-harun --editor --quit
godot --headless --path game/chronica-harun res://scenes/boot/DepthRuntimeSmoke.tscn
```

O smoke deve imprimir `DEPTH_RUNTIME_SMOKE_OK` e sair com código 0.

## Anti-regressão

- Nenhuma escrita institucional ou `real_progress_gate` é permitida neste módulo.
- Segredos não recebem portas rotuladas como segredo e exigem abertura física compatível.
- Até duas salas secretas podem existir por andar quando o layout suporta.
- Pós-boss usa escolhas condicionais mutuamente exclusivas.
- Conteúdo autoral sem proveniência histórica fixada permanece marcado como `dramatizacao_electorum`.
- Esta branch não faz merge automático em `main`.
