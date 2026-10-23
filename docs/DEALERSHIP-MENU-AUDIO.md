# Dealership menu and audio checkpoint

This checkpoint adds the current tabbed Vehicles, Accessories, Trade-ins,
Delivery Zone and Admin UI, its supporting dealership code and native preview
definitions. It preserves the published tower artwork, structure and clothing.

Admin access requires single-player debug mode or the administrator access level;
multiplayer client debug does not confer server authority. Admin > Sounds has
independent enable switches and 0–100% volume sliders, saved per world and sent to
clients. Purchase defaults to 50%, music to 10%. Music uses the current softer
volume curve and respects the native Music Volume setting. Play/Pause controls
operate actual local playback. The supplied audio assets are included unchanged.

The Astrolux emblem is enlarged 50% and its visible right edge aligns with the
20px inner margin. Delivery Zone exposes the saved area. Trade-in detection uses
physical ground-level vehicle bounds; transaction safeguards remain in place.

Offline regression checks cover audio settings, playback controls and access
policy; Lua files parse. In-game menu layout, audio listening, complete purchase/
trade cycles and multiplayer acceptance remain pending. This is a development
checkpoint, not Workshop release acceptance. Audio redistribution licensing has
not been recorded; resolve it before Workshop release.
