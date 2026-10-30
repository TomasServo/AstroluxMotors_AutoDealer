# Furniture fade investigation — 2026-10-29

No runtime change was applied by this investigation.

Inspection of the installed Project Zomboid `projectzomboid.jar` shows `FBORenderCell.calculateObjectTargetAlpha_NotDoorOrWall` returns float `0x3f28f5c3` (approximately 0.66) for potentially obscuring furniture on a square marked as obscuring the player. Tabletop objects have a separate branch returning the same alpha. `isPotentiallyObscuringObject` includes native solid/solidTrans sprites and objects with containers. Multi-tile furniture is included through its sprite grid. This explains proximity-dependent couch/table transparency without missing furniture or failed collision.

The inspected path does not consult `NeverCutaway` or an object-level opacity override before applying this furniture fade. Repeated Lua `setAlphaAndTarget` does not address the renderer's cached target calculation. No supported per-object Lua suppression was identified. Do not claim native validation of a fix or change shared vanilla sprite solidity, inventory, seating, or world geometry simply to bypass this branch.

Evidence was extracted read-only into the task workspace's `outputs/furniture-cell.txt` using `mp-repair/class_inspect.py`. Runtime, source archive and saves are unchanged. Removing this native behavior remains unresolved; a custom rendering implementation would require separate depth-order, interaction, seating, save/reload and multiplayer validation.
