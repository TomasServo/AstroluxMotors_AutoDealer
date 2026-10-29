-- Refresh cached sight/collision properties after the glass tile-definition update.
local seen=setmetatable({}, {__mode='k'})
local function refresh(sq)
 if not sq or seen[sq]then return end
 local objects=sq:getObjects();local relevant=false
 for i=0,objects:size()-1 do
  local sp=objects:get(i):getSprite();local n=sp and sp:getName()
  if n and (n:find('TSBAstroluxClearGlass_',1,true)==1 or n=='TSBAstroluxBayCollision_2')then relevant=true;break end
 end
 if not relevant then return end
 sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
 if not isServer()then sq:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)end
 seen[sq]=true
end
Events.LoadGridsquare.Add(refresh)
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or not getCell()then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
  for dx=0,12 do for dy=0,12 do refresh(getCell():getGridSquare(r.x+dx,r.y+dy,0))end end
 end
end)
