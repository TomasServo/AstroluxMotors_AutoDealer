-- Repair only texture-only ground left by the previous release deletion code.
if isClient()then return end
local function repair(sq)
 if not sq or sq:getZ()~=0 then return end
 local journal=ModData.get('TSBAstroluxReleasePlacements.v1')or {}
 local site=false
 for _,e in pairs(journal)do
  if e.status=='cleared'and e.deletedAt and sq:getX()>=e.x and sq:getX()<e.x+12 and sq:getY()>=e.y and sq:getY()<e.y+12 then site=true;break end
 end
 if not site then return end
 local list=sq:getObjects()
 for i=0,list:size()-1 do
  local o=list:get(i);local old=o:getSprite();local name=o:getSpriteName()
  if old and not old:getName()and name and name:match('^blends_')and not o:getModData().TSBAstroluxFlooring then
   local sprite=getSprite(name)
   if sprite and sprite:getName()==name and sprite:getProperties():has(IsoFlagType.solidfloor)then
    o:setSprite(sprite);o:transmitUpdatedSpriteToClients()
    sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
    if not isServer()then o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)end
   end
  end
 end
end
Events.LoadGridsquare.Add(repair)
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%300~=0 or not getCell()then return end
 for _,e in pairs(ModData.get('TSBAstroluxReleasePlacements.v1')or {})do
  if e.status=='cleared'and e.deletedAt then
   for dx=0,11 do for dy=0,11 do repair(getCell():getGridSquare(e.x+dx,e.y+dy,0))end end
  end
 end
end)
