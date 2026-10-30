-- Persistent native collision and rain properties, scoped to the local test tower.
if isClient()then return end
local F={};local ticks=0;local tag='TSBAstroluxNativeHelperV1'
local covered=setmetatable({},{__mode='k'})
local refreshed=setmetatable({},{__mode='k'})
local function refresh(sq)
 sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
end
local function ensure(sq,kind,owner,wanted,spriteName)
 local found;local objects=sq:getObjects()
 for i=objects:size()-1,0,-1 do
  local o=objects:get(i);local data=o:getModData()[tag]
  if data and data.kind==kind and data.owner==owner then
   if not wanted or found then sq:transmitRemoveItemFromSquare(o);refresh(sq)
   else
    found=o
    if kind=='pillar' or kind=='pillarArt' then
     if o:getSprite():getName()~=spriteName then o:setSprite(assert(getSprite(spriteName)));refresh(sq) end
     o:setDoRender(kind=='pillarArt')
    else o:setDoRender(false) end
    -- Recalculate saved squares once after loading the corrected collision flags.
    if (kind=='furniture' or kind=='pillar') and not refreshed[o] then refresh(sq);refreshed[o]=true end
   end
  end
 end
 if wanted and not found then
  local sprite=assert(getSprite(spriteName),'Missing native Astrolux helper sprite')
  local obj=IsoObject.new(getCell(),sq,sprite)
  obj:getModData()[tag]={owner=owner,kind=kind};obj:setDoRender(kind=='pillarArt')
  if kind=='pillar' or kind=='pillarArt' then obj:getModData().TSBAstroluxStructure=owner end
  sq:AddTileObject(obj);refresh(sq);if isServer()then obj:transmitCompleteItemToClients()end
  return true
 end
 return false
end
function F.apply(s)
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
     local thumpable=instanceof(obj,'IsoThumpable')
     local props=sprite and sprite:getProperties()
     local nativeSolid=props and (props:has(IsoFlagType.solid) or props:has(IsoFlagType.solidtrans))
     -- Native wooden chairs are IsoObjects with directional chair flags, not
     -- solid/thumpable objects; mannequins likewise have their own native class.
     local chairIndex=name and tonumber(name:match('^furniture_seating_indoor_02_(%d+)$'))
     local woodenChair=chairIndex and chairIndex>=4 and chairIndex<=11
     local mannequin=instanceof(obj,'IsoMannequin')
     local blocking=name and (floorPlant or thumpable or nativeSolid or woodenChair or mannequin) and not name:find('furniture_tables_low_',1,true)
     if blocking then
      blocks=true
      -- Recheck native object flags throughout the 12x12 footprint. A helper
      -- square flag alone is not a substitute for a thumpable's collision state.
      if thumpable and (not obj:isBlockAllTheSquare() or obj:isCanPassThrough())
       and sq:getMovingObjects():size()==0 and sq:getStaticMovingObjects():size()==0 then
       obj:setBlockAllTheSquare(true);obj:setCanPassThrough(false);obj:setHoppable(false)
       refresh(sq);obj:transmitCompleteItemToClients()
       print('[Astrolux furniture] Restored owned collision '..name..' at '..x..','..y)
      end
     end
    end
   end
   -- Retired square-corner supports: remove only this tower's tagged
   -- helpers, including invisible blockers. Diagonal structural girders
   -- and furniture are separate objects and must remain untouched.
   local pillar=(dx==0 or dx==12) and (dy==0 or dy==12)
   if pillar then
    ensure(sq,'pillar',s.recordId,false,'TSBAstroluxBayCollision_2')
    ensure(sq,'pillarArt',s.recordId,false,'TSBAstroluxGroundPillar_0')
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
      if not isServer()then sq:getFloor():invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)end
      covered[sq]=s.recordId
     end
    end
   end
  end
 end end
 require('TSBAstroluxStructure/FurnitureEdges').sync(s)
end

-- Reconcile only existing furniture helpers. Never recreate or reposition furniture.
function F.cleanup(sq)
 if not sq or sq:getZ()~=0 then return end
 local objects=sq:getObjects();local owners={}
 for i=0,objects:size()-1 do
  local md=objects:get(i):getModData()
  local f=md.movableData and md.movableData.TSBAstroluxFurnishingV1
  if f then owners[f.tower]=true end
 end
 for i=objects:size()-1,0,-1 do
  local o=objects:get(i);local h=o:getModData()[tag]
  if h and h.kind=='furniture' and not owners[h.owner]then
   sq:transmitRemoveItemFromSquare(o);refresh(sq)
  end
 end
end
Events.LoadGridsquare.Add(F.cleanup)
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or not getCell()then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
  if r.status~='deleting'then
   for dx=0,12 do for dy=0,12 do F.cleanup(getCell():getGridSquare(r.x+dx,r.y+dy,0))end end
   if r.status=='ready' and r.releaseTower then
    require('TSBAstroluxStructure/FurnitureEdges').sync({recordId=r.id,x=r.x,y=r.y})
   end
  end
 end
end)

return F
