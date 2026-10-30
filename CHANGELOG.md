# Changelog

## 0.9 Beta - 2026-10-30

Final corrections:
- Align single-player movement with intact diagonal glass while preserving
  access to the furniture and the original native window collision.
- Restore corner-cabinet collision while keeping storage usable.
- Preserve native couch sitting, standing and exit; correct table overlap.
- Remove the green tabletop lamp and refresh furniture helper lighting.
- Default personal Showroom Music to 25%, preserving admin levels and saved
  personal preferences.
- Correct the Challenge title and description for Build 42.21.
- Supply the latest working save under Astrolux Motors Auto Dealer.

Validation: fresh placement, furniture and collision checks, personal audio,
and save/reload passed. Thirty regression suites and five targeted suites pass.

See [release notes](docs/RELEASE-0.9-BETA.txt) and [installation](docs/wiki/Install-the-Demo.md).


This file groups development checkpoints into launch-facing milestones. Git commit history is retained.

## 0.9 beta candidate â€” final demo corrections (2026-10-29)

- Initialize the approved Challenges showroom with two delivery areas and $25,000 once per character.
- Use release mannequin controls in non-debug single-player; preserve native inventory access.
- Add ownership-scoped kiosk/furniture boundaries, excluding native containers and mannequins; reconcile moved/deleted furniture.
- Default class prices to $400/$600/$1,000 with demand pricing; preserve saved overrides.
- Retain native furniture visibility fading, accepted for beta. Steam Overlay opening remains deferred; copying the reporting link is available.

## Earlier dealership testing candidate (2026-10-23)

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

## Preserved foundations â€” 2026-10-22

- Native transparent ground floor and centered sliding entrances beneath the approved car-display tower; approved roof cleanup retained.
- Full decorative tower cutaway, valid depth coverage and native gray flooring with a dark border.
- Captured showroom furniture/default-layout tools and independent sales kiosks.
- Accepted black/white racing jackets and existing asset attribution.

## Before public launch

- Complete in-game menu, purchase, trade-in, audio, save/reload and dedicated multiplayer acceptance.
- Review interruption/reconnection and administrator recovery cases against a backed-up world.
- Record permissions/provenance for distributed audio and finalize Workshop packaging.

Unaccepted local clothing/artwork revisions and unrelated game-startup repairs are excluded from this checkpoint.
