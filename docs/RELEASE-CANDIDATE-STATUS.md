# 0.9 beta release candidate — 2026-10-29

This is a development checkpoint, not a published 0.9 beta release.

## User-confirmed multiplayer acceptance

- Paste and delete work; both halves of rugs and couches are present.
- Post-deletion debris cleared after authoritative client reconciliation.
- Mannequin outfit locks work; new towers default to locked.
- Municipal power off/on and persistence work.
- Ordinary players cannot see the Delivery Zone tab after the permissions fix.
- Non-debug test launcher and matched client/server files are available.

Automatic doors default to enabled for new towers; existing explicit settings are preserved.

## Pending before release

- Native fresh-world test of the new 80×80 SP demo, then save/reload.
- Preserved save tested with this final runtime.
- Live mixed grass/pavement terrain-restoration confirmation (mocked regression passes).
- Final packaging/version metadata and Workshop description review.
- Steam Overlay opening is explicitly deferred until after 0.9 beta.

## Lessons after the frozen checkpoint

The frozen world is the approved layout reference; its old runtime is not the final release runtime. Keep one matched version on server and clients. Restart after Lua deployment before testing checksum compatibility.

Native default removal expands multi-tile furniture groups. Exact-object operations must pass `false` when refreshing or deleting separately owned pieces. Preserve insertion order during publication. Do not infer terrain: retain and restore each tile's original sprite journal. Server deletion success alone is insufficient: clients must reconcile ownership-tagged remnants and restored floors after completion.

The checkpoint excludes server credentials, player connection profiles, diagnostic logs, machine-specific launchers and backups. The original frozen archive remains preserved outside the repository; the bundled save has unchanged world bytes.

## Automated validation

All 274 runtime Lua files parse under Lua 5.1. The legacy suite run under Lupa has 10 passing and 15 failing scripts; see LEGACY-TEST-RESULTS.json. Failures include missing game mocks/modules and assertions requiring investigation. This is not a clean full-suite pass and remains a release gate. Portable targeted deletion and terrain tests are in tests/rc (Python with lupa installed).
