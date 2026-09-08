# CHRONICA HARUN · Desktop Release QA

## Automated/static status

Python contract tests and the complete static validator are executed in this workspace.

## Runtime status

**Godot headless: não executado neste ambiente**, porque nenhum binário `godot`/`godot4` está instalado e o ambiente de container não possui resolução externa para baixar uma build. Isso impede afirmar importação, compilação GDScript, física, render, áudio ou frame-time como validados em runtime.

## Runtime acceptance gate

Quando um Godot 4 compatível estiver disponível, executar import e headless, abrir a cena principal, validar primeira pessoa, mouse look não invertido, colisões, movimento, projéteis visíveis, telegraph/windup/impact/recovery, enemies em world-space, bosses em três fases, salas secretas por Carga de Ruptura, salas especiais, teofanias, save/load, retry, progressão e performance.

A meta é 60 FPS em 1080p no preset base. 1440p e 4K são presets de qualidade, não promessa de performance universal. O pipeline visual final continua Blender -> GLTF/GLB -> Godot; placeholders procedurais não são rotulados como “arte final 8K”.
