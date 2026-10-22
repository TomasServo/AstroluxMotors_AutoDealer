# Window and roof triangle fix

The user confirmed the fix in-game on October 22, 2026 and authorized publication. Version 0.2.1 changes rendering metadata only; the accepted artwork pack, slice offsets, placement anchors, native ground-floor objects and save data are unchanged.

The installed game's `media/shaders/tileWithDepth.frag` discards a fragment when its sampled red depth value is zero. The previous display had no explicit mapping, allowing native whole-tile fallback geometry to exclude 35,126 visible artwork pixels. A direct copy of native billboard depth would still leave 353,146 visible pixels at zero.

The fix registers this mod through `common/media/tileGeometry.txt` and supplies `common/media/depthmaps/DEPTH_TSBAstroluxDisplay.png`. All 404 slices are addressed in the native eight-column, 51-row layout. Positive native billboard samples remain exact; only zero samples are extended to the smallest positive representable depth, 1/255. This avoids changing the whole depth ramp.

The coverage check samples every visible pixel of the actual packed atlas: none of its 1,446,044 visible pixels now receives zero depth. Four unused slots remain blank. No image pixels or geometry positions were edited, and existing placed towers use their saved sprite IDs without rebuilding.

Run the asset regression check with Python and Pillow:

```sh
python tests/depth-coverage.py
```

The fix passed the existing Lua syntax, layout, conversion, rollback and menu tests as well. In-game confirmation covers the reported triangle gaps; comprehensive overlap, cutaway, enclosure, collision, cleanup, multiplayer and save/reload testing is not implied. Multiplayer remains unsupported by the prototype.
