Ceiling lights - 2026-10-24 candidate
TSBAstrolux.CeilingLightCool: Cool White Ceiling Light (6000K)
TSBAstrolux.CeilingLightWarm: Warm White Ceiling Light (2700K)

Find both in the normal admin/debug item list. Use vanilla inventory Place /
furniture placement, and the vanilla furniture pickup tool on their tile.
One tile per fixture. Place on the ROOM'S FLOOR LEVEL, not the floor above.
The world sprite is completely transparent by request; inventory icons remain
visible. The furniture cursor's selected tile/info identifies invisible items.
No collision, floor covering, artificial light halo, or painted-on glow.

These are real IsoLightSwitch fixtures. Native electricity, bulb wear, bulb
replacement, removal and save/network behavior apply. Native room wall switches
control panels in their room. Rooms without a wall switch retain the fixture's
native individual on/off behavior. Dynamically built structures with no native
room need an explicit switch binding; Astrolux's showroom supplies that binding.
6000K/2700K are RGB approximations, not a physically spectral game simulation.
Existing hue/string-light/timer state and legacy runtime IDs are preserved.

No automatic lights in other rooms or saved-world item grants. Artwork is
original AI-generated art; the world pack contains only transparent pixels.
Source/offline validation is separate from in-game acceptance. Check item-list
icons, vanilla place/pickup, wall switch, blackout/generator, bulb removal,
save/reload, streaming, and two-client synchronization before publication.
