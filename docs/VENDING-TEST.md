# Dealership testing

This is a pre-release test package. Use a disposable, backed-up world and keep the existing mod ID. No TSB Core is required. Legacy dealership saves are not migrated.

## Administrator setup

Use an administrator account, or single-player debug mode. Client debug alone does not grant multiplayer administration.

1. Place a native sales kiosk and open its menu within three tiles.
2. In Delivery Zone, select two corners, choose one of eight headings and inspect the area/arrow. Right-click or Escape exits the preview while preserving the menu. Test the optional border on loaded squares.
3. In Admin > Vehicle prices, select an alphabetical vehicle family, then its variant. Test a family-wide price, a variant override, and availability switches, including emergency vehicles.
4. Set static or demand pricing. Check that price changes invalidate unpaid quotes and that completed purchases update demand once.
5. In Buybacks, test enablement, base percentage, damage percentage, minimum installed-parts percentage, battery exclusion, key requirements and hotwire policy.

## Transactions

- Quote and buy using loose cash, cash bundles, nested inventory and exact change. Favorite/equipped currency must remain protected.
- Block or unload delivery space: the order must queue without taking payment. Reload and reconnect; it must deliver once when the buyer and space are ready.
- Cash must be deducted after physical vehicle/key creation. Optional bank providers commit immediately before vehicle creation. Failed or uncertain operations require inspection rather than blind retries.
- Verify matching key identity, eight facing directions, configured paint/accessories, and empty vehicle cargo.
- Check legacy prepaid orders against a backed-up test fixture: they must never pay twice.
- Select one or several vehicles in Trade-ins. Review each appraisal and total before accepting. Confirm removal and cash payout happen once.
- Test matching original and player-made keys, missing keys, hotwired vehicles, missing parts, battery exclusion, damage, occupied vehicles and cargo. Unsupported profiles should show a reason without errors.

## Remaining acceptance

Exercise save/reload, interrupted transactions, reconnection and dedicated multiplayer. Check native collision/clearance, real cash/bank behavior, administrator authorization and recovery holds. Offline engine doubles cannot establish these outcomes.

Structure testing remains in [STRUCTURE-ACCEPTANCE.md](STRUCTURE-ACCEPTANCE.md); audio testing is in [DEALERSHIP-MENU-AUDIO.md](DEALERSHIP-MENU-AUDIO.md).
