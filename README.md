# Astrolux Motors

Glass tower rebuild for Project Zomboid Build 42. Structure first; dealership features will follow structural acceptance.

This repository currently contains **Structure Lab 0.1.0**, an isolated prototype using native glass, doors and floors. It does not replace or migrate the previous `PZ_TSB_AutoVend` mod. Existing vehicles, paid orders, balances and saved data must be preserved when dealership features are added later.

## Current structure

- 8 × 8 interior, five levels at z=0–4 and a solid roof at z=5.
- Native full-height commercial glass on every level.
- Four native single glass doors and matching frames on the ground floor.
- Original ground preserved; 320 upper-floor/roof tiles.
- No giant artwork overlay, custom depth maps, forced transparency or external runtime dependencies.

No stairs yet: inspect upper levels using debug movement. Cars, kiosks, signs, lighting and sales are deferred. Native glass is the first test material, not the final visual design.

## Test installation

Close the game. Copy `mods/PZ_TSB_AstroluxStructure` into your Zomboid `mods` directory. Back up and compare any existing version before replacing it.

Create a disposable **single-player debug save** named `AstroluxStructureLab` (an optional suffix is allowed). Enable **Astrolux Motors - Structure Lab** for that save. Use the prototype on its own for the first test. Existing worlds and their mod selections should remain unchanged.

The placement and cleanup tools reject multiplayer and other save names. In the lab, stand outside a clear 11 × 11 area, within 30 tiles of the intended northwest interior corner. Right-click that ground tile, choose **Astrolux Motors lab: preview structure here**, and confirm the coordinates. Preview validates the site and opens a confirmation; it does not draw a ghost tower.

The entire clearance area must be loaded outdoor solid ground, without people, animals, bodies, dropped items or objects other than existing ground floors. Move vehicles well away. Placement rechecks the site before building. Cleanup removes only tagged prototype objects and refuses occupied or modified sites.

See [structural acceptance](docs/STRUCTURE-ACCEPTANCE.md) before adding detail.

## Validation status

Offline Lua checks pass for perimeter continuity, floor layout, four doors, lab isolation, obstruction rejection, placement revalidation, duplicate prevention, cleanup and simulated construction/rollback failures. Engine doubles exercise persistence of ownership across a Lua module reload.

**In-game acceptance is pending.** These checks do not establish actual collision, rendering, weather enclosure, room recognition, roof cutaway, pathfinding or save/reload behavior. Multiplayer is unsupported by this prototype.

## Run checks

With Node.js installed:

```sh
npm install
npm test
```

Fengari is a development dependency only; it is not part of the game mod. A Lua interpreter can also run `lua tests/structure.lua` from the repository root.

## Provenance

The previous mod was set aside before this rebuild. Its verified published reference was [`62449fc`](https://github.com/TomasServo/PZ_TSB_AutoVend/commit/62449fc011b82ab0e61ba18c1230c703df34b107). This repository publishes only the new structural prototype, its tests and documentation. No old tower artwork, backups, saves, logs, credentials or development dependencies are included.

See [native implementation evidence](docs/NATIVE-EVIDENCE.md).
