# Non-debug single-player mannequin setting

The Challenges demo's kiosk setting still entered the legacy `SettingsDisplays.objects` path, which requires `getDebug()`. Multiplayer entered `ShowroomSettings.record` and the authorized release dispatcher. The initial lock default from ReleaseAssembly did not repair this menu discrepancy.

SettingsDisplays now selects the release path for nearby release towers in SP as well as MP. It reads the record's persisted lock state and sends `displayLocks` through the existing dispatcher, which applies owned mannequin tags and updates the record. Legacy non-release debug behavior is retained.

The regression exercises debug-disabled SP status/toggling, enabled/disabled persisted record state, MP admin denial/acceptance, and absence of a nearby release tower. All 27 Lua 5.1 scripts and the Fengari suite pass. Native user verification is pending. The SP test profile has the correction on disk for its next launch; the running process was not interrupted or hot-patched.

Frozen archive verified unchanged: `accepted-save-and-runtime.zip`, SHA-256 `13ca84214a1a9b90e82fa12a9a40ca9def725e4886c797581ab1e9a4ada568a7`. The generated Challenges demo remains a candidate, not a replacement accepted checkpoint. MP and the frozen archive were not updated.
