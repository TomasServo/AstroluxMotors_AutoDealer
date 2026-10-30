# Menu and audio

The kiosk has Vehicles, Accessories, Trade-ins, Delivery Zone and Admin tabs. Individual car settings are under **Admin > Vehicle prices**: choose the alphabetical family, then a variant. The main menu retains the larger Astrolux logo.

Admin > Sounds controls per-world enablement and 0–100% volume for purchase audio and showroom music. Defaults are 15% purchase and 10% music; existing saved settings remain authoritative. Personal settings allow each client to adjust volume/mute independently. Music uses softer gain scaling, respects native Music Volume and plays only inside the showroom.

Play/Pause controls operate actual local playback. Play starts playback again; it does not provide a seek-preserving media-player resume. Showroom music loops. Purchase sound is used for purchase interaction and successful trade-ins. Personal settings persist locally; world settings remain server controlled.

Before launch, listen at low and high settings, test zero/mute, leave/re-enter the showroom, close/reopen the menu, pause/play both sounds, and verify music repeats. Test separate clients and native audio settings. Offline tests validate control/state logic, not perceived loudness or native playback.

The supplied audio assets remain unchanged. The project owner confirmed third-party audio is used with permission on 2026-10-30; see AUDIO-PERMISSIONS.json.
