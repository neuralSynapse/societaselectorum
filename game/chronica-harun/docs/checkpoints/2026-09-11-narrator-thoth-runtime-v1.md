# CHRONICA HARUN · Checkpoint — Narrador + Presença de Thoth

**Data:** 2026-09-11
**Branch:** `feat/chronica-initiatic-roguelite-v2`

## Decisão de UX narrativa

Todo texto narrativo que aparece durante a ação deve também ser falado por um narrador. O jogador não deve ser obrigado a interromper combate, câmera ou navegação para ler conteúdo essencial.

### Contrato

- Legendas narrativas continuam visíveis.
- O narrador fala a mesma linha exibida.
- A duração da legenda é estendida para não desaparecer antes do fim estimado da fala.
- Linhas simultâneas entram em fila; uma não corta a outra.
- Mensagens curtas de sistema/combate não são narradas.
- Encontros narrativos no HUD só são narrados quando o bloco contém personagem + fala.
- Prompts de escolha são narrados; as opções permanecem para decisão do jogador com o gameplay pausado.
- Web usa `speechSynthesis` em `pt-BR`; desktop usa o TTS nativo do `DisplayServer` quando disponível.
- Ausência de voz do sistema não pode impedir o jogo de iniciar.

## Thoth

O encontro do Portal 0 / O Olho continua sendo um **Aspecto de Thoth**, uma manifestação ligada à Percepção, não um boneco técnico genérico.

O placeholder de cápsula foi substituído por uma apresentação procedural dedicada com:

- veste de escriba;
- cabeça de íbis;
- bico de íbis;
- disco lunar e halo;
- paleta lápis-lazúli, azul profundo e ouro;
- tabuinha de escrita;
- cajado de Thoth;
- iluminação própria discreta;
- identificação 3D `ASPECTO DE THOTH · PERCEPÇÃO`.

A fala preservada é: `Nomeie o que viu. Depois separe o que viu daquilo que concluiu.`

## Anti-regressão

Teste governante: `tests/test_narration_and_divine_presence_contract.py`.

A entrega só é considerada válida após testes Python, validadores, import Godot, boot, export Web, teste Chromium de visibilidade, captura visual e deploy Pages em execução fresca.
