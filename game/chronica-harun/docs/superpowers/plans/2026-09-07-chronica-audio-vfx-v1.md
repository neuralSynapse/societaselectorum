# CHRONICA HARUN · Audio + VFX + Combat Feedback Plan

> Branch: `feat/chronica-audio-vfx-v1`
> Base: `feat/chronica-combat-v2` @ `4342dcdaf154de952620208ca36f1ab0e76b228e`

## Goal

Elevar somente o feedback audiovisual de gameplay sem alterar IA, narrativa, progressão, backend ou o contrato de combate. O resultado deve manter projéteis ranged visíveis e fisicamente viajantes, com a sequência `windup → telegraph → emission → travel → impact`, áudio espacial seguro e VFX legíveis com bloom mínimo.

## Architecture

- `AudioDirector` permanece autoload e passa a resolver todo ID usado para asset instalado ou fallback procedural original.
- `VFXDirector` será um autoload leve e puramente visual, com efeitos procedurais temporários e orçamento de emissão explícito.
- Sistemas existentes somente recebem hooks de feedback, sem reescrita de comportamento.
- `ReadableProjectile` continua sendo a autoridade do dano ranged no impacto físico.
- Assets procedurais serão classificados como `placeholder`; nenhum asset protegido de terceiros será incorporado.

## Tech Stack

Godot 4.3, GDScript, AudioStreamWAV procedural, MeshInstance3D/GPUParticles3D, pytest, GitHub Actions.

## Spec

### Audio
- Resolver ou fornecer fallback para todos os IDs SFX usados.
- IDs conhecidos nunca podem causar erro nem impedir boot.
- Áudio 3D para combate, impactos, chefes, pickups e rupturas.
- Status de proveniência consultável: `final`, `candidate`, `placeholder`.

### VFX
- Deep black, burnt gold e ritual red.
- Emissão limitada, sem glow de tela inteira.
- Telegraphs sem emissão ou dentro do cap estabelecido.
- Projétil com núcleo visível e trail renderizável independente da câmera.

### Hooks
- primary attack, RMB power, Kinesis, Instrumenta, Tarot.
- enemy windup/telegraph/projectile/hit/death.
- projectile travel/impact.
- boss windup/attack/phase/death.
- pickup, secret rupture e special-room activation.

## Global Constraints

- Não fazer merge.
- Não alterar IA, narrativa, progressão ou backend.
- Não alterar catálogos roguelite além de hooks VFX/SFX já previstos.
- Não criar dano instantâneo em ataques ranged.
- Não usar áudio protegido de terceiros.

## Tasks

- [ ] Estabelecer CI próprio da frente G sobre a branch exclusiva.
- [ ] Escrever testes RED para resolução SFX, fallback, cap de emissão, projétil e boss phase feedback.
- [ ] Implementar fallback procedural seguro no AudioDirector.
- [ ] Implementar VFXDirector procedural e orçamento visual.
- [ ] Tornar trail do projétil realmente renderizável e manter travel físico.
- [ ] Conectar hooks de player, inimigos, bosses, pickups, secrets e salas especiais.
- [ ] Documentar classificação final/candidate/placeholder.
- [ ] Rodar pytest completo, validators, Godot 4.3 import, boot e runtime probe.
- [ ] Confirmar warnings restantes e HEAD final sem merge.
