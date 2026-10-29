-- Private single-player test only. Never move or delete furnishings or containers.
if isClient() or isServer()then return end
local L=require 'AstroluxDiagonalLab/GirderLayout'
local P=require 'AstroluxDiagonalLab/Plan'
local M={};local ticks=0
local function refresh(sq)
 sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
end
local function owned(o,s,kind)
 local d=o:getModData()[L.tag]
 return d and d.owner==s.recordId and d.kind==kind
end
local function remove(sq,s,kind)
 local objects=sq:getObjects()
 for i=objects:size()-1,0,-1 do
  local o=objects:get(i)
  if owned(o,s,kind)then sq:RemoveTileObject(o);refresh(sq)end
 end
end
local function ensure(sq,s,kind,sprite,visible)
 local found;local objects=sq:getObjects()
 for i=objects:size()-1,0,-1 do
  local o=objects:get(i)
  if owned(o,s,kind)then
   if found then sq:RemoveTileObject(o);refresh(sq)
   else
    found=o
    if o:getSprite():getName()~=sprite:getName()then o:setSprite(sprite);refresh(sq)end
    if o:getDoRender()~=visible then o:setDoRender(visible);o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)end
   end
  end
 end
 if not found then
  found=IsoObject.new(getCell(),sq,sprite)
  found:getModData()[L.tag]={owner=s.recordId,kind=kind}
  found:getModData().TSBAstroluxStructure=s.recordId
  found:setDoRender(visible);sq:AddTileObject(found);refresh(sq)
 end
 return found
end
local function occupied(sq,s)
 if sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0 then return true end
 local objects=sq:getObjects()
 for i=0,objects:size()-1 do
  local o=objects:get(i);local md=o:getModData()
  if not owned(o,s,L.artKind) and not owned(o,s,L.blockKind)then
   local glass=md.TSBAstroluxStructure==s.recordId and md.TSBAstroluxStructureKind=='window' and instanceof(o,'IsoWindow')
   local sprite=o:getSprite();local props=sprite and sprite:getProperties()
   if not glass and (o:getContainer() or md.movableData or instanceof(o,'IsoDoor')
    or instanceof(o,'IsoThumpable') or instanceof(o,'IsoMannequin')
    or (props and (props:has(IsoFlagType.solid) or props:has(IsoFlagType.solidtrans))))then return true end
  end
 end
 return false
end
function M.update()
 if not P.runtimeEnabled()then return end
 local preview=TSBAstroluxShowroomDiagonalPreview
 local s=preview and preview.site();if not s then return end
 local active=preview.enabled and TSBAstroluxDiagonalGirderReady==true
 for _,p in ipairs(L.positions)do
  local sq=getCell():getGridSquare(s.x+p[1],s.y+p[2],0)
  if sq then
   -- Legacy helpers were solid across a whole tile, well beyond the post base.
   -- Remove them even when a player or container occupies this square.
   remove(sq,s,L.blockKind)
   local art=active and getSprite(L.sprite(p))
   if not active or not art then
    remove(sq,s,L.artKind)
   elseif not occupied(sq,s)then
    -- The existing native window edge supplies collision at this junction.
    -- Keep the aligned post art without adding a full-square obstruction.
    ensure(sq,s,L.artKind,art,true)
   end
  end
 end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%30==0 then M.update()end end)
return M
