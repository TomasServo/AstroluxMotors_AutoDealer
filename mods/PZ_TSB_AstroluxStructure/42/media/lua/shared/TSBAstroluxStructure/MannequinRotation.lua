local R=require 'TSBAstroluxStructure/Records'
local M={channel='TSBAstroluxMannequin',directions={'N','NE','E','SE','S','SW','W','NW'}}
function M.showroom(o)
 if not o or not instanceof(o,'IsoMannequin') or o:getObjectIndex()<0 then return false end
 local sq=o:getSquare();if not sq or sq:getZ()~=0 then return false end
 for _,r in ipairs(R.all())do local size=r.combinedSize or 8
  if r.status=='ready' and sq:getX()>=r.x and sq:getX()<r.x+size and sq:getY()>=r.y and sq:getY()<r.y+size then return true end
 end
 return false
end
function M.allowed(player,o,direction)
 local valid=false;for _,name in ipairs(M.directions)do if name==direction then valid=true;break end end
 if not valid or not player or player:isDead() or not M.showroom(o)then return false end
 local sq=o:getSquare()
 if math.floor(player:getZ())~=sq:getZ() or (player:getX()-sq:getX()-0.5)^2+(player:getY()-sq:getY()-0.5)^2>9 then return false end
 if sq:getObjects():get(o:getObjectIndex())~=o then return false end
 if ((isClient and isClient()) or (isServer and isServer())) and SafeHouse and SafeHouse.isSafeHouse(sq,player:getUsername(),true)then return false end
 return true
end
function M.apply(player,o,direction)
 if not M.allowed(player,o,direction)then return false end
 -- Native rotate updates the persistent direction and broadcasts on a server.
 -- Do not use setRenderDirection: that changes only the temporary preview.
 o:rotate(IsoDirections[direction])
 return o:getDir()==IsoDirections[direction]
end
return M
