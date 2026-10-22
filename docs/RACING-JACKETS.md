# Astrolux racing jackets

Black and white jackets use dedicated male/female racing meshes with standing collars,
front Astrolux chest logos and matching inventory icons. Item identifiers:
`TSBAstrolux.AstroluxRacingJacket` and `TSBAstrolux.AstroluxRacingJacketWhite`.

The user confirmed both installed jackets work on October 22, 2026. This checkpoint
contains that exact installed mesh/material version. Larger front-and-back prints
remain a separate, uninstalled and untested candidate and are not included here.
Pants and the white helmet are excluded from this jacket-only checkpoint.

Geometry was authored procedurally for this project. Native Project Zomboid rig,
bind matrices and animation tracks are retained for compatibility; skinning uses
up to four native bones per vertex. Model, texture and icon bytes match the tested
installation. Clothing GUID registrations are included so the native loader can
attach visuals. New jacket textures and icons were prepared with OpenAI ImageGen;
the chest emblem derives from the existing project-owned TSB Signs Astrolux artwork.

Protection, coverage and movement behavior follow native shellsuit clothing.
No new recipes, loot distribution, dealership vending, dependencies or save migration
are added. Existing installed item names and clothing GUIDs remain unchanged.

Validation: run `python tests/racing-jackets.py`. Detailed animation, layering,
multiplayer and save/reload acceptance remain pending; user confirmation establishes
that both jackets work, not exhaustive coverage of those cases.
