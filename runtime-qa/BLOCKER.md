# CHRONICA HARUN · Runtime QA external blocker

- QA branch: `fix/chronica-runtime-qa`
- Godot QA binary: `4.3.stable.official.77dcf97d8`
- v4 manifest archive SHA-256: `8c5c416178c26e611d87b41fff08f718df5ccbedb2f30ddb4c153acfc11d96a7`
- v4 manifest archive bytes: `153508`
- Manifest source_head: `a558da28caa4f9b0f475e2a7e81a78c15696f415`
- Missing manifest-verifiable chunks in all reachable Git refs/history: `0`

## Missing chunks

## Consequence
The priority v4 tar.xz cannot be reconstructed according to its governing manifest. Therefore `project.godot`, pytest, Godot import, boot smoke and runtime playability cannot be truthfully executed against v4 until an exact missing chunk or the complete source archive/tree is restored.

No gameplay/runtime production files were modified by this QA branch.
