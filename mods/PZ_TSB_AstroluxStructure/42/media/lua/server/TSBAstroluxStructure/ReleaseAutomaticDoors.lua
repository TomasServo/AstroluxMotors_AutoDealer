-- Opt-in safe-zone showroom mode. Settings are stored on the showroom record;
-- native IsoDoors continue to own collision, sprites and saved open state.
-- The current showroom package is a local test: do not enable it on MP servers.
if isClient()then return end
local Records=require 'TSBAstroluxStructure/Records'
local Entrances=require 'AstroluxBayTest/ShowroomEntrances12'
local Access=require 'TSBAstroluxVend/AdminAccess'
local Doors=require 'TSBAstroluxStructure/SlidingDoors'
local World=require 'AstroluxBayTest/TestWorld'
local M={radius=2,closeDelay=2000};local cycles={};local last=0

local function activeWorld()return not isClient()end
function M.record(player)
 if not activeWorld() or not Access.allowed(player) or not player or player:isDead() or player:getZ()~=0 then
  return nil,'Showroom administrator access required.'
 end
 local r=Records.near(player:getX(),player:getY());local size=r and (r.combinedSize or 8)
 if not r or r.status~='ready' or (size~=8 and size~=12)
  or player:getX()<r.x-3 or player:getX()>r.x+size+3 or player:getY()<r.y-3 or player:getY()>r.y+size+3 then
  return nil,'Stand at this showroom to change automatic doors.'
 end
 return r
end
function M.setEnabled(player,enabled)
 if type(enabled)~='boolean' then return nil,'Automatic doors requires an on/off value.' end
 local r,why=M.record(player);if not r then return nil,why end
 r.automaticDoorsEnabled=enabled;cycles[r.id]=nil
 return true
end
-- Euclidean distance to the full two-tile opening, from either side.
function M.distanceSquared(player,pair)
 if not player or player:isDead() or player:getZ()~=0 then return math.huge end
 local a=pair.leaves[1]
 local along=pair.north and player:getX()-a.x or player:getY()-a.y
 local across=pair.north and player:getY()-a.y or player:getX()-a.x
 local beyond=math.max(-along,0,along-2)
 return beyond*beyond+across*across
end
local function leaves(r,pair)
 if r.closedEntrances and r.closedEntrances[pair.edge] then return end
 local found={}
 for _,leaf in ipairs(pair.leaves)do
  local sq=getCell():getGridSquare(leaf.x,leaf.y,0);if not sq then return end
  local list=sq:getObjects();local match
  for i=0,list:size()-1 do
   local o=list:get(i);local d=o:getModData();local sp=o:getSprite();local name=sp and sp:getName()
   if d.TSBAstroluxStructure==r.id and d.TSBAstroluxStructureKind=='slidingDoor'
    and instanceof(o,'IsoDoor') and o:getObjectIndex()>=0 and o:getNorth()==pair.north
    and (name=='TSBAstroluxSlidingDoor_'..leaf.base or name=='TSBAstroluxSlidingDoor_'..(leaf.base+2))then
    if match then return end;match=o
   end
  end
  if not match or match:isDestroyed() or match:isBarricaded() or match:isLocked() or match:isLockedByKey()
   or not match:getOppositeSquare()then return end
  found[#found+1]=match
 end
 if #found~=2 or Doors.partner(found[1],getCell())~=found[2]then return end
 return found[1],found[2]
end
local function obstructed(a,b,pair,closing)
 for _,o in ipairs({a,b})do
  if IsoDoor.isDoorObstructed(o)then return true end
  if closing then
   for _,sq in ipairs({o:getSquare(),o:getOppositeSquare()})do
    if not sq then return true end
    for _,list in ipairs({sq:getMovingObjects(),sq:getStaticMovingObjects()})do
     for i=0,list:size()-1 do
      local obj=list:get(i);local p=pair.leaves[1]
      local along=pair.north and obj:getX()-p.x or obj:getY()-p.y
      local across=pair.north and obj:getY()-p.y or obj:getX()-p.x
      if obj:getZ()==0 and along>=-.3 and along<=2.3 and math.abs(across)<=.6 then return true end
     end
    end
   end
  end
 end
 return false
end
local function sync(o)
 o:syncIsoObject(false,0,nil,nil);o:getSquare():RecalcAllWithNeighbours(true)
 if not isServer()then o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)end
end
local function setOpen(a,b,desired)
 local before={a:IsOpen(),b:IsOpen()};local changed=false
 local ok,err=pcall(function()
  for _,o in ipairs({a,b})do
   if o:IsOpen()~=desired then
    o:ToggleDoorSilent();assert(o:IsOpen()==desired,'Native leaf refused automatic state')
    sync(o);changed=true
   end
  end
 end)
 if not ok then
  local restored=true
  for i,o in ipairs({a,b})do
   local undo=pcall(function()
    if o:IsOpen()~=before[i]then o:ToggleDoorSilent()end
    assert(o:IsOpen()==before[i],'Native rollback failed');sync(o)
   end)
   restored=restored and undo
  end
  print('[Astrolux automatic doors] Native transition refused; restored='..tostring(restored)..': '..tostring(err))
  return false,not restored
 end
 if changed then
  -- One positional sound per pair, honoring the existing door clip volume.
  -- Silent native toggles avoid borrowing a distant player's sound emitter.
  pcall(function()getSoundManager():PlayWorldSound('TSBAstroluxSlidingGlass'..(desired and 'Open' or 'Close'),a:getSquare(),0,18,1,false)end)
 end
 return true,false
end
function M.update(now,players)
 if not activeWorld()then return end
 local keep={}
 for _,r in ipairs(Records.all())do
  if r.releaseTower and r.status=='ready' and r.automaticDoorsEnabled==true and ((r.combinedSize or 8)==8 or r.combinedSize==12)then
   keep[r.id]=true;local states=cycles[r.id] or {};cycles[r.id]=states
   for _,pair in ipairs(Entrances.plan(r))do
    local a,b=leaves(r,pair)
    if not a then states[pair.edge]=nil
    else
     local state=states[pair.edge]
     if not state or state.a~=a or state.b~=b then state={a=a,b=b};states[pair.edge]=state end
     local nearby=false
     for _,player in ipairs(players)do if M.distanceSquared(player,pair)<=M.radius*M.radius then nearby=true;break end end
     if nearby then state.emptySince=nil
     elseif not state.emptySince or now<state.emptySince then state.emptySince=now end
     local desired=nearby or now-state.emptySince<M.closeDelay
     if (nearby or not desired) and not state.hold and (not state.retryAt or now>=state.retryAt)
      and (a:IsOpen()~=desired or b:IsOpen()~=desired) and not obstructed(a,b,pair,not desired)then
      local ok,hold=setOpen(a,b,desired);state.hold=hold;state.retryAt=not ok and (now+1000) or nil
     end
    end
   end
  end
 end
 for id in pairs(cycles)do if not keep[id]then cycles[id]=nil end end
end
Events.OnTick.Add(function()
 if not activeWorld()then return end
 local now=getTimestampMs();if now>=last and now-last<100 then return end;last=now
 local players={}
 if isServer()then local online=getOnlinePlayers();for i=0,online:size()-1 do players[#players+1]=online:get(i)end
 else for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i);if p then players[#players+1]=p end end end
 M.update(now,players)
end)
return M
