# Structural acceptance

Status: offline checks passed; the user accepted the in-game appearance on October 22, 2026. The full checklist below remains a test plan, not a claim that every check passed. Use a disposable `AstroluxStructureLab` single-player debug save.

1. Walk the perimeter. Closed doors and glass must block their correct tile edges.
2. Open and close all four doors. Enter and exit each without invisible barriers.
3. Move around and inside at several zoom levels. Inspect glass transparency, native cutaway, corners and roof hiding for flicker, triangles or missing faces.
4. Verify the native ground floor, doors and ceiling remain. Confirm native upper stories are removed and the car-display artwork aligns above the base. Check the approved roof and corners. The upper display has no walkable decks.
5. Save, exit and reload. Confirm decks, windows, doors and collision persist.
6. Clear the whole area, including upper floors and roof. Stand outside the 11 × 11 clearance area. Right-click ground, choose **Astrolux Motors lab: remove prototype**, and confirm. Only tagged lab objects should disappear; original ground must remain. Save and reload.
7. Place again. Check for duplicate structures, leftover collision or orphaned glass.

Record game build, observations and screenshots for each failed check. Native weather enclosure and room recognition may require a map-authored structure; evaluate that from test evidence before introducing rendering workarounds.

Stairs/circulation, final styling and dealership features follow structural acceptance. Do not migrate existing dealership saves as part of this test.
