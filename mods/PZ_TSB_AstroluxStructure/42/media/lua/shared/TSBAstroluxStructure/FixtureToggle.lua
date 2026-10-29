require 'TimedActions/ISToggleLightAction'
local Power=require 'TSBAstroluxStructure/FixturePower'
local complete=ISToggleLightAction.complete
function ISToggleLightAction:complete()
 local o=self.object
 if Power.available(o)and not o:canSwitchLight()then
  local p=self.character;local s=o:getSquare()
  if not p or p:getZ()~=s:getZ()or(p:getX()-s:getX())^2+(p:getY()-s:getY())^2>9 then return false end
  -- Retain the native saved state and native multiplayer synchronization.
  o:setActive(not o:isActivated(),false,true)
  return true
 end
 return complete(self)
end
