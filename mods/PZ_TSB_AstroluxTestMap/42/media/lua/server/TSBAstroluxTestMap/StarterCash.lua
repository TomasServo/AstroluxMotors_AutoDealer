local W=require 'AstroluxBayTest/TestWorld'
local C=require 'TSBAstroluxTestMap/Config'
local Demo=require 'TSBAstroluxTestMap/DemoReady'
local M={};local ticks=0
local key='TSBAstroluxTestMap.StarterCash.v1'
function M.update()
 if not W.freshLot() or C.bundledDemo~=true or not Demo.update()then return end
 local p=getSpecificPlayer(0);if not p or p:isDead() then return end
 local md=p:getModData();local s=md[key]
 if s and (s.done or s.hold) then return end
 if not s then s={bundles=0};md[key]=s end
 -- Mark each insertion before calling Java. An uncertain insertion is held,
 -- never retried automatically, so it cannot award a duplicate cash batch.
 if s.pending then s.hold='Previous cash insertion was interrupted';return end
 local ok,why=pcall(function()
  for n=1,math.min(25,250-s.bundles)do
   local item=assert(instanceItem('Base.MoneyBundle'),'Native $100 bundle unavailable')
   item:setActualWeight(0);item:setCustomWeight(true)
   item:getModData().TSBAstroluxTestMapGrant={key=key,sequence=s.bundles+1}
   s.pending=s.bundles+1
   assert(p:getInventory():AddItem(item)==item,'Starter cash insertion not confirmed')
   s.bundles=s.pending;s.pending=nil
  end
  if s.bundles==250 then s.done=true;p:Say('Welcome to Astrolux. You have $25,000 to try the dealership.') end
 end)
 if not ok then s.hold=tostring(why);print('[Astrolux Test Map] Cash held: '..s.hold) end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%30==0 then M.update() end end)
return M
