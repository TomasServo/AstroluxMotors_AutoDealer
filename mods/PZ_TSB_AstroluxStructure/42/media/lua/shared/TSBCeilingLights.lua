-- Native fixtures own emission, electricity, bulbs, pickup and synchronization.
-- Both products ship this identical module; load exactly one set of handlers.
if TSBCeilingLights then return TSBCeilingLights end
local M={key='TSBCeilingLightsV1'}
TSBCeilingLights=M
local tracked=setmetatable({}, {__mode='k'})
M.colors={{153/255,148/255,142/255},{153/255,100/255,52/255}}
function M.isPanel(o)
 if not o or not instanceof(o,'IsoLightSwitch') then return false end
 local s=o:getSprite();local n=s and s:getName()
 return n and (n:match('^TSBLivingCeiling_[01]$') or n:match('^TSBAstroluxCeiling_[01]$'))~=nil or false
end
local function valid(o)
 local s=o and o:getSquare()
 return s and o:getObjectIndex()>=0 and getCell() and
  getCell():getGridSquare(s:getX(),s:getY(),s:getZ())==s
end
function M.resolveSwitch(panel)
 local sq=panel:getSquare();local binding=panel:getModData()[M.key]
 if binding and binding.switch then
  local b=binding.switch
  local s=getCell():getGridSquare(b.x,b.y,b.z)
  if not s then return nil,true end -- fail closed during streaming
  local objects=s:getObjects()
  for i=0,objects:size()-1 do local o=objects:get(i)
   local sprite=o:getSprite()
   if instanceof(o,'IsoLightSwitch') and not M.isPanel(o) and sprite and
    sprite:getName()==b.sprite then return o,true end
  end
  return nil,true -- deleted/replaced switch never silently rebinds
 end
 local room=sq:getRoom()
 if room then
  -- Native room list contains room switches, not independent table lamps.
  local switches=room:getLightSwitches()
  for i=0,switches:size()-1 do local o=switches:get(i)
   if valid(o) and not M.isPanel(o) then return o,true end
  end
 end
 return nil,false
end
function M.refresh(o)
 if not M.isPanel(o) or not valid(o) then tracked[o]=nil;return false end
 tracked[o]=true
 -- Bulb replacement and native pickup can carry bulb RGB. The panel's
 -- diffuser temperature remains the selected item variant.
 local index=tonumber(o:getSprite():getName():match('_(%d+)$'))
 local color=M.colors[index+1]
 -- The five installed showroom panels need stronger overlapping illumination.
 -- Keep the diffuser's RGB ratio; ordinary portable panels retain their output.
 local tag=o:getModData().TSBAstroluxCeilingV1
 if type(tag)=='string' and tag:match('^panel[1-5]$') then
  color={color[1]*1.65,color[2]*1.65,color[3]*1.65}
 end
 local changed=false
 if math.abs(o:getPrimaryR()-color[1])>0.001 then o:setPrimaryR(color[1]);changed=true end
 if math.abs(o:getPrimaryG()-color[2])>0.001 then o:setPrimaryG(color[2]);changed=true end
 if math.abs(o:getPrimaryB()-color[3])>0.001 then o:setPrimaryB(color[3]);changed=true end
 -- Native RGB setters update the source but do not invalidate lighting caches.
 -- Reapply the current state only after a color change; never toggle or refill.
 if changed then o:switchLight(o:isActivated()) end
 if isClient() then return true end
 local switch,linked=M.resolveSwitch(o)
 if linked then
  local on=switch~=nil and switch:isActivated()
  if o:isActivated()~=on then
   -- Force is needed to record OFF even during a blackout. Native update
   -- still checks the panel's own electricity and bulb before emitting.
   o:setActive(on,false,true)
  end
 end
 return true
end
function M.visit(sq)
 if not sq then return end
 local objects=sq:getObjects()
 for i=0,objects:size()-1 do M.refresh(objects:get(i)) end
end
function M.bind(panel,switch)
 if not M.isPanel(panel) or not switch or not instanceof(switch,'IsoLightSwitch') or M.isPanel(switch) then return false end
 local a,b=panel:getSquare(),switch:getSquare()
 if not a or not b or a:getZ()~=b:getZ() then return false end
 panel:getModData()[M.key]={switch={x=b:getX(),y=b:getY(),z=b:getZ(),sprite=switch:getSprite():getName()}}
 panel:transmitModData();M.refresh(panel);return true
end
-- Runtime texture alias for the showroom's native wall switch. No vanilla
-- pixels are copied into either product's package.
function M.bindSwitchArt(manager)
 if isServer() then return end
 manager=manager or IsoSpriteManager.instance
 if not manager then return end
 local map=manager:getNamedMap()
 for i=0,3 do
  local alias='TSBAstroluxCeilingSwitch_'..i
  local target=map:get(alias)
  if target and map:get('lighting_indoor_01_'..i) then
   target:LoadFramesNoDirPageSimple('lighting_indoor_01_'..i);target:setName(alias)
  end
 end
end
Events.OnLoadedTileDefinitions.Add(M.bindSwitchArt)
Events.LoadGridsquare.Add(M.visit)
Events.OnObjectAdded.Add(function(o) M.refresh(o) end)
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%15~=0 then return end
 for o in pairs(tracked) do M.refresh(o) end
end)
return M
