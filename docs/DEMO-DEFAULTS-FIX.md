# Demo defaults repair — 2026-10-29

DemoReady now uses the explicit AstroluxMotorsDemo challenge ID and TSBAstroluxDemoScenario.v1 recordId instead of requiring the old test save name. The previous legacy save route remains supported.

The approved template kiosks are at tower offsets (3,0) and (8,0). Delivery rectangles retain the original demo geometry, translated with the tower: (-2,-15) through (12,-5), south-facing; and (16,-1) through (25,16), west-facing. Neither intersects the tower footprint.

Setup waits for both kiosks and ready furnishings, does not overwrite existing zones, and does not recreate zones deliberately cleared after initialization. Other challenges, ordinary worlds, multiplayer, foreign towers and held orders are excluded. The existing native $25,000 cash grant is now reachable for the challenge; it retains per-character progress and uncertain-insertion holds.

Regression covers exact scope, full preparation before mutation, edited zones, power gating, 250 $100 bundles, reload, partial batch continuation and interrupted insertion. All 25 Lua regression scripts pass under Lua 5.1 and Fengari. Native acceptance remains with the user.

The separate SP demo profile is updated. Existing challenge saves can be loaded; no repaste is required. The frozen source archive and deployed MP files were not modified.
