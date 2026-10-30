# Pre-Workshop scrub â€” 2026-10-29

Status: HOLD for Workshop publication. No Workshop upload performed.

## Passed

- All 274 runtime Lua files parse under Lua 5.1.
- Every declared texture pack and tile definition exists.
- Static scan found no missing Astrolux require targets.
- Bundled ZIP integrity passed; all 532 saved-world files match the frozen source byte for byte.
- Five targeted regression scripts pass: deletion resume/token replay prevention, client cleanup, terrain restoration, power authorization/persistence, nearby deletion and mannequin authorization.
- Targeted credential-pattern scan found no matches in mods, docs or candidate tests. This is not an exhaustive security certification.
- The three reported fluid-container whitespace warnings do not apply: these calls retrieve attached containers rather than looking up container script names.

## Corrected in this scrub

- Main mod and optional map version metadata now identify 0.9-beta.
- Removed obsolete test-world-only placement claim from main mod metadata.
- Workshop text distinguishes tested MP features from broader untested multiplayer behavior.
- Added the GitHub save download link; clarified the save-only archive and tested game version.
- Added portable targeted tests. The deletion-resume test now supplies the server-mode mock required by the current handler.

No gameplay Lua, frozen save, running client or server was changed during this scrub.

## Outstanding release gates

1. Challenges world startup passed user testing. Complete demo gameplay and save/reload checks, then load the preserved save with the final runtime.
2. Demo defaults repaired: the explicit challenge record selects its approved kiosks and relative delivery zones; existing zone edits remain authoritative. The actual cash-grant path passes reload/interruption tests. Native acceptance of zones and $25,000 is pending.
3. RESOLVED: all 24 legacy regression scripts pass after updating stale fixtures and fixing trade-offer pricing. See LEGACY-TEST-REPAIR.md and LEGACY-TEST-RESULTS.json.
4. RESOLVED: user confirmed mixed-terrain restoration works in multiplayer on 2026-10-29; the ownership-aware restoration regression also passes.

Steam Overlay opening remains deferred by the user until after 0.9 beta. The existing copy-link fallback remains available.
