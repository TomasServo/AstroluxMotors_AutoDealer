-- Scope larger ceiling/cutaway bounds to this marked test-showroom record.
local V=require 'TSBAstroluxStructure/Visibility'
local originalInside,originalShell=V.inside,V.isShell
V.inside=function(player,r)
 if r.combinedSize~=11 then return originalInside(player,r) end
 return player:getZ()==0 and player:getX()>=r.x and player:getX()<r.x+11
  and player:getY()>=r.y and player:getY()<r.y+11
end
V.isShell=function(obj,r)
 if r.combinedSize~=11 then return originalShell(obj,r) end
 local md=obj:getModData();local sq=obj:getSquare()
 return md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='floor'
  and sq and sq:getZ()==1 and sq:getX()>=r.x and sq:getX()<r.x+11 and sq:getY()>=r.y and sq:getY()<r.y+11
end
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%30~=0 or isClient() or isServer() or not getWorld()
  or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
  if r.combinedSize==11 then
   for x=0,10 do for y=0,10 do
    local sq=getCell():getGridSquare(r.x+x,r.y+y,1);local list=sq and sq:getObjects()
    if list then for i=0,list:size()-1 do V.update(list:get(i),r) end end
   end end
  end
 end
end)
return V
