-- Local Astrolux test-world validation; no global material/drop overrides.
if isClient() or isServer() then return end
local M={};local tracked=setmetatable({},{__mode='k'});local ticks=0
local key='TSBAstroluxDebrisV1'
local function enabled()
 return (getDebug() or require('AstroluxBayTest/TestWorld').testMap()) and getNumActivePlayers()==1 and require('AstroluxBayTest/TestWorld').enabled()
end
local function owned(o)
 if not o or not o:getSquare() then return false end
 local md=o:getModData()
 return md.TSBAstroluxStructure and
  ((instanceof(o,'IsoWindow') and md.TSBAstroluxStructureKind=='window') or
   (instanceof(o,'IsoDoor') and md.TSBAstroluxStructureKind=='slidingDoor'))
end
local function squares(o)
 local sq=o:getSquare();local other=o:getOppositeSquare();local out,seen={},{}
 local function add(s)if s and not seen[s] then seen[s]=true;out[#out+1]=s end end
 add(sq);add(other)
 -- Stay beside the affected opening rather than scattering across the room.
 for _,s in ipairs({sq,other})do if s then
  for _,d in ipairs({-1,1})do
   add(getCell():getGridSquare(s:getX()+(o:getNorth() and d or 0),s:getY()+(o:getNorth() and 0 or d),s:getZ()))
  end
 end end
 return out
end
local function snapshot(o)
 local snap={glass={},hinges={}}
 for _,sq in ipairs(squares(o))do local glass=sq:getBrokenGlass();if glass then snap.glass[glass]=true end end
 local list=o:getSquare():getWorldObjects()
 for i=0,list:size()-1 do local object=list:get(i);local item=object:getItem()
  if item and item:getFullType()=='Base.Hinge' then snap.hinges[object]=true end
 end
 return snap
end
function M.track(o)
 if not enabled() or not owned(o) or tracked[o] then return end
 local md=o:getModData();local state=md[key]
 if not state then
  -- Existing damage is a baseline, never a retroactive loot grant.
  state={broken=o:isDestroyed(),cleared=instanceof(o,'IsoWindow') and o:isGlassRemoved() or false}
  md[key]=state
 end
 tracked[o]={state=state,before=snapshot(o)}
end
local function glass(o,before,wanted,countNative)
 local added=0
 if countNative then
  for _,sq in ipairs(squares(o))do local g=sq:getBrokenGlass()
   if g and not before.glass[g] then added=added+1 end
  end
 end
 for _,sq in ipairs(squares(o))do
  if added>=wanted then break end
  if not sq:getBrokenGlass() then
   local g=sq:addBrokenGlass()
   if g then added=added+1 end
  end
 end
 if added<wanted then print('[Astrolux Debris] No free nearby tile for '..(wanted-added)..' glass pile(s); no deferred respawn.') end
end
function M.update(o)
 local entry=tracked[o];if not entry then return end
 local state=entry.state
 if state.hold then return end
 local ok,why=pcall(function()
  if o:isDestroyed() and not state.broken then
   state.broken=true -- consume event before creating loot; never duplicate on failure
   glass(o,entry.before,2,true)
   if instanceof(o,'IsoDoor') then
    local list=o:getSquare():getWorldObjects();local native=0
    for i=0,list:size()-1 do local object=list:get(i);local item=object:getItem()
     if item and item:getFullType()=='Base.Hinge' and not entry.before.hinges[object] then native=native+1 end
    end
    for i=1,math.max(0,2-native)do
     assert(o:getSquare():AddWorldInventoryItem('Base.Hinge',0,0,0),'Hinge drop failed')
    end
   end
  end
  if instanceof(o,'IsoWindow') and o:isGlassRemoved() and not state.cleared then
   state.cleared=true;glass(o,entry.before,1,false)
  end
 end)
 if not ok then state.hold=tostring(why);print('[Astrolux Debris] Held: '..state.hold) end
 if o:getObjectIndex()<0 then tracked[o]=nil else entry.before=snapshot(o) end
end
local function scan(sq)
 if not enabled() or not sq then return end
 local list=sq:getObjects();for i=0,list:size()-1 do M.track(list:get(i)) end
end
Events.LoadGridsquare.Add(scan)
Events.OnWeaponHitThumpable.Add(function(_,_,o)
 if not enabled() then return end
 M.track(o);if tracked[o] then tracked[o].before=snapshot(o) end
end)
Events.OnObjectAboutToBeRemoved.Add(function(o)
 if enabled() and tracked[o] and o:isDestroyed() then M.update(o) end
end)
Events.OnTick.Add(function()
 if not enabled() then return end
 ticks=ticks+1
 if ticks%30==1 then
  for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
   if r.status=='ready' then
    local size=r.combinedSize or 8
    for n=0,size do
     scan(getCell():getGridSquare(r.x+n,r.y,0));scan(getCell():getGridSquare(r.x+n,r.y+size,0))
     if n>0 and n<size then
      scan(getCell():getGridSquare(r.x,r.y+n,0));scan(getCell():getGridSquare(r.x+size,r.y+n,0))
     end
    end
   end
  end
 end
 if ticks%5~=0 then return end
 for o in pairs(tracked)do
  if o:getObjectIndex()<0 then tracked[o]=nil else M.update(o) end
 end
end)
return M
