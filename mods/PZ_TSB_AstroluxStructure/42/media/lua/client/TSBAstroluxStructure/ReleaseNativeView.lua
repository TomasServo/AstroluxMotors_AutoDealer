local Sites=require 'TSBAstroluxStructure/ReleaseSites'
local hidden={};local last=0;local ready=false
local M={}
Events.OnGameStart.Add(function()
 local manager=TileDepthTextureManager.getInstance()
 for i=0,8 do
  local name='TSBAstroluxGlassFrame_'..i;local art=getTexture(name)
  local depth=manager:getTextureFromTileName('PZ_TSB_AstroluxStructure',name)
  if not art or not depth or depth:isEmpty()then print('[Astrolux release] Missing frame depth: '..name);return end
  local texture=depth:getTexture();texture:setOffsetX(art:getOffsetX());texture:setOffsetY(art:getOffsetY())
 end
 ready=true
end)
local function render(o,value)
 if o:getDoRender()~=value then o:setDoRender(value);o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)end
end
function M.update()
 -- Apply visibility every render, but scan loaded objects only twice a second.
 for o in pairs(hidden)do if o:getObjectIndex()>=0 then render(o,false)end end
 local now=getTimestampMs();if now-last<500 then return end;last=now
 local wanted={};local p=getSpecificPlayer(0)
 if ready and p then for _,r in ipairs(Sites.all())do
  if r.status=='ready'and(p:getX()-r.x)^2+(p:getY()-r.y)^2<6400 then
   local visibility=require 'AstroluxBayTest/ShowroomVisibility12'
   for dx=0,11 do for dy=0,11 do
    local above=getCell():getGridSquare(r.x+dx,r.y+dy,1)
    if above then local objects=above:getObjects();for i=0,objects:size()-1 do visibility.update(objects:get(i),r)end end
   end end
   for dx=0,12 do for dy=0,12 do local sq=getCell():getGridSquare(r.x+dx,r.y+dy,0)
    if sq then local list=sq:getObjects();for i=0,list:size()-1 do
     local o=list:get(i);local md=o:getModData()
     if md.TSBAstroluxStructure==r.id then
      if md.TSBAstroluxCornerCollisionV1 or md.TSBAstroluxStructureKind=='corner'then wanted[o]=true
      elseif md.TSBAstroluxStructureKind=='window'then render(o,true);o:setAlphaAndTarget(0,1);o:setSceneCulled(false)end
     end
    end end
   end end
  end
 end end
 for o,old in pairs(hidden)do if not wanted[o]then if o:getObjectIndex()>=0 then render(o,old)end;hidden[o]=nil end end
 for o in pairs(wanted)do if hidden[o]==nil then hidden[o]=o:getDoRender()end;render(o,false)end
end
Events.OnTick.Add(M.update)
Events.OnRenderTick.Add(M.update)
Events.LoadGridsquare.Add(function()last=0 end)
Events.OnDisconnect.Add(function()
 for o,old in pairs(hidden)do if o:getObjectIndex()>=0 then render(o,old)end end
 hidden={};last=0
end)
return M
