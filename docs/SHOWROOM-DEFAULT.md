# Default showroom furnishings

The user-completed capture was verified on October 22, 2026. The final in-game export contains 19 furnishings, including the north-facing chrome sink that the user accepted after installation. The validated relative layout is saved in shared Lua as TSBAstroluxStructure/DefaultFurnishings.lua.

The 8-by-8 layout contains two kiosks, three counters, a refrigerator, a coffee appliance, four seating pieces, two tables, three plants, two lamps and one sink. Positions, facing, same-tile order and actual render offsets are preserved. The sink is at relative (1,7), on the counter opposite the coffee maker across the corner cabinet; the captured native render offset is 2.

Kiosks are marked for fresh registration, and the corner cabinet retains its coffee-supplies role as layout metadata. No inventories, transactions, service identities, buyer information or refill deadlines are copied. An eventual paste implementation must construct functional native objects and assign new kiosk identities. Saving this default does not implement the paste operation itself.

Use the single-player lab right-click action record showroom furnishings to export an established default to Zomboid/Lua/TSBAstroluxShowroomDefault.txt. The native file writer rejects .lua output names; the export uses allowed .txt with a portable literal table. The profile is also retained in world ModData if export is unavailable. The one-time sink installer uses vanilla furniture placement, preserves the counter, and retains native plumbing behavior.

Verified final capture SHA256: f9182d8b3f2a07aa61a06d0684f41b9b1103798b4a3fde980f0f84e300b80fba.

Sink appearance and 19-object capture are accepted in game. Pasting, plumbing after water shutoff, multiplayer, and the separately staged coffee restock/sign updates remain unverified.
