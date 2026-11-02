# Default showroom furnishings

The user-completed capture was verified on October 22, 2026. The final in-game export contains 19 furnishings, including the north-facing chrome sink that the user accepted after installation. The validated relative layout is saved in shared Lua as TSBAstroluxStructure/DefaultFurnishings.lua.

The 8-by-8 layout contains two kiosks, three counters, a refrigerator, a coffee appliance, four seating pieces, two tables, three plants, two lamps and one sink. Positions, facing, same-tile order and actual render offsets are preserved. The sink is at relative (1,7), on the counter opposite the coffee maker across the corner cabinet; the captured native render offset is 2.

Kiosks are marked for fresh registration, and the corner cabinet retains its coffee-supplies role as layout metadata. No inventories, transactions, service identities, buyer information or refill deadlines are copied. The paste constructs functional native objects and assigns new kiosk identities. Version 0.6.0 adds a furnished-paste action using this saved layout; its in-game acceptance is pending.

Use the single-player lab right-click action record showroom furnishings to export an established default to Zomboid/Lua/TSBAstroluxShowroomDefault.txt. The native file writer rejects .lua output names; the export uses allowed .txt with a portable literal table. The profile is also retained in world ModData if export is unavailable. The one-time sink installer uses vanilla furniture placement, preserves the counter, and retains native plumbing behavior.

Verified final capture SHA256: f9182d8b3f2a07aa61a06d0684f41b9b1103798b4a3fde980f0f84e300b80fba.

Sink appearance and 19-object capture are accepted in game. Pasting, plumbing after water shutoff, multiplayer, and the separately staged coffee restock/sign updates remain unverified.

## Paste test (0.6.0)

In AstroluxStructureLab, right-click clear ground and select **Astrolux Motors lab: paste furnished showroom here**. Confirm the 19-furnishing layout. Stand outside the footprint, keep its 11-by-11 ground site and nearby vehicles clear, and remain within 30 tiles. Existing showrooms remain in place; each copy is saved as its own record. Native containers, refrigerator, coffee appliance, lamps and sink are placed through vanilla furniture code. Tables/counters precede tabletop objects. Captured facing, order and render offsets are retained.

Both new kiosks receive fresh registrations without orders, inventory or delivery areas copied from the original. Configure their vehicle delivery areas before purchases. The coffee cabinet retains its policy role; the separately staged refill implementation runs only if installed. Pasting does not charge the player or consume construction materials; this is the existing single-player debug-lab builder workflow.

Check all 19 furnishings, all four sliding-door pairs, the two kiosk screens, the sink, containers and lamps. Walk into and out of both the original and copy to check independent cutaways. Save/reload and verify no duplicates. Obstructed sites are rejected; failures roll back new fixtures/registrations or hold an uncertain partial build for inspection. Native multi-tile furniture pieces are validated individually without searching a player's inventory.
