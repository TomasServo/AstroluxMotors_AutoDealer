-- Existing owned covers gained solidfloor for native room detection.
-- Never create roofs or assign synthetic room IDs.
if isClient()then return end
local M={};local seen=setmetatable({},{__mode='k'});local ticks=0
function M.visit(sq)
 if not sq or seen[sq]then return end
 local list=sq:getObjects()
 for i=0,list:size()-1 do
  local o=list:get(i);local sp=o:getSprite();local data=o:getModData();local md=data.TSBAstroluxNativeHelperV1
  local doorway=data.TSBAstroluxStructure and data.TSBAstroluxStructureKind=='slidingDoor' and sp and sp:getName():match('^TSBAstroluxSlidingDoor_')
  if doorway or (md and md.kind=='rain' and sp and sp:getName()=='TSBAstroluxBayCollision_3')then
   sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
   IsoRegions.squareChanged(sq,true)
   getCell():checkHaveRoof(sq:getX(),sq:getY())
   seen[sq]=true;return
  end
 end
end
Events.LoadGridsquare.Add(M.visit)
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or not getCell()then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
  if r.releaseTower and r.status=='ready'then
   for x=0,12 do for y=0,12 do
    M.visit(getCell():getGridSquare(r.x+x,r.y+y,0))
    if x<12 and y<12 then M.visit(getCell():getGridSquare(r.x+x,r.y+y,1))end
   end end
  end
 end
end)
return M
