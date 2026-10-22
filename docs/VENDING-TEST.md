# Kiosk and vehicle vending test batch

Version 0.5.2: user confirmed the kiosk item is present and a local test purchase delivered one car in the selected direction with its key (October 22, 2026). Remote queue delivery, configured kiosk movement/pickup blocking and multiplayer remain unverified in game. Prior published baseline: `d9e3f80bb25ca4bc55510e2a8f9c196fbaf98edc`.

The accepted floor, tower cutaway, sliding doors and their quieter sound remain unchanged. This batch reuses the prior project's kiosk artwork, sales UI, catalog, pricing, paint choices, stock restoration and payment protections under isolated names. It does **not** import its tower-linked parking, painted bays, fixed-slot layout or old spawn implementation. No Java helper, launcher change, game-core modification or additional runtime mod is required. The optional existing server-bank bridge is used only if present; native carried cash works independently.

## First purchase

1. Launch `AstroluxStructureLab` yourself with Astrolux enabled. Open the admin item list, search **Astrolux Motors Sales Kiosk**, and add it to inventory. Use its vanilla **Place** action, or the furniture controls, to position and rotate it on a clear ground-floor tile away from the sliding-door paths. Ground right-click kiosk creation options have been removed. Nothing is automatically placed or replaced.
2. Click or right-click the kiosk to open **Astrolux Motors**. This selects the kiosk for subsequent area setup. Stay within three tiles when shopping.
3. Right-click ground, choose **Astrolux Motors admin: drag vehicle spawn area**, and choose N, E, S or W. Press and hold the left button on one corner tile, drag to the opposite corner, release, and confirm. Right-click or Escape cancels. For a first car test, a clear 10-by-16-tile rectangle leaves ample space.
4. The same menu offers **Enter remote corners; face ...**. Enter `x1, y1, x2, y2` to create a rectangle beyond the current view. Area creation has no size or distance limit relative to the kiosk or tower. The native integer-coordinate range still applies. A one-tile area can be saved, but a vehicle must physically fit before it can be purchased.
5. Reopen the kiosk. Select a vehicle and paint, request a price quote, then confirm. Carried `Base.Money` and `Base.MoneyBundle` are supported; favorite/equipped currency is excluded. Owner pricing retains dynamic/static selection, native colors and enabled compatible designs. The initial catalog contains the four prior vanilla offers; owner pricing can enable compatible installed scripts.
6. In a clear loaded area, delivery should complete immediately with a fully restored vehicle and its key in the buyer's inventory. Vehicles use exact N/E/S/W headings, with vanilla debug-spawn angle jitter removed. Existing parked vehicles, people, bodies, items and fixtures must remain untouched.

## Remote delivery test

1. Designate an area on real map ground far outside the currently loaded region, using the coordinate option or by visiting it after selecting the kiosk. Fog-of-war is irrelevant; the code never requires explored tiles.
2. Buy at the kiosk. The order should show **queued**, with payment recorded exactly once. A reservation prevents another buyer from consuming the same space. Do not buy a second car to retry the same order.
3. Save and reload before visiting the area. The unattempted queue should survive without another charge.
4. Keep the buyer online and load the destination by travelling there, or have another player load it in multiplayer testing. Once a fitting clear space is loaded, delivery is retried automatically about every two seconds. The buyer receives the key. If the reserved location is obstructed, another clear location within the same area can be selected; otherwise the order remains queued.
5. Verify there is one vehicle, one key and one charge. Reload and recheck. Queued orders prevent kiosk removal and area changes until resolved. An interrupted or uncertain native spawn/key/payment operation becomes a hold and is never automatically spawned again.

The buyer must be online for delivery because the key goes into that buyer's native inventory. A fully loaded, known-blocked area is rejected before payment. Unloaded terrain cannot be inspected from Lua; it is checked when loaded. No empty terrain or fake grid squares are created to force a remote spawn.

## Verification limits

Offline checks cover startup ordering, drag confirmation/cancel, arbitrary remote rectangles, vehicle fit and exact headings, loaded-space search, queued payment/reload, cross-buyer reservations, cash rollback, authorization, uncertain-payment holds and duplicate prevention. Native kiosk rendering/collision, live purchases, physics orientation, remote chunk transitions and multiplayer behavior still need in-game acceptance. This batch does not migrate old dealership orders, balances, fixtures or vehicles.
# Movable kiosk test (0.5.2)

In the admin item list, search **Astrolux Motors Sales Kiosk** (`TSBAstroluxVend.SalesKiosk`) and add it to inventory. In inventory, use the kiosk's vanilla **Place** action, or use the furniture controls. Rotate it with the normal furniture controls. Existing placed kiosks also become movable after restarting with this batch.

Configure a two-corner area and prices, pick up the kiosk using the furniture **Pick Up** mode, then place it elsewhere. Its registration ID, absolute spawn-area coordinates, prices and purchase history remain intact. The spawn area does not move with the kiosk. Unpaid quotes are invalidated when moving or rotating it. Test a save/reload while it is carried.

A queued, paid, dispatching or held delivery blocks pickup, including completion of a pickup action started before the purchase. Finish delivery (or resolve its hold) first. Vanilla placement collision and inventory capacity rules still apply; kiosk moves have no random breakage and dismantling is disabled. Live single-player and multiplayer furniture acceptance remain pending.

