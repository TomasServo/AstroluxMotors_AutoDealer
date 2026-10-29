-- Local test-save grant only. Never runs on a client/server or production world.
local M={}
local ticks=0
local key='TSBAstroluxTestMillion20261025'
function M.update()
 if isClient() or isServer() or not getDebug() or getNumActivePlayers()~=1 then return end
 if not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_LouisvillePerformance' then return end
 local player=getSpecificPlayer(0);if not player then return end
 local data=player:getModData()
 local state=data[key]
 if state and (state.done or state.hold) then return end
 if not state then state={bundles=0};data[key]=state end
 local ok,why=pcall(function()
  for i=1,math.min(100,1000-state.bundles) do
   local item=instanceItem('Base.MoneyBundle')
   assert(item,'Could not create test cash')
   item:setActualWeight(0);item:setCustomWeight(true)
   item:getModData().TSBAstroluxTestCashGrant=key
   assert(player:getInventory():AddItem(item)==item,'Test cash insertion failed')
   state.bundles=state.bundles+1
  end
  if state.bundles>=1000 then
   state.done=true
   player:Say('Astrolux test cash: $100,000 test grant complete.')
   print('[Astrolux Test Cash] Complete: 1000 weightless $100 bundles granted once.')
  end
 end)
 if not ok then state.hold=true;state.error=tostring(why);print('[Astrolux Test Cash] Held: '..state.error)end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%10==0 then M.update()end end)
return M
