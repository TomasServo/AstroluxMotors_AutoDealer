# Structural acceptance

Status: offline checks passed; the user accepted the in-game appearance on October 22, 2026. The full checklist below remains a test plan, not a claim that every check passed. Use a disposable `AstroluxStructureLab` single-player debug save.

1. Walk the perimeter. Glass must block its correct tile edges; the centered two-tile entrances remain open.
2. Enter and exit all four centered openings without invisible barriers. Sliding doors are deferred.
3. Move around and inside at several zoom levels. Inspect glass transparency, native cutaway, corners and roof hiding for flicker, triangles or missing faces.
4. Verify the native ground-floor tile pattern, glass and ceiling remain. Confirm native upper stories are removed and the car-display artwork aligns above the base. Check the approved roof and corners. The upper display has no walkable decks.
5. Save, exit and reload. Confirm floor tiles, windows, openings and collision persist.
6. Clear the whole area, including upper floors and roof. Stand outside the 11 × 11 clearance area. Right-click ground, choose **Astrolux Motors lab: remove prototype**, and confirm. Only tagged lab objects should disappear; original ground must remain. Save and reload.
7. Place again. Check for duplicate structures, leftover collision or orphaned glass.

Record game build, observations and screenshots for each failed check. Native weather enclosure and room recognition may require a map-authored structure; evaluate that from test evidence before introducing rendering workarounds.

Stairs/circulation, final styling and dealership features follow structural acceptance. Do not migrate existing dealership saves as part of this test.

The user accepted the transparent ground-floor glass, bordered gray floor and complete tower/ceiling hiding on October 22, 2026 (0.3.8). This is visual acceptance; broader checklist items remain to be verified. The tower hides within four tiles and restores beyond five tiles of the base to preempt native partial cutaway. No unsupported renderer cache API is used.
