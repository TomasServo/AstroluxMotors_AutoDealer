# Demo defaults repair â€” 2026-10-29

DemoReady now uses the explicit AstroluxMotorsDemo challenge ID and TSBAstroluxDemoScenario.v1 recordId instead of requiring the old test save name. The previous legacy save route remains supported.

The approved template kiosks are at tower offsets (3,0) and (8,0). The user-approved delivery rectangles captured from the challenge save are (-1,-13) through (14,-3), south-facing, gap 1 / row gap 1; and (16,-1) through (25,16), west-facing, gap 1 / row gap 0. At tower (118,121), these are (117,108)â€“(132,118) and (134,120)â€“(143,137). Neither intersects the tower footprint. These now initialize new demos; existing zone edits remain untouched.

Setup waits for both kiosks and ready furnishings, does not overwrite existing zones, and does not recreate zones deliberately cleared after initialization. Other challenges, ordinary worlds, multiplayer, foreign towers and held orders are excluded. The existing native $25,000 cash grant is now reachable for the challenge; it retains per-character progress and uncertain-insertion holds.

Regression covers exact scope, full preparation before mutation, edited zones, power gating, 250 $100 bundles, reload, partial batch continuation and interrupted insertion. All 25 Lua regression scripts pass under Lua 5.1 and Fengari. Native acceptance remains with the user.

The separate SP demo profile is updated. Existing challenge saves can be loaded; no repaste is required. The frozen source archive and deployed MP files were not modified.

User acceptance on 2026-10-29: both delivery zones present, $25,000 grant successful, vehicle purchase successful, trade-in successful. This does not establish acceptance of the outstanding furniture rendering/collision and mannequin-setting corrections.

User-approved class-price defaults: Normal $400, Heavy Duty $600, Sports $1,000. Demand pricing remains the default (Static Pricing unchecked). Existing saved admin overrides are retained. Mannequin inventory/locking and cabinet access/collision were subsequently confirmed working by the user; couch fading remains unresolved.
