# MUNDUS · HĀRŪN · Cidadela Viva

Survivor mobile 9:16 isolado das outras experiências de MUNDUS.

## Fonte publicada

- WebsitePublisher project: `27912`
- Rota canônica: `/harun-survivor.html`
- Laboratório legado: `/survivor-lab.html`

## Arquitetura v3

- `js/data-v3.js`: atos, inimigos, habilidades, sinergias e metaprogressão.
- `js/art-v3.js`: renderização procedural Canvas 2D; não depende dos PNGs antigos de Hārūn.
- `js/engine-v3.js`: loop, movimento, autoataque, hordas, XP, cartas, chefes, eventos e save próprio.
- `css/survivor-v3.css`: HUD 9:16, cartas, campanha, talentos, coleção e roleta.
- `index.html`: shell canônico da experiência.

## Regras de isolamento

1. Não importar sprites ou saves do roguelite 2D ou do FPS.
2. Save exclusivo: `mundus_harun_survivor_v3`.
3. `survivor-lab.html` permanece apenas como arquivo histórico.
4. Mudanças de gameplay deste diretório não entram automaticamente em `chronica-harun`.

## Referência de experiência

A direção de UX deriva dos vídeos enviados pelo usuário: arena vertical, joystick, progressão por ondas, boss warning, cartas de raridade, habilidade dominada e metaprogressão. Arte, personagens, nomes e narrativa permanecem próprios de MUNDUS.
