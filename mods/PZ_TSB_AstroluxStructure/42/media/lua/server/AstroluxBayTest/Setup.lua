-- Exact-world isolated scale study. Original tower and other worlds untouched.
if isClient()then return end
local world='AstroluxStructureLab_12x12_FourSides'
local X,Y=10285,9258
local plan=require 'AstroluxBayTest/Plan'
local ticks=0
local function allowed()return not isServer() and tostring(getWorld():getWorld())==world end
local function square(x,y,z)return getCell():getGridSquare(x,y,z or 0)end
local function run()
 if not allowed()then return end
 local state=ModData.getOrCreate('TSBAstroluxBayTest.v1')
 -- Retry only the known pre-placement failure from the obsolete setLx call.
 if not state.relocationFixV2 then
  if not state.ready and not state.positioned and not state.vehicleId
   and state.hold and string.find(tostring(state.hold),'Object tried to call nil',1,true) then
   state.hold=nil
  end
  state.relocationFixV2=true
 end
 if not state.siteSearchV3 then
  if not state.ready and not state.vehicleId and state.hold=='Preview footprint occupied; nothing deleted.' then state.hold=nil end
  state.siteSearchV3=true
 end
 if state.ready or state.hold then return end
 local player=getSpecificPlayer(0);if not player or player:isDead()then return end
 if not state.positioned then
  player:teleportTo(10282.5,9265.5,0)
  state.positioned=true;return
 end
 local function clearSite(cx,cy)
  -- Include the native comparison car's surrounding tiles, not only its center.
  for dx=-2,7 do for dy=-2,11 do
   local sq=square(cx+dx,cy+dy)
   if not sq or not sq:getFloor() or not sq:TreatAsSolidFloor() then return false end
   local list=sq:getObjects()
   for i=0,list:size()-1 do if list:get(i)~=sq:getFloor() then return false end end
   if sq:getWorldObjects():size()>0 or sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0 then return false end
  end end
  for dx=-5,9 do for dy=-5,11 do if not square(cx+dx,cy+dy)then return false end end end
  local vehicles=getCell():getVehicles():iterator()
  while vehicles:hasNext()do
   local v=vehicles:next()
   if v:getX()>cx-3 and v:getX()<cx+9 and v:getY()>cy-3 and v:getY()<cy+12 then return false end
  end
  return true
 end
 local found=false
 for radius=0,24 do
  for dx=-radius,radius do
   for dy=-radius,radius do
    if math.max(math.abs(dx),math.abs(dy))==radius and clearSite(10285+dx,9258+dy)then
     X,Y=10285+dx,9258+dy;found=true;break
    end
   end
   if found then break end
  end
  if found then break end
 end
 if not found then
  if not state.waitingForSite then print('[Astrolux Bay Test] Waiting for a clear loaded patch nearby. No objects removed.');state.waitingForSite=true end
  return
 end
 state.siteX=X;state.siteY=Y
 print('[Astrolux Bay Test] Clear site selected: '..X..','..Y)
 local reference=square(X+1,Y+9)
 local required={}
 for _,piece in ipairs(plan)do
  local sprite=getSprite(piece.sprite);assert(sprite,'Preview asset missing: '..piece.sprite)
  required[#required+1]={piece=piece,sprite=sprite}
 end
 -- Persist before native effects. Partial setup is held; never duplicate pieces/car.
 state.hold='Setup interrupted; inspect or restore fresh test copy.'
 for dx=0,5 do for dy=0,2 do
  local sq=square(X+dx,Y+dy);sq:getFloor():setSprite(getSprite('floors_interior_tilesandwood_01_28'))
  sq:RecalcAllWithNeighbours(true);sq:getFloor():invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
 end end
 for _,entry in ipairs(required)do
  local p=entry.piece;local sq=square(X+p.x,Y+p.y,p.z)
  if not sq then sq=getCell():createNewGridSquare(X+p.x,Y+p.y,p.z,true)end
  assert(sq,'Preview sprite square unavailable.')
  local obj=IsoObject.new(getCell(),sq,entry.sprite);obj:getModData().TSBAstroluxBayTest=true
  sq:AddTileObject(obj);sq:RecalcAllWithNeighbours(true)
 end
 local dir=IsoDirections.E
 local car=addVehicleDebug('Base.CarStationWagon',dir,nil,reference)
 assert(car,'Native comparison vehicle creation failed.')
 state.vehicleId=car:getId();assert(car:getSquare(),'Comparison vehicle not physically placed.')
 car:setDir(dir);car:setAngles(0,(math.deg(dir:toAngle())+180)%360,0)
 car:getModData().TSBAstroluxBayTest=true;car:transmitModData()
 local key=car:createVehicleKey();assert(key and player:getInventory():AddItem(key),'Comparison key creation failed.')
 state.ready=true;state.hold=nil
 player:Say('Full-Size Bay Test ready. Decorative bay on fresh terrain; real Cerise and key supplied for scale comparison. Original tower unchanged.')
 print('[Astrolux Bay Test] Ready; decorative scale prototype, native comparison vehicle '..tostring(state.vehicleId))
end
Events.OnTick.Add(function()
 if not allowed()then return end
 ticks=ticks+1;if ticks<60 then return end;ticks=0
 local ok,why=pcall(run)
 if not ok then
  local state=ModData.getOrCreate('TSBAstroluxBayTest.v1');state.hold=tostring(why)
  print('[Astrolux Bay Test] Held: '..state.hold)
  local player=getSpecificPlayer(0);if player then player:Say('Bay Test setup paused: site occupied or partial setup. See console.')end
 end
end)
