local S=require 'TSBAstroluxStructure/EntranceSigns'
local originalPlan=S.plan
S.plan=function(r)
 if r.combinedSize~=11 then return originalPlan(r)end
 return {{x=r.x+4,y=r.y+11,z=0,sprite='TSBAstroluxEntranceSign_0'},
 {x=r.x+11,y=r.y+4,z=0,sprite='TSBAstroluxEntranceSign_1'}}
end
local M={}
function M.apply(r)
 if r.combinedSize~=11 or r.status~='ready' or r.alignment11Revision then return end
 local cell=getCell();local old={};local targets={};local floors={}
 for _,p in ipairs(S.plan(r))do
  local sq=cell:getGridSquare(p.x,p.y,0);local sprite=getSprite(p.sprite)
  if not sq or not sprite or sprite:getName()~=p.sprite then return end
  targets[#targets+1]={sq=sq,sprite=sprite}
 end
 for x=0,11 do for y=0,11 do
  local sq=cell:getGridSquare(r.x+x,r.y+y,0);if not sq then return end
  local list=sq:getObjects()
  for i=0,list:size()-1 do local obj=list:get(i);local md=obj:getModData()
   if md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='entranceSign' then old[#old+1]={obj=obj,sq=sq}end
  end
 end end
 if #old~=2 then return end
 local gray=getSprite('floors_interior_tilesandwood_01_28');if not gray then return end
 for x=0,10 do for y=0,10 do
  local sq=cell:getGridSquare(r.x+x,r.y+y,1);if not sq then return end
  local obj=sq:getFloor();local md=obj and obj:getModData()
  if obj and md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='floor' and obj:getSprite():getName()=='floors_interior_tilesandwood_01_0' then floors[#floors+1]=obj end
 end end
 local made={}
 local ok,why=pcall(function()
  for _,t in ipairs(targets)do
   local obj=IsoObject.new(cell,t.sq,t.sprite);made[#made+1]={obj=obj,sq=t.sq}
   local md=obj:getModData();md.TSBAstroluxStructure=r.id;md.TSBAstroluxStructureKind='entranceSign'
   t.sq:AddTileObject(obj);assert(obj:getObjectIndex()>=0);t.sq:RecalcAllWithNeighbours(true)
  end
  for _,e in ipairs(old)do e.sq:RemoveTileObject(e.obj);assert(e.obj:getObjectIndex()<0);e.sq:RecalcAllWithNeighbours(true)end
  for _,obj in ipairs(floors)do obj:setSprite(gray);obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)end
  r.alignment11Revision=1
 end)
 if not ok then
  for _,e in ipairs(made)do if e.obj:getObjectIndex()>=0 then e.sq:RemoveTileObject(e.obj)end end
  for _,e in ipairs(old)do if e.obj:getObjectIndex()<0 then e.sq:AddTileObject(e.obj)end;e.sq:RecalcAllWithNeighbours(true)end
  print('[Astrolux Alignment] Sign relocation rolled back: '..tostring(why))
 end
end
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or isClient() or isServer() or not getWorld()
  or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do M.apply(r)end
end)
return M
