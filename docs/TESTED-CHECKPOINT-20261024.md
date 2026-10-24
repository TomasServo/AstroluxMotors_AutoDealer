# Astrolux Motors Auto Dealer: tested checkpoint

The user confirmed the current local build works on October 24, 2026 and requested publication. This updates the existing audit branch, not a tagged beta or Workshop release. Earlier progress documents describe historical intermediate states; this document records the latest checkpoint.

## Included

- Current installed consolidated mod, with stable runtime IDs and the display name Astrolux Motors Auto Dealer.
- Settings for entrance/window conversion, associated rugs, mannequin outfit locking and coffee restock enablement.
- Furniture selection/information, native rotation retention for chairs, lamps and mannequins, and rug facing fixes.
- Showroom glass/floor/collision and lamp updates; music coverage and delivery-border corrections.
- Updated kiosk and entrance panels; approved cyan car/ASTROLUX, amber orbit/star and red MOTORS artwork on the independent neon sign and matching rug.
- Entrance rug removal/restoration, including the reported south entrance boundary case. Both adjacent native rug pieces follow the toggle; ownership, ambiguity, loading and rollback guards remain.

The runtime snapshot manifest records 247 installed files before Git line-ending normalization. Repository-only banking documentation and the compatibility shim are preserved. No saves, logs, backups or dependencies are included. The separately staged square-ceiling-light migration is not included.

## Validation and limits

- All current runtime Lua files parse.
- Asset registration/consolidation checks pass.
- Structural and conversion tests pass up to the legacy suite's existing menu test harness failure: missing TSBAstroluxVend/ContextMenu in the harness search path. The full legacy suite is not passing and did not complete.
- Portable `tests/entrance-admin.lua` covers four entrance toggles, ownership, occupied-door rejection, complete rug hide/restore, missing/unloaded parts, rollback, south lateral overlap, all four threshold overlaps and disconnected-grid rejection.
- Native sign/rug pack metadata and rug alpha coverage were checked during preparation; working rug cursor, rotation and floor-depth files were preserved by the artwork update.
- User's latest in-game acceptance covers the local test build; this is not evidence of multiplayer, arbitrary-map deployment or exhaustive economy/transaction validation.

The tower still has single-player debug-lab restrictions and historical migration handlers. Temporary furniture/rug/pickup diagnostics remain in the accepted snapshot for the audit to assess. Shared furniture compatibility should eventually move to Core with the Astrolux copy removed, not duplicated. Do not remove native helper definitions without a saved-object migration plan.

Review the existing Cursor audit brief before release. Retain the current accepted build as the review baseline and report findings before changing behavior.
