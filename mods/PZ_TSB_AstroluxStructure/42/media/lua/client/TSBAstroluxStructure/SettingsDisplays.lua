-- Local debug-showroom controls; do not advertise multiplayer enforcement.
local M={}
local R=require 'TSBAstroluxStructure/Records'
function M.objects(player)
 if isClient() or isServer() or not getDebug() or not player or player:isDead() or player:getZ()~=0 then return nil,'Available in the local debug showroom.' end
 local r=R.near(player:getX(),player:getY());local n=r and (r.combinedSize or 8)
 if not r or r.status~='ready' or player:getX()<r.x-3 or player:getX()>r.x+n+3 or player:getY()<r.y-3 or player:getY()>r.y+n+3 then return nil,'Stand at the showroom to change its displays.' end
 local out={}
 for x=r.x,r.x+n-1 do for y=r.y,r.y+n-1 do
  local sq=getCell():getGridSquare(x,y,0)
  if not sq then return nil,'Load the whole showroom before changing its displays.' end
  local list=sq:getObjects()
  for i=0,list:size()-1 do local o=list:get(i);if instanceof(o,'IsoMannequin')then out[#out+1]=o end end
 end end
 return out
end
function M.status(player)
 local objects,reason=M.objects(player);if not objects then return false,reason,false end
 local L=require 'TSBAstroluxStructure/MannequinLock';local count=0
 for _,o in ipairs(objects)do if L.locked(o)then count=count+1 end end
 if #objects==0 then return false,'No showroom mannequins found.',false end
 return count==#objects,tostring(count)..' of '..tostring(#objects)..' display outfits locked.',true
end
function M.set(player,value)
 local objects,reason=M.objects(player);if not objects then return false,reason end
 local L=require 'TSBAstroluxStructure/MannequinLock'
 for _,o in ipairs(objects)do o:getModData()[L.key]=value==true or nil;o:transmitModData()end
 return true
end
return M
