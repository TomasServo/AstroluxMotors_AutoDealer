# Astrolux Motors Auto Dealer

**0.9 Beta for Project Zomboid Build 42.21.0.** Single-player release checks passed. Multiplayer remains experimental.

[Download 0.9 Beta](https://github.com/TomasServo/AstroluxMotors_AutoDealer/releases/tag/v0.9-beta) · [Install the Challenge or saved world](docs/wiki/Install-the-Demo.md) · [Project wiki](https://github.com/TomasServo/AstroluxMotors_AutoDealer/wiki)

A furnished glass showroom with vehicle sales, trade-ins, configurable pricing and delivery areas, automatic entrances, sales kiosks, mannequin controls and personal audio settings.

## Install

With the game closed, install the release's `mods/PZ_TSB_AstroluxStructure` folder into your game profile's `mods` directory. For the Challenge and bundled world, also install and enable `PZ_TSB_AstroluxTestMap`, displayed as **Astrolux Test Lot (Single Player Preview)**. Avoid duplicate local and Workshop installations.

Choose **Challenges -> Astrolux Motors Auto Dealer** for a fresh showroom. To import the supplied world, follow the [exact save-folder instructions](docs/wiki/Install-the-Demo.md); the save ZIP alone does not install its required mods. Resume through **Load** after quitting normally.

The matching saved world is [Astrolux Motors Auto Dealer.zip](https://github.com/TomasServo/AstroluxMotors_AutoDealer/raw/refs/tags/v0.9-beta/bundled-saves/Astrolux%20Motors%20Auto%20Dealer.zip). Both the Challenge and bundled world use the current tested runtime. No debug mode or manual tower paste is needed for the Challenge.

## Changes and validation

Diagonal glass movement and corner-cabinet collision are corrected for single-player. Both couches and the tables retain native interaction and draw order. The green lamp is removed. Personal Showroom Music defaults to 25%; existing personal choices and administrator levels are preserved.

Fresh placement, all four corners and entrances, furniture access, both couches, cabinet storage and save/reload passed. Thirty regression suites and five targeted suites passed; 282 runtime Lua files parse. See [release notes](docs/RELEASE-0.9-BETA.txt).

## Known beta limitations

- Faint pavement shading remains at diagonal corners; correction is deferred.
- Native furniture visibility fading remains.
- Multiplayer is experimental. The new diagonal-glass and corner-cabinet movement guards are single-player.
- Steam overlay integration remains deferred; the copy-link fallback remains available.

## Development and integration

Run `npm install`, then `npm test`, or set `TSB_LUA_CLI` to an existing Fengari CLI. Runtime bytes are preserved by `.gitattributes`. The hash manifest is in `docs/RUNTIME-SHA256.json`.

Banking is optional; cash works independently. See the main mod's `README-ADMIN-BANKING.txt` for supported integration details. This release does not claim migration of orders or balances from retired dealership implementations.

## Permissions

Copyright 2026 TomasServo. See [LICENSE](LICENSE). Third-party audio is used with permission as confirmed by the project owner. Project Zomboid and third-party assets remain the property of their respective owners.
