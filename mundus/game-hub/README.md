# MUNDUS · Game Hub

A raiz do WebsitePublisher 27912 é a central de navegação, não um runtime de gameplay.

## Rotas ativas

| Experiência | Rota | Estado |
| --- | --- | --- |
| CHRONICA HĀRŪN · 3D/FPS | `/chronica-harun-3d.html` | ativa, Fusão v3.6 |
| HĀRŪN · Cidadela das Cinzas · 2D | `/harun-roguelite.html` | ativa |
| HĀRŪN · Cidadela Viva · Survivor | `/harun-survivor.html` | ativa, v3 |

## Arquivo

- `/mundus-fps.html`
- `/survivor-lab.html`
- `/fusion-v22-clean.html`

## Regra anti-regressão

A homepage `/` só apresenta e roteia. Nenhum jogo deve carregar seus scripts, save ou assets globais na Central. Cada experiência mantém namespace e persistência próprios.
