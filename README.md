# Astrolux Motors

Glass tower rebuild for Project Zomboid Build 42. Structure first; dealership features will follow structural acceptance.

This repository currently contains **Structure Lab 0.3.8**, an isolated prototype using native glass, doors and floors. It does not replace or migrate the previous `PZ_TSB_AutoVend` mod. Existing vehicles, paid orders, balances and saved data must be preserved when dealership features are added later.

## Current structure

- Transparent 8 x 8 ground floor with two-tile openings centered on all four sides and an intact ceiling at z=1.
- Previous approved-roof Astrolux car-display artwork above that base.
- Upper native stories removed; 404 decorative slices preserve the previous image and anchors.
- Native gray square-tile floor with a dark gray border. Original floor state is retained for lab cleanup. No external runtime dependency or dealership code.

The base reuses the previous project transparent glass under isolated sprite names. Sliding doors are deferred; all eight centered entrance tiles are intentionally open. Existing tagged intact panes convert on the next lab load without repairing altered panes.

The upper display is artwork, not walkable floors or actual vehicles. Kiosks, lighting and sales remain deferred. The approved left AC remains; the removed roof structures stay removed.

Existing lab prototypes convert once on the next debug lab load if the site is clear and player is nearby, outside the footprint. The conversion preserves the ground-floor objects and ceiling, rejects foreign objects or occupants and rolls back construction failures. Use the context-menu conversion option if the automatic attempt is deferred. The user accepted the resulting in-game appearance on October 22, 2026.

## Test installation

Close the game. Copy `mods/PZ_TSB_AstroluxStructure` into your Zomboid `mods` directory. Back up and compare any existing version before replacing it.

Create a disposable **single-player debug save** named `AstroluxStructureLab` (an optional suffix is allowed). Enable **Astrolux Motors - Structure Lab** for that save. Use the prototype on its own for the first test. Existing worlds and their mod selections should remain unchanged.

The placement and cleanup tools reject multiplayer and other save names. In the lab, stand outside a clear 11 × 11 area, within 30 tiles of the intended northwest interior corner. Right-click that ground tile, choose **Astrolux Motors lab: preview structure here**, and confirm the coordinates. Preview validates the site and opens a confirmation; it does not draw a ghost tower.

The entire clearance area must be loaded outdoor solid ground, without people, animals, bodies, dropped items or objects other than existing ground floors. Move vehicles well away. Placement rechecks the site before building. Cleanup removes only tagged prototype objects and refuses occupied or modified sites.

See [structural acceptance](docs/STRUCTURE-ACCEPTANCE.md) before adding detail.

## Validation status

Offline Lua checks pass for perimeter continuity, floor layout, four doors, lab isolation, obstruction rejection, placement revalidation, duplicate prevention, cleanup and simulated construction/rollback failures. Engine doubles exercise persistence of ownership across a Lua module reload.

**The user accepted the in-game appearance on October 22, 2026.** Comprehensive door/collision, weather enclosure, room recognition, roof cutaway, pathfinding, cleanup and save/reload checks remain pending. Multiplayer is unsupported by this prototype.

The user also confirmed the window/roof triangle fix in-game on October 22, 2026. Version 0.2.1 supplies explicit native depth coverage for all 404 display slices, keeping the approved artwork and placement unchanged. See [depth coverage](docs/DEPTH-COVERAGE.md).

## Run checks

With Node.js installed:

```sh
npm install
npm test
```

Fengari is a development dependency only; it is not part of the game mod. A Lua interpreter can also run `lua tests/structure.lua` from the repository root.

## Provenance

The previous mod was set aside before this rebuild. Its verified published reference was [`62449fc`](https://github.com/TomasServo/PZ_TSB_AutoVend/commit/62449fc011b82ab0e61ba18c1230c703df34b107). This repository publishes only the new structural prototype, its tests and documentation. Only the approved tower artwork and reused project glass assets are included with the structural prototype; backups, saves, logs, credentials and development dependencies are excluded.

See [native implementation evidence](docs/NATIVE-EVIDENCE.md).

The user accepted the transparent glass, gray floor with dark border, and complete tower/ceiling cutaway in-game on October 22, 2026. Version 0.3.8 hides the decorative tower and its native ceiling together within a four-tile entrance buffer, restoring beyond five tiles to avoid boundary flicker. This deliberately hides the tower before footprint entry. Sliding doors, multiplayer, weather enclosure and the full acceptance checklist remain unverified. The 0.2.1 triangle fix remains confirmed.
