-- One-time native battery/bulb provisioning for pasted showroom floor lamps.
-- The temporary showroom has no native building electricity connection.
local M={}
function M.repair(o)
 if not o or not instanceof(o,'IsoLightSwitch') then return false end
 local sprite=o:getSprite();if not sprite or (sprite:getName()~='lighting_indoor_01_56' and sprite:getName()~='lighting_indoor_02_35') then return false end
 local md=o:getModData();local data=md.movableData
 if not data or not data.TSBAstroluxFurnishingV1 or data.TSBAstroluxLampProvisioned then return false end
 if not o:canSwitchLight() then
  if not o:hasLightBulb() then o:setBulbItemRaw('Base.LightBulb') end
  o:setCanBeModified(true);o:setUseBatteryDirect(true);o:setHasBatteryRaw(true);o:setPower(1)
  o:setPrimaryR(1);o:setPrimaryG(.95);o:setPrimaryB(.85)
  o:setActive(true)
 end
 data.TSBAstroluxLampProvisioned=true;o:transmitModData()
 return true
end
function M.update()
 if isClient() or isServer() or not getDebug() then return end
 local R=require 'TSBAstroluxStructure/Records';local cell=getCell();if not cell then return end
 for _,r in ipairs(R.all())do if r.status=='ready' then
  local n=r.combinedSize or 8
  for x=r.x,r.x+n-1 do for y=r.y,r.y+n-1 do
   local sq=cell:getGridSquare(x,y,0)
   if sq then local list=sq:getObjects();for i=0,list:size()-1 do M.repair(list:get(i))end end
  end end
 end end
end
Events.OnGameStart.Add(M.update)
Events.EveryOneMinute.Add(M.update)
return M
