-- Pasted showrooms have no native room. Maintain the sink's native finite
-- reserve while municipal water is available; stop refilling at shutoff.
if isClient() then return end
local R=require 'TSBAstroluxStructure/Records'
local M={};local tracked=setmetatable({},{__mode='k'});local ticks=0
local function showroom(sq)
 for _,r in ipairs(R.all())do
  local size=r.combinedSize or 8
  if r.status=='ready' and sq:getZ()==0 and sq:getX()>=r.x and sq:getX()<r.x+size
   and sq:getY()>=r.y and sq:getY()<r.y+size then return true end
 end
 return false
end
function M.update(o)
 local sq=o and o:getSquare();local spr=o and o:getSprite()
 if not sq or not spr or o:getObjectIndex()<0 or not showroom(sq) then return false end
 if not string.match(spr:getName() or '', '^fixtures_sinks_') then return false end
 local props=spr:getProperties()
 if not props:has(IsoFlagType.waterPiped) then return false end
 -- Existing rain-barrel plumbing and non-water fluid contents remain native.
 if o:getUsesExternalWaterSource() or sq:isNoWater() then return true end
 if getGameTime():getWorldAgeDaysSinceBegin()>=getSandboxOptions():getWaterShutModifier() then return true end
 local fc=o:getFluidContainer();if fc and fc:getAmount()>0 then return true end
 local capacity=tonumber((props:get(IsoPropertyType.MAXIMUM_WATER_AMOUNT)))
  or tonumber((props:get(IsoPropertyType.WATER_AMOUNT)))
 if not capacity or capacity<=0 or capacity>=9999 then return true end
 local md=o:getModData()
 if md.canBeWaterPiped~=false or md.waterAmount~=capacity or md.waterMaxAmount~=capacity then
  md.canBeWaterPiped=false;md.waterMaxAmount=capacity;md.waterAmount=capacity
  o:transmitModData()
 end
 return true
end
function M.square(sq)
 if not sq or not showroom(sq) then return end
 local list=sq:getObjects()
 for i=0,list:size()-1 do local o=list:get(i);if M.update(o) then tracked[o]=true end end
end
function M.tick()
 ticks=ticks+1
 if ticks%30~=0 then return end
 for o in pairs(tracked)do if not M.update(o) then tracked[o]=nil end end
 if ticks~=30 and ticks%300~=0 then return end
 local cell=getCell();if not cell then return end
 for _,r in ipairs(R.all())do if r.status=='ready' then
  local size=r.combinedSize or 8
  for x=r.x,r.x+size-1 do for y=r.y,r.y+size-1 do M.square(cell:getGridSquare(x,y,0)) end end
 end end
end
Events.LoadGridsquare.Add(M.square)
Events.OnObjectAdded.Add(function(o)if M.update(o) then tracked[o]=true end end)
Events.OnTick.Add(M.tick)
return M
