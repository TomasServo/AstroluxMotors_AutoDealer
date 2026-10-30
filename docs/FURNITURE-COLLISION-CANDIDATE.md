# Furniture collision candidate â€” native test pending

The Challenges demo was reported to allow kiosk/cabinet overlap and fade couches and the coffee table. This invalidates release readiness for this demo; the earlier startup acceptance alone did not establish furniture collision/rendering acceptance.

Native `IsoGridSquare.CalculateCollide` explicitly exempts `solidtrans` blocking beside window/hoppable flags. The packaged `TSBAstroluxBayCollision_2` has `solidtrans`, not `solid`. Runtime diagnostics showed these same flags at the affected kiosks/counters. Thumpable blocking flags were already enabled, so repeating those setters is insufficient evidence of a repair.

The candidate adds invisible `collideN`/`collideW` edges around owned furniture footprints using existing collision-only tiles. It does not add solid/shadow-casting helpers or change shared vanilla sprites. It reconciles on placement and periodically for ready release towers, including existing challenge saves. It defers new boundaries while a furniture square is occupied, excludes door squares and the existing low-table exception, and removes its edges when the furniture leaves. Boundaries carry the standard tower ownership tag and remain inside Delete Tower's existing scan margin.

Validation: 26 isolated Lua 5.1 regression scripts and the Fengari suite passed; the RC cleanup, exact deletion, terrain restoration, nearby deletion and power tests passed. The new test covers four boundary locations, windows, idempotence, ownership, occupancy deferral, unloaded squares, furniture movement and door/low-table exclusions. These doubles do not prove native movement or rendering.

Only the separate SP demo profile received the candidate. Its challenge saves and previous runtime file were backed up first. The frozen source and MP packages were not changed. No Workshop publication is authorized by these test results alone.

Still requires user testing: approach kiosks/cabinets from all sides, check couch/table appearance near the player, save/reload, and delete with no residual collision. Couch fading is not claimed fixed; no forced-opacity workaround has been added. Publication remains on hold pending native acceptance.

## Container access correction

User confirmed kiosk/cabinet collision and mannequin locking, but mannequin inventory was unavailable even unlocked; couches still fade. Native ISInventoryPage filters nearby containers through IsoGridSquare.canReachTo, whose wall check uses collideN/collideW. The boundary candidate therefore prevented native container access. FurnitureEdges now excludes mannequins and non-kiosk containers and removes their existing tagged boundaries on reconciliation. Native furniture collision and inventory contents remain untouched. Kiosk boundary behavior is retained. Tests cover both exclusion and cleanup. All 27 Lua 5.1 regressions pass. Cabinet collision must be rechecked; couch fading remains unresolved. This correction is not final native acceptance.
