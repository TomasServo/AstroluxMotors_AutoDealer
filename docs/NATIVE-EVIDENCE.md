# Native implementation evidence

Inspected the installed game's Lua and `media/newtiledefinitions.tiles` on October 22, 2026, before implementing the prototype. Game assets were read without modification. The package references native sprite names; it does not redistribute vanilla pixels or tile definition binaries.

| Native sprite | Relevant properties |
| --- | --- |
| `walls_commercial_01_0` | `windowW`, `WindowW`, `wall`, glass material; native smashed/glass-removed offsets |
| `walls_commercial_01_1` | Corresponding north-facing window |
| `walls_commercial_01_2` | `WallSE` corner |
| `walls_commercial_01_8` | `DoorWallW`, `wall` |
| `walls_commercial_01_9` | `DoorWallN`, `wall` |
| `fixtures_doors_01_40` | `doorW`, `attachedW`, `doorTrans`, glass material |
| `fixtures_doors_01_41` | `doorN`, `attachedN`, `doorTrans`, glass material |
| `floors_interior_tilesandwood_01_0` | `solidfloor`, `diamondFloor`, `attachedFloor` |

`media/lua/shared/Moveables/ISMoveableSpriteProps.lua` creates `IsoDoor` for door flags and `IsoWindow` for window flags, inserting them with `AddSpecialObject`. Local removal uses `RemoveTileObject`, with separate transmission for networked games. The prototype is restricted to single-player.

`media/lua/server/BuildingObjects/ISWoodenFloor.lua` uses `square:addFloor(sprite)` for native floor construction. The prototype likewise builds actual upper-level floors. It makes no sprite-flag or forced-transparency changes.

Engine doubles verify layout, safety checks and failure paths. Actual rendering, enclosure, native room recognition, collision and persistence remain in-game test requirements.
