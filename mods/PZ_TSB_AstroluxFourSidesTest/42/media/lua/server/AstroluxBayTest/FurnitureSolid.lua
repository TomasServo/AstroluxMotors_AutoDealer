-- Persistent native collision and rain properties, scoped to the local test tower.
if isClient() or isServer() then return end
local F={};local ticks=0;local tag='TSBAstroluxNativeHelperV1'
local covered=setmetatable({},{__mode='k'})
local function refresh(sq)
 sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
end
local function ensure(sq,kind,owner,wanted,spriteName)
 local found;local objects=sq:getObjects()
 for i=objects:size()-1,0,-1 do
  local o=objects:get(i);local data=o:getModData()[tag]
  if data and data.kind==kind and data.owner==owner then
   if not wanted or found then sq:RemoveTileObject(o);refresh(sq)
   else found=o;o:setDoRender(false)end
  end
 end
 if wanted and not found then
  local sprite=assert(getSprite(spriteName),'Missing native Astrolux helper sprite')
  local obj=IsoObject.new(getCell(),sq,sprite)
  obj:getModData()[tag]={owner=owner,kind=kind};obj:setDoRender(false)
  sq:AddTileObject(obj);refresh(sq)
  return true
 end
 return false
end
function F.update()
 local s=ModData.get('TSBAstroluxCombined12.v1')
 if not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' or not s or not s.ready then return end
 local cell=getCell()
 for dx=0,12 do for dy=0,12 do
  local x,y=s.x+dx,s.y+dy;local sq=cell:getGridSquare(x,y,0)
  if sq then
   local objects=sq:getObjects();local blocks=false;local doorway=false
   for i=0,objects:size()-1 do
    local obj=objects:get(i);local md=obj:getModData()
    local furniture=md.movableData and md.movableData.TSBAstroluxFurnishingV1
    if instanceof(obj,'IsoDoor')then doorway=true end
    if furniture and furniture.tower==s.recordId then
     local sprite=obj:getSprite();local name=sprite and sprite:getName()
     -- The two ground-standing plants are native IsoObjects, not thumpables.
     -- Keep the small tabletop plant and working coffee table excluded.
     local floorPlant=name=='vegetation_indoor_01_9' or name=='vegetation_indoor_01_11'
     if name and (floorPlant or instanceof(obj,'IsoThumpable')) and not name:find('furniture_tables_low_',1,true)then blocks=true end
    end
   end
   if not blocks or doorway or (sq:getMovingObjects():size()==0 and sq:getStaticMovingObjects():size()==0)then
    ensure(sq,'furniture',s.recordId,blocks and not doorway,'TSBAstroluxBayCollision_2')
   end
   if dx<12 and dy<12 and sq:getFloor() and sq:getFloor():getModData().TSBAstroluxFlooring==s.recordId then
    local above=cell:getGridSquare(x,y,1) or cell:createNewGridSquare(x,y,1,true)
    if above then
     local added=ensure(above,'rain',s.recordId,true,'TSBAstroluxBayCollision_3')
     if added or covered[sq]~=s.recordId then
      cell:checkHaveRoof(x,y);sq:clearPuddles()
      sq:getFloor():invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
      covered[sq]=s.recordId
     end
    end
   end
  end
 end end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%30==0 then F.update()end end)
return F
