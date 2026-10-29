# Install the Astrolux Motors Auto Dealer demo

The demo recreates the approved furnished showroom on the existing 80×80 Astrolux lot. The original approved single-player save is also retained as an optional download.

## Automatic demo

1. Subscribe to the Astrolux Motors Auto Dealer Workshop item and wait for Steam to finish downloading.
2. In the game’s **Mods** menu enable **Astrolux Motors Auto Dealer** (`PZ_TSB_AstroluxStructure`) and **Astrolux Test Lot (Single Player Preview)** (`PZ_TSB_AstroluxTestMap`).
3. Return to the main menu and let Lua reload. Restart if prompted.
4. Select **New Game → Challenges → Astrolux Motors Auto Dealer Demo** and create a character.
5. Wait for the starting area to load. The approved showroom is constructed once, automatically.
6. Quit normally to save. Use **Load** to resume; do not start another challenge to continue the same world.

No external program, ZIP extraction, debug mode or manual paste is required for this route. The initial mannequin outfits are locked and automatic sliding doors are enabled. Reloading does not rebuild a deleted tower or reset your changes.

## Optional frozen save

Use [Astrolux Motors Auto Dealer.zip](../../bundled-saves/Astrolux%20Motors%20Auto%20Dealer.zip) when you want the actual preserved save rather than a newly generated demo world.

1. Exit Project Zomboid.
2. Extract the archive to a temporary folder.
3. Copy `Saves/Sandbox/Astrolux Motors Auto Dealer` into your own `Zomboid/Saves/Sandbox` directory.
4. Verify the final structure is `Zomboid/Saves/Sandbox/Astrolux Motors Auto Dealer/<save files>`, without an extra nested `Saves` folder.
5. Keep existing worlds intact. If that destination already exists, back it up or choose a different imported folder name; do not merge two saves.
6. Enable both matching Astrolux mods and use **Load → Astrolux Motors Auto Dealer**. If you changed the folder name, select that name instead.

Typical Windows destination: `C:\Users\YOUR-NAME\Zomboid\Saves\Sandbox`. A custom `-cachedir` launcher uses its own profile directory instead. On other systems use the `Zomboid/Saves/Sandbox` directory belonging to your game profile.

The archive contains only the preserved saved world; use the matching runtime from this checkpoint or the published Workshop release. Workshop subscribers should use the matching Workshop mods, avoiding duplicate local installations of the same mod IDs. Copying only the saved-world folder does not enable its mods automatically.

## Troubleshooting

- **Demo not listed:** enable both mods, finish Steam downloads and reload/restart the game.
- **Save not listed:** check the folder nesting and the profile used by your launcher.
- **Missing-mod warning:** verify the two mod IDs above and use the release’s matching versions.
- **Setup stopped:** retain the console log and report the error. Do not repeatedly paste over a partially constructed showroom.
- **Version compatibility:** the current candidate requires Build 42.21.0. Later Build 42 updates need compatibility checks; this is not a Build 41 save.

This workflow is for single-player. Enabling the demo mod on a multiplayer server does not automatically import the saved world or create a showroom.
