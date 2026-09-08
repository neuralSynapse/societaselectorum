# CHRONICA HĀRŪN · Base44 Web Handoff

Source app: `Chronica Hārūn: The Peregrinus Quest`
Base44 app ID: `6a9f74d6e7dce9ea0995ad09`

## Transfer policy

This handoff must preserve the literal Base44 app state. Do not reconstruct the game from prose and call it a migration. The next runtime may only become canonical after source/assets/config/state from Base44 are transferred or otherwise verified as equivalent.

## Current blockers

- Latest Base44 builder execution currently reports an error in ChatGPT widget state.
- External Base44 sandbox/file/shell access returns `PREMIUM_REQUIRED` and requires Builder plan.
- Base44 GitHub connector exists and is awaiting OAuth authorization.
- Non-sandbox entity inspection exposes only the built-in `User` schema.

## Next target

Floot project: `MUNDUS · CHRONICA HĀRŪN — Base44 Handoff`
Floot project ID: `a4c34ab3-61eb-4607-ade6-907511a57eb7`

The Floot project is staging-only until literal Base44 source is available. No divergent gameplay implementation should be authored there before the transfer.

## Planned literal route

1. Authorize the Base44 GitHub connector.
2. Export/persist Base44 code, assets, config and state to this branch if Base44 permits through its internal builder/connector.
3. Inventory and hash transferred files/assets.
4. Copy the literal state into Floot.
5. Verify visual and functional equivalence.
6. Create a Floot checkpoint.
7. Continue development in Floot until its real limit.
8. Repeat checkpoint/export/import/verify for the next tool.
