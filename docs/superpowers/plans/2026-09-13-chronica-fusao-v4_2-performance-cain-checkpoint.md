# CHRONICA HĀRŪN · FUSÃO V4.2 · Performance + Travessia de Caim

## Estado governante
- Runtime principal: WebsitePublisher project 27912.
- Branch de espelho/código verificável: `feat/chronica-web-runtime`.
- Hārūn é personagem ficcional; autoria real: Frater Horus Phosphorus.
- O OLHO permanece percepção, nunca ataque.
- Primeira pessoa continua padrão; câmera sobre o ombro é opcional.

## Travessia das Três Relíquias
Contrato recuperado e persistido em `game/chronica-harun/web-v4/chronica-cain-rite.js`:
1. coletar três relíquias físicas;
2. encaixar as três em receptáculo/altar;
3. despertar a Presença Perseguidora;
4. atravessar sob perseguição;
5. recolher o testemunho;
6. receber a Marca de Caim;
7. encerrar a perseguição.

Os nomes históricos exatos das três peças, receptáculo, perseguidor e testemunho não foram recuperados em snapshot verificável. Não inventar nomes. A Marca funciona na dramatização como consequência, limite e proteção; o bônus de 12% de redução de dano é mecânica de jogo, não alegação histórica/espiritual.

## Performance V4.2
Hipótese isolada para o hitch no instante de manifestação: mudança de contagem de `THREE.PointLight` visíveis podia exigir nova variante/compilação de shader em pleno combate.

Política implementada em `chronica-performance.js`:
- `enemyCore` dinâmico: DESABILITADO dentro das salas de combate;
- `hitImpact` dinâmico: DESABILITADO dentro das salas de combate;
- `roomKey`: permanece permitido;
- fora de combate, efeitos compatíveis com o tier continuam permitidos.

A alteração não muda dano, hitbox, telegraph, IA, projéteis, melee, controles ou progressão.

## Anti-regressão
Arquivos:
- `game/chronica-harun/web-v4/chronica-performance.js`
- `game/chronica-harun/web-v4/chronica-diagnostic-policy.js`
- `game/chronica-harun/web-v4/chronica-diagnostics.js`
- `game/chronica-harun/web-v4/chronica-performance.test.cjs`
- `game/chronica-harun/web-v4/chronica-diagnostic-policy.test.cjs`

Invariantes:
- `enemyCore + combatRoom => false`
- `hitImpact + combatRoom => false`
- `roomKey + combatRoom => true`
- F2 diagnostics inclui `performance_combat_lights`.

## Publicação WebsitePublisher
Build publicada como FUSÃO V4.2:
- `chronica-performance.js?v=2`
- `chronica-diagnostic-policy.js?v=1`
- `chronica-diagnostics.js?v=5`
- `chronica-v2.js?v=106`

## Verificação
Testes Node executados no lote V4.2:
- syntax check de performance/policy;
- política de luzes de combate;
- invariantes do diagnóstico;
- `performance.validate()`.

Todos retornaram exit 0 no ambiente de execução do lote.

## Limite de evidência
A conexão de navegador Opera não estava autorizada no momento do lote. Portanto, até playtest gráfico/interativo real: **VISUAL QA NOT VERIFIED**.
