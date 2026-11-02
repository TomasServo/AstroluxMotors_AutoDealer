# Showroom coffee cabinet

Prepared for in-game testing. The unique corner counter/cabinet with storage inside the registered showroom becomes the coffee cabinet when the footprint is loaded. If there are multiple corner cabinets, use the administrator right-click action **Astrolux Motors admin: use as coffee supplies cabinet** on the intended cabinet while standing within three tiles.

Target stock uses native items from the vanilla café coffee supplies family:

| Item | ID | Target |
|---|---|---|
| Coffee | Base.Coffee2 | 2 |
| White mug | Base.MugWhite | 4 |
| Sugar packet | Base.SugarPacket | 4 |
| Spoon | Base.Spoon | 4 |
| Simple syrup | Base.SimpleSyrup | 1 |
| Dishcloth | Base.DishCloth | 1 |
| Milk carton | Base.Milk | 1 |

Initial missing stock is added immediately. After that, every missing unit gets its own 600-second wall-clock deadline, detected within one second while loaded. Returned stock cancels the oldest pending replacement. Extra/player items are never deleted. Full containers retain their pending replacements until there is room. Deadlines persist in native movableData through saves and ordinary furniture moves. While unloaded or the game is closed, no items are created; overdue replacements arrive when the cabinet is loaded again inside the showroom. Items retain native behavior; empty or partially used items count until removed.

Test removing two coffee jars at different times: neither should return early, and each should return ten real-life minutes after its removal. Return a mug before its deadline and verify no extra mug appears. Save/reload and check that deadlines survive. Actual in-game acceptance remains pending.
