# Astrolux Motors

**[Wiki & Quick Start](https://github.com/TomasServo/AstroluxMotors_AutoDealer/wiki/Quick-Start)** — player and administrator guides, capabilities, troubleshooting and test-map setup. The wiki identifies its reviewed 0.9 beta candidate; that candidate includes changes beyond this main branch.

A standalone Project Zomboid Build 42 dealership with an Astrolux glass showroom, vehicle sales and trade-ins. **Pre-release testing candidate; multiplayer and final launch acceptance are pending.**

## Features

- Tabbed vehicle shopping, accessories, trade-ins, delivery-zone setup and administrator settings.
- Alphabetical vehicle families with individual variants, availability switches, model-wide prices and variant overrides. Static or persistent demand pricing; existing paint designs and compatible accessories.
- Delivery rectangles with eight facing directions, an area preview and direction arrow. Queued orders wait for loaded, clear space. New vehicles receive a matching key and empty cargo.
- Selectable trade-ins with individual appraisals. Administrators control buybacks, base value, damage deductions, required installed-parts percentage, battery exclusion, key-in-inventory requirements and hotwired vehicles. A player-made matching key is valid.
- Separate purchase sound and looping showroom music, world settings and personal volume/mute controls. Local Play/Pause controls and quieter music scaling.
- Transparent native ground floor, sliding entrances, gray bordered tiles and the approved decorative car-display tower. Published racing jackets are retained.

## Install and test

With the game closed, back up the existing mod and copy `mods/PZ_TSB_AstroluxStructure` into the Zomboid mods directory. Enable its existing mod ID, `PZ_TSB_AstroluxStructure`. No TSB Core or external framework is required. Optional bank support is discovered only when a compatible provider is present; cash works independently.

Use a backed-up disposable world first. Structure placement/cleanup tools remain restricted to the single-player debug `AstroluxStructureLab` save family. This package does not migrate the retired dealership's saved orders or balances.

See [dealership testing](docs/VENDING-TEST.md), [menu and audio](docs/DEALERSHIP-MENU-AUDIO.md), [structural acceptance](docs/STRUCTURE-ACCEPTANCE.md) and [showroom defaults](docs/SHOWROOM-DEFAULT.md).


## Optional banking for administrators

The mod package includes an [admin banking guide](mods/PZ_TSB_AstroluxStructure/docs/PRIVATE-BANK-INTEGRATION.txt) and a [private-bank adapter template](mods/PZ_TSB_AstroluxStructure/docs/examples/PrivateBankAdapter.lua.example). Start with `README-ADMIN-BANKING.txt` in the mod folder. Banking remains optional; the template is an inactive example for a separate compatibility mod.

## Development checks

Run `npm ci`, then `npm test` with Node.js. Alternatively set `TSB_LUA_CLI` to an existing Fengari CLI. The suite checks Lua syntax, structure rollback/visibility, menu startup, cash safety, delivery timing/replay, eight headings, trade-in listing, variants, demand and personal audio. Native engine, listening and multiplayer acceptance still require in-game testing.

## Release notes and assets

[CHANGELOG.md](CHANGELOG.md) is the consolidated release history. Technical evidence and asset attribution remain in [native evidence](docs/NATIVE-EVIDENCE.md), [display provenance](docs/DISPLAY-PROVENANCE.md), [depth coverage](docs/DEPTH-COVERAGE.md) and [racing jackets](docs/RACING-JACKETS.md). Audio licensing/provenance must be recorded before public Workshop distribution.

## Copyright and permissions

Copyright © 2026 TomasServo. All rights reserved.

Server administrators may install and use this mod on their servers.

Copying, modifying, redistributing, or repackaging the mod’s code or assets is not permitted without my prior written permission. Installation copies necessary to run the mod on a server are permitted.

For custom building designs, modifications, or updates needed for your server, please contact me to discuss your request.

Permission to use this mod does not include permission to create or distribute modified versions.
