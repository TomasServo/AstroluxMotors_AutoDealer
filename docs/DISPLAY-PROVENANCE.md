# Car-display artwork

Structure Lab 0.2.0 restores the project's previous car-display artwork above the retained native ground floor. The user explicitly requested this layout and accepted its in-game appearance on October 22, 2026.

The source is the approved roof-cleanup `AstroluxTower.pack`, SHA256 `aaa3174a835c03fb43c5032242c641ef17469f4a67bc85f572b5a7de3a69c9b5`, published in the prior mod at [`62449fc`](https://github.com/TomasServo/PZ_TSB_AutoVend/commit/62449fc011b82ab0e61ba18c1230c703df34b107). The roof retains the left AC unit and excludes the removed blue structures and southeast cube.

Only `AstroluxEightPage` is reused: its PNG bytes, 404 slice rectangles and offsets are unchanged, as are the archived 404-piece placement anchors. The pack and tile definitions use the isolated `TSBAstroluxDisplay` namespace and tiledef registration 7981. No depth map or legacy dealership code is imported. The display is decorative artwork; it does not create actual vehicles or walkable upper decks.

Vanilla sprites for the ground floor remain references to installed game assets. No vanilla sprite pixels are bundled. The retained source image is project artwork; no new image was generated for this layout.
