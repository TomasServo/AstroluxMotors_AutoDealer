# Parking-width delivery placement

Version 0.6.4 retains the two-corner rectangle and its selected cardinal heading.
Ordinary cars use three tiles of width. Size comes from the loaded vehicle's
native extents and center-of-mass offset, with a quarter-tile clearance on each
side. Wider or longer vehicles receive a larger footprint. The native square's
half-tile center is included when converting that footprint to surrounding tiles.

Placement tries compact rows, then remaining integer centers in loaded map
intersections. Parked vehicles are measured through the native getWorldPos
transform used by vanilla vehicle entry, including body height for tilted cars.
Each quote, purchase and dispatch reads current parked positions and pending
reservations across kiosks. Vehicles moved away free their former space; vehicles
moved into a reservation force a queued order to find another clear position.
Saved reservations survive reload, and older larger reservations are retained.
Full loaded areas refuse a new purchase before payment. Unloaded destinations
retain the existing Lua-only queue behavior. Collision, terrain, people and
loose-object checks remain active. One outstanding order per buyer is retained;
successive delivered purchases can fill the same parking row.

Tests use real domain/selection modules with native method doubles. They cover
four Hilux purchases in a clear 14x7 rectangle (7x14 for east/west), all four
headings, concurrent quotes, mixed sizes, moved and diagonal cars, full-area
rejection, cross-kiosk reservations, queued relocation, reload and replay refusal.
Native runtime spacing, doors and movement still require an in-game test.

For that test, define a clear 14x7 north/south area. Buy four Hilux vehicles one
at a time without driving them away. Check three-tile width, body/door clearance,
headings and keys. A fifth purchase should be refused without charging. Move one
car away and verify another purchase uses the freed space. Save/reload and repeat
with a cargo van and another kiosk using an overlapping rectangle.
