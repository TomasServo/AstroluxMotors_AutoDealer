-- Lab-only provisioning: find placed signs across the showroom, including moved signs.
local M={};local ticks=0
local key='TSBAstroluxLabSignPowerV2'
function M.apply(o)
 if not o or not instanceof(o,'IsoLightSwitch') then return false end
 local sprite=o:getSprite();local name=sprite and sprite:getName()
 if not name or not name:match('^TSBAstroluxMotorsSign_[0-3]$') then return false end
 local md=o:getModData()
 return require('TSBAstroluxStructure/Electricity').retireTestBattery(o,md[key])
end
function M.update()
 if isClient() or isServer() or getNumActivePlayers()~=1 or not getWorld()
  or not require('AstroluxBayTest/TestWorld').enabled() then return end
 local s=ModData.get('TSBAstroluxCombined12.v1')
 local cell=getCell();if not cell or not s or not s.ready or not s.x or not s.y then return end
 for x=s.x,s.x+12 do for y=s.y,s.y+12 do
  local sq=cell:getGridSquare(x,y,0)
  if sq then local objects=sq:getObjects()
   for i=0,objects:size()-1 do M.apply(objects:get(i)) end
  end
 end end
end
if Events then Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%300==0 then
  local ok,why=pcall(M.update);if not ok then print('[Astrolux Sign Power] '..tostring(why)) end
 end
end)end
return M
