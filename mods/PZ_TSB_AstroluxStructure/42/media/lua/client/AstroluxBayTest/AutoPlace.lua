-- One-shot setup for the explicitly authorized, separate performance save.
local W=require 'AstroluxBayTest/TestWorld'
local M={}
local stateKey='TSBAstroluxAutoPlace20261025.v1'
local function empty(data) for _ in pairs(data or {})do return false end;return true end
local function clutter(o)
 if o:getContainer() or not empty(o:getModData()) then return false end
 if instanceof(o,'IsoThumpable') or instanceof(o,'IsoDoor') or instanceof(o,'IsoWindow') or instanceof(o,'IsoTree') then return false end
 local sp=o:getSprite();local n=sp and sp:getName()
 if not n then return false end
 for _,prefix in ipairs({'blends_grassoverlays_','vegetation_groundcover_','d_floorleaves_','d_trash_','overlay_grime_','street_trafficlines_'})do
  if n:sub(1,#prefix)==prefix then return true end
 end
 return false
end
function M.emptyVehicle(v)
 if not empty(v:getModData()) then return false end
 for seat=0,v:getMaxPassengers()-1 do if v:getCharacter(seat) then return false end end
 for i=0,v:getPartCount()-1 do
  local container=v:getPartByIndex(i):getItemContainer()
  if container and container:getItems():size()>0 then return false end
 end
 return true
end
function M.survey(player,x,y)
 if player:getZ()~=0 or (player:getX()-x)^2+(player:getY()-y)^2>900 then return nil end
 local result={x=x,y=y,objects={},items={},vehicles={}}
 local cell=getCell()
 for z=0,4 do for sx=x-1,x+13 do for sy=y-1,y+13 do
  local sq=cell:getGridSquare(sx,sy,z)
  if z==0 and (not sq or not sq:TreatAsSolidFloor() or not sq:isOutside() or not sq:getFloor()) then return nil end
  if sq then
   local moving=sq:getMovingObjects()
   for i=0,moving:size()-1 do
    local mover=moving:get(i)
    local margin=sx<x or sx>x+12 or sy<y or sy>y+12
    if mover~=player or not margin then return nil end
   end
   if sq:getStaticMovingObjects():size()>0 then return nil end
   local world=sq:getWorldObjects();local worldSet={}
   for i=0,world:size()-1 do
    if z~=0 then return nil end
    local o=world:get(i);worldSet[o]=true;result.items[#result.items+1]={sq=sq,obj=o}
   end
   local list=sq:getObjects()
   for i=0,list:size()-1 do local o=list:get(i)
    if not (z==0 and o==sq:getFloor()) and not worldSet[o] then
     if z~=0 or not clutter(o) then return nil end
     result.objects[#result.objects+1]={sq=sq,obj=o}
    end
   end
  end
 end end end
 local vehicles=cell:getVehicles():iterator()
 while vehicles:hasNext() do local v=vehicles:next()
  if v:getX()>x-9 and v:getX()<x+20 and v:getY()>y-9 and v:getY()<y+20 then
   if not M.emptyVehicle(v) then return nil end
   result.vehicles[#result.vehicles+1]=v
  end
 end
 result.score=#result.vehicles*1000+#result.items*10+#result.objects+((player:getX()-x)^2+(player:getY()-y)^2)/100
 return result
end
function M.execute(player,candidate)
 if not W.city() then return nil,'Wrong test save.' end
 local state=ModData.getOrCreate(stateKey)
 local city=ModData.get('TSBAstroluxCityPerformance.v1')
 if state.attempted or (city and city.recordId) then return nil,'Setup already attempted or showroom already placed.' end
 local fresh=M.survey(player,candidate.x,candidate.y)
 if not fresh then return nil,'Site changed; nothing cleared.' end
 -- Asset/inventory preflight before any irreversible clearing.
 local plan=require('AstroluxBayTest/ShowroomPlan12').plan(fresh.x,fresh.y)
 for _,piece in ipairs(plan.objects)do
  local sprite=getSprite(piece.sprite)
  if not sprite or sprite:getName()~=piece.sprite then return nil,'Missing structural sprite.' end
 end
 local prepared,why=require('AstroluxBayTest/ShowroomFurnishings12').prepare({x=fresh.x,y=fresh.y,replacementProfile=require('AstroluxBayTest/PerformanceSite').profile()})
 if not prepared then return nil,why end
 state.attempted=true;state.x=fresh.x;state.y=fresh.y
 state.clutter=#fresh.objects;state.items=#fresh.items;state.vehicles=#fresh.vehicles
 state.status='clearing'
 for _,entry in ipairs(fresh.items)do entry.sq:transmitRemoveItemFromSquare(entry.obj) end
 for _,entry in ipairs(fresh.objects)do entry.sq:RemoveTileObject(entry.obj);entry.sq:RecalcAllWithNeighbours(true) end
 for _,vehicle in ipairs(fresh.vehicles)do removeVehicle(player,vehicle) end
 state.status='placing'
 local record,reason=require('AstroluxBayTest/PerformanceSite').place(player,fresh.x,fresh.y)
 if not record then state.status='hold';return nil,reason end
 state.recordId=record.id;state.status='complete'
 print('[Astrolux Auto Place] Complete at '..fresh.x..','..fresh.y..'; clutter='..state.clutter..', items='..state.items..', empty vehicles='..state.vehicles)
 return record
end
function M.rearmCeilingFailure(state,city)
 M.rearmMannequinFailure(state,city)
 if not W.city() or not state or not state.attempted or state.ceilingRetryUsed or state.status~='hold'
  or (city and city.recordId) then return false end
 local err=state.error
 if type(err)~='string' or not err:find('Native furniture geometry rejected TSBAstroluxCeiling_0',1,true)
  or not err:find('Prototype objects rolled back.',1,true) then return false end
 for _,record in ipairs(require('TSBAstroluxStructure/Records').all())do
  if record.x==state.x and record.y==state.y then return false end
 end
 state.ceilingRetryUsed=true
 state.ceilingFailure={x=state.x,y=state.y,error=state.error,clutter=state.clutter,items=state.items,vehicles=state.vehicles}
 state.attempted=nil;state.status='retry-ready';state.error=nil
 print('[Astrolux Auto Place] One ceiling-fixture retry enabled after confirmed prototype rollback.')
 return true
end
function M.rearmMannequinFailure(state,city)
 if not W.city() or not state or not state.attempted or state.mannequinRetryUsed or state.status~='hold'
  or (city and city.recordId) then return false end
 local err=state.error
 if type(err)~='string' or not err:find('New furnishing contains unexpected items; paste cancelled',1,true)
  or not err:find('Prototype objects rolled back.',1,true) then return false end
 for _,record in ipairs(require('TSBAstroluxStructure/Records').all())do
  if record.x==state.x and record.y==state.y then return false end
 end
 state.mannequinRetryUsed=true
 state.mannequinFailure={x=state.x,y=state.y,error=state.error,clutter=state.clutter,items=state.items,vehicles=state.vehicles}
 state.attempted=nil;state.status='retry-ready';state.error=nil
 print('[Astrolux Auto Place] One mannequin-inventory retry enabled after confirmed prototype rollback.')
 return true
end
local ticks=0;local origins;local index=1;local best;local finished=false;local anchorX,anchorY
function M.tick()
 if finished or not W.city() then return end
 ticks=ticks+1;if ticks<600 then return end
 local player=getSpecificPlayer(0);if not player or player:isDead() then return end
 local state=ModData.get(stateKey);local city=ModData.get('TSBAstroluxCityPerformance.v1')
 M.rearmCeilingFailure(state,city)
 M.rearmMannequinFailure(state,city)
 if (state and state.attempted) or (city and city.recordId) then finished=true;return end
 if not origins then
  anchorX=math.floor(player:getX());anchorY=math.floor(player:getY());origins={}
  for dx=-26,14,4 do for dy=-26,14,4 do origins[#origins+1]={anchorX+dx,anchorY+dy} end end
 end
 if math.abs(player:getX()-anchorX)>2 or math.abs(player:getY()-anchorY)>2 then
  origins=nil;best=nil;index=1;ticks=0;return
 end
 for _=1,4 do
  local pos=origins[index]
  if not pos then
   finished=true
   if not best then player:Say('No safe outdoor showroom site nearby. Nothing cleared.');print('[Astrolux Auto Place] No eligible site near '..anchorX..','..anchorY);return end
   local ok,record,why=pcall(M.execute,player,best)
   if ok and record then player:Say('Performance showroom placed nearby. Wait for lighting to settle.')
   else
    local status=ModData.get(stateKey);if status and status.attempted then status.status='hold';status.error=tostring(ok and why or record) end
    player:Say('Automatic placement stopped. See the log; no automatic retry.')
    print('[Astrolux Auto Place] Stopped: '..tostring(ok and why or record))
   end
   return
  end
  local candidate=M.survey(player,pos[1],pos[2]);if candidate and (not best or candidate.score<best.score) then best=candidate end
  index=index+1
 end
end
if Events then Events.OnTick.Add(function()
 local ok,why=pcall(M.tick)
 if not ok then finished=true;print('[Astrolux Auto Place] Disabled after error: '..tostring(why)) end
end) end
return M
