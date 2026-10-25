-- Match vanilla Neon Open: dim base artwork plus native HasLightOnSprite overlay.
-- The engine controls the full-bright _on_ overlay and actual light emission.
local M={}
function M.refresh(o)
 if not o or not instanceof(o,'IsoLightSwitch') then return end
 local sp=o:getSprite();local name=sp and sp:getName()
 if type(name)~='string' or not name:match('^TSBAstroluxMotorsSign_[0-3]$') then return end
 o:setCustomColor(ColorInfo.new(0.12,0.12,0.12,1))
 o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
end
function M.visit(sq)
 if not sq then return end
 local objects=sq:getObjects()
 for i=0,objects:size()-1 do M.refresh(objects:get(i)) end
end
Events.LoadGridsquare.Add(M.visit)
Events.OnObjectAdded.Add(M.refresh)
Events.OnFillWorldObjectContextMenu.Add(function(_,_,objects)
 for _,o in ipairs(objects or {}) do if o and o:getSquare() then M.visit(o:getSquare()) end end
end)
return M
