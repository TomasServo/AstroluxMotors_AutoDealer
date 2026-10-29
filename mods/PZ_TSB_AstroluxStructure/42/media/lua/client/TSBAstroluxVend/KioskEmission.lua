-- Compatibility entry point; KioskAppearance owns the native powered overlay.
-- Do not draw UI geometry over the world-rendered monitor.
local M={}
function M.draw()end
return M
