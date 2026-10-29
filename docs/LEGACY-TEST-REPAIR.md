# Legacy test repair — 2026-10-29

All 24 regression scripts pass under both Lua 5.1 through Lupa and Fengari through the Node runner. The cash-fixture helper is excluded from the test count and exercised by the payment tests. All 274 runtime Lua files parse. Five targeted RC tests pass separately.

## Runtime correction

VehicleCatalog.tradeOffer returned raw native offers because every exact variant ID is now retained in byID. That shortcut skipped demand-adjusted prices and configuration surcharge/disable checks. Resolve normal offers through resolve and family variants through variant. Regression coverage checks vanilla and mod variants, surcharge, disabled configuration, hidden parent, repeated lookups without price compounding, and direct native demand pricing.

## Test corrections

- Restore current module search paths and required native API mocks (door obstruction, square properties, UI controls, inventory metadata and electricity).
- Test owner access in normal single-player while retaining multiplayer admin, moderator and client-debug boundaries.
- Test exact footprint cutaway instead of removed entrance hysteresis, retaining viewer isolation, stable redraw and foreign-object checks.
- Test explicit furnishing capture, failure-before-commit and current context-menu confirmations.
- Test normalized selection corners and deferred UI confirmation.
- Test personal volume fractions/defaults and clip-gain routing instead of the obsolete UI-emitter path.
- Test loaded-zone/power/funds refusal before orders or effects, immediate delivery, consumed-quote replay prevention, crash holds, no automatic legacy queue dispatch and bank commit order.
- Update appraisal resolver and payout mocks; capacity refusal now returns a reason without throwing. Retain no-removal/no-payment assertions.

The Node runner now discovers every Lua regression test, including audio-controls, and parses both mod packages. Each test runs in a fresh VM. No failures are skipped or marked expected.

Run `npm install` then `npm test`, or install Python `lupa` and run `python tests/run_legacy.py`. Targeted tests are `python tests/rc/test_*.py` individually. These mocked checks do not replace native-game acceptance.

Only VehicleCatalog.lua changed in gameplay code. No frozen save, deployed multiplayer files or live server was changed. Deploy matched client/server runtime copies before multiplayer testing this revision.
