local E=require 'TSBAstroluxStructure/Electricity'
local M={}
-- Native movable lamps placed on a tower-owned floor need the same grid rule.
function M.isTowerLamp(o)
 if not o or not instanceof(o,'IsoLightSwitch')or o:getObjectIndex()<0 or not o:getCanBeModified()then return false end
 local sp=o:getSprite();local n=sp and sp:getName()or ''
 if n:match('^TSBAstrolux')then return false end
 local sq=o:getSquare();local floor=sq and sq:getFloor()
 return floor~=nil and floor:getModData().TSBAstroluxFlooring~=nil
end
function M.supported(o)
 if not o or not instanceof(o,'IsoLightSwitch')or o:getObjectIndex()<0 then return false end
 if M.isTowerLamp(o)then return true end
 local sp=o:getSprite();local n=sp and sp:getName()
 return type(n)=='string'and(n:match('^TSBAstroluxMotorsSign_[0-3]$')~=nil or n:match('^TSBAstroluxCeilingSwitch_[0-3]$')~=nil)
end
function M.available(o)
 if not M.supported(o)or o:getUseBattery()or not o:getBulbItem()then return false end
 local s=o:getSquare();if not s then return false end
 if E.square(s)then return true end
 -- The installed wall switch can sit on the outside edge of the floor.
 if o:getModData().TSBAstroluxCeilingV1=='switch'then
  local cell=getCell()
  for _,d in ipairs({{0,-1},{-1,0},{0,1},{1,0}})do
   if E.square(cell:getGridSquare(s:getX()+d[1],s:getY()+d[2],s:getZ()))then return true end
  end
 end
 return false
end
return M
