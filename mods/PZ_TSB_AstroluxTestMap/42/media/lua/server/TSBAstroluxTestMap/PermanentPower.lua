-- Private test world: permanent municipal power, ordinary generators supported.
require 'TSBAstroluxTestMap/Config'
local W=require 'AstroluxBayTest/TestWorld'
local Native=require 'TSBAstroluxTestMap/NativeRoom'
local M={};local ticks=0
function M.settings()
 if not W.freshLot()then return false end
 local options=getSandboxOptions()
 options:set('ElecShut',9)
 options:set('ElecShutModifier',options:randomElectricityShut(9))
 options:toLua()
 getWorld():setHydroPowerOn(true)
 return true
end
function M.update()
 if not M.settings() or not Native.update()then return false end
 local state=ModData.getOrCreate('TSBAstroluxTestMap.PermanentPower.v1')
 local units=state.units or {};local removed={}
 for id,p in pairs(units)do
  local sq=getCell():getGridSquare(p.x,p.y,0)
  if sq then
   local list=sq:getObjects()
   for i=list:size()-1,0,-1 do
    local o=list:get(i)
    if instanceof(o,'IsoGenerator')and o:getModData().TSBAstroluxTestPowerV1==id then
     o:setActivated(false)
     o:setConnected(false)
     o:setSurroundingElectricity()
     sq:transmitRemoveItemFromSquare(o)
     print('[Astrolux Test Power] Removed tagged test generator; native grid confirmed.')
    end
   end
   removed[#removed+1]=id
  end
 end
 for _,id in ipairs(removed)do units[id]=nil end
 state.gridOnlyRevision=1
 return true
end
local function update()
 local ok,why=pcall(M.update)
 if not ok then print('[Astrolux Test Power] Grid conversion deferred: '..tostring(why))end
end
Events.OnGameStart.Add(update)
Events.OnTick.Add(function()ticks=ticks+1;if ticks%60==0 then update()end end)
Events.EveryTenMinutes.Add(update)
return M
