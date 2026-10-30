# 0.9 beta release candidate â€” 2026-10-29

This is a development checkpoint, not a published 0.9 beta release.

## User-confirmed multiplayer acceptance

- Paste and delete work; both halves of rugs and couches are present.
- Post-deletion debris cleared after authoritative client reconciliation.
- Mixed-terrain restoration in multiplayer passed user testing (2026-10-29).
- Mannequin outfit locks work; new towers default to locked.
- Municipal power off/on and persistence work.
- Ordinary players cannot see the Delivery Zone tab after the permissions fix.
- Non-debug test launcher and matched client/server files are available.

Automatic doors default to enabled for new towers; existing explicit settings are preserved.

## User-confirmed single-player acceptance

- New Challenges world starts successfully (2026-10-29).
- Both delivery zones exist; current saved rectangles approved as new-demo defaults.
- $25,000 starter cash, purchase and trade-in passed user testing.
- Mannequin inventory/locking and cabinet access/collision passed after corrections; kiosk collision passed.
- Native couch/table player-visibility fading explicitly accepted for 0.9 beta. This is retained engine behavior, not a claimed rendering fix.
- Approved base defaults: Normal $400, Heavy Duty $600, Sports $1,000; demand pricing enabled.

## Pending before release

- Final save/reload smoke test with the latest accepted runtime.
- Preserved save tested with this final runtime.
- Workshop upload after final native smoke tests; packaging metadata and description reviewed.
- Steam Overlay opening is explicitly deferred until after 0.9 beta.

## Lessons after the frozen checkpoint

The frozen world is the approved layout reference; its old runtime is not the final release runtime. Keep one matched version on server and clients. Restart after Lua deployment before testing checksum compatibility.

Native default removal expands multi-tile furniture groups. Exact-object operations must pass `false` when refreshing or deleting separately owned pieces. Preserve insertion order during publication. Do not infer terrain: retain and restore each tile's original sprite journal. Server deletion success alone is insufficient: clients must reconcile ownership-tagged remnants and restored floors after completion.

The checkpoint excludes server credentials, player connection profiles, diagnostic logs, machine-specific launchers and backups. The original frozen archive remains preserved outside the repository; the bundled save has unchanged world bytes.

## Automated validation

All 275 runtime Lua files parse. The 28 regression scripts (including demo defaults) now pass under both Lua 5.1 (Lupa) and the project's Fengari runner; the shared cash fixture is exercised by payment suites. The five targeted release-candidate scripts also pass. See LEGACY-TEST-RESULTS.json and LEGACY-TEST-REPAIR.md. Live demo/save acceptance remains outstanding.

## Independent audit follow-up

The audit of 87f800d identified silent 250 ms release-command throttling. Commit e71cf50 returns an explicit failure/retry message without consuming pending state. The new SP/MP regression verifies rejection, state preservation, site requests and retry at the threshold. All 28 scripts pass in Lua 5.1 and Fengari; all five Python RC scripts were rerun successfully here using the existing Lupa runtime. Cursor did not independently rerun those Python checks.
