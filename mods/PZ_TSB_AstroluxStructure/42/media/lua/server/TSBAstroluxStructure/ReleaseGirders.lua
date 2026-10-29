-- Private single-player test only. Never move or delete furnishings or containers.
if isClient()then return end
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
  if owned(o,s,kind)then sq:transmitRemoveItemFromSquare(o);refresh(sq)end
 end
end
local function ensure(sq,s,kind,sprite,visible)
 local found;local objects=sq:getObjects()
 for i=objects:size()-1,0,-1 do
  local o=objects:get(i)
  if owned(o,s,kind)then
   if found then sq:transmitRemoveItemFromSquare(o);refresh(sq)
   else
    found=o
    if o:getSprite():getName()~=sprite:getName()then o:setSprite(sprite);refresh(sq);if isServer()then o:transmitUpdatedSpriteToClients()end end
    if o:getDoRender()~=visible then o:setDoRender(visible);if not isServer()then o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)end end
   end
  end
 end
 if not found then
  found=IsoObject.new(getCell(),sq,sprite)
  found:getModData()[L.tag]={owner=s.recordId,kind=kind}
  found:getModData().TSBAstroluxStructure=s.recordId
  found:setDoRender(visible);sq:AddTileObject(found);refresh(sq);if isServer()then found:transmitCompleteItemToClients()end
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
function M.apply(s)
 for _,p in ipairs(L.positions)do
  local sq=assert(getCell():getGridSquare(s.x+p[1],s.y+p[2],0),'Girder square unloaded')
  if not occupied(sq,s)then ensure(sq,s,L.artKind,assert(getSprite(L.sprite(p))),true)end
 end
end
return M
