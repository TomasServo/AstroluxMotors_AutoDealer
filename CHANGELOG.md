# Changelog

This file groups development checkpoints into launch-facing milestones. Git commit history is retained.

## Tested local checkpoint - 2026-10-24

- Display name: Astrolux Motors Auto Dealer; existing mod, item and saved sprite IDs retained.
- Settings controls for entrances, linked rugs, mannequin outfit locks and coffee restocking.
- Furniture pickup information, chair/lamp/mannequin rotation, rug facing and showroom lamp fixes.
- Glass, collision, floor/weather, audio coverage and delivery-border corrections.
- Updated kiosk and entrance art; approved car-logo neon sign and matching rug.
- Complete entrance rugs now follow door/window toggles even when one half crosses the detection boundary.
- User confirmed the current local build works and requested this GitHub checkpoint. Audit and multiplayer/release validation remain pending.

## Unreleased — dealership testing candidate (2026-10-23)

### Shopping and administration

- Tabbed menu with a larger Astrolux emblem, grouped alphabetical vehicle families and individual variant selection.
- Vehicle availability switches, model-wide prices and per-variant overrides; configurable static/demand pricing without an arbitrary price ceiling.
- Existing factory colors/designs and compatible accessory choices, with administrator pricing.

### Delivery and trade-ins

- Delivery-zone editing, native area visualization, direction arrow, optional border and eight vehicle headings. Leaving the area preview keeps the main menu open.
- Queued purchases take no payment until delivery is ready. Cash is deducted after vehicle/key creation; compatible banks commit immediately before creation. Uncertain operations are held for inspection; legacy prepaid orders are not charged twice.
- Empty cargo on newly purchased vehicles and matching delivered keys.
- Select multiple vehicles for appraisal and trade-in. Unsupported appraisal profiles appear with an explanation instead of causing menu errors.
- Configurable buyback enablement, base percentage, damage deductions, installed-parts threshold, battery exclusion, key requirements and hotwire policy. Matching player-made keys are accepted.

### Audio and reliability

- Independent purchase and showroom sound controls, personal settings, local Play/Pause and looping showroom music. Softer music gain respects native audio settings.
- Improved client initialization, deferred native handlers, administrator checks, variant/catalog handling and trade-in eligibility feedback.
- Expanded offline regression coverage for payments, queued delivery, headings, menu startup, appraisals, catalog variants, demand and personal audio.

## Preserved foundations — 2026-10-22

- Native transparent ground floor and centered sliding entrances beneath the approved car-display tower; approved roof cleanup retained.
- Full decorative tower cutaway, valid depth coverage and native gray flooring with a dark border.
- Captured showroom furniture/default-layout tools and independent sales kiosks.
- Accepted black/white racing jackets and existing asset attribution.

## Before public launch

- Complete in-game menu, purchase, trade-in, audio, save/reload and dedicated multiplayer acceptance.
- Review interruption/reconnection and administrator recovery cases against a backed-up world.
- Record permissions/provenance for distributed audio and finalize Workshop packaging.

Unaccepted local clothing/artwork revisions and unrelated game-startup repairs are excluded from this checkpoint.
