-- Commit real native orientation, independently of cursor preview/timed actions.
local Native=require 'TSBAstroluxStructure/MannequinRotation'
local M={directions=Native.directions,showroom=Native.showroom}
function M.rotate(player,o,direction)
 if not Native.allowed(player,o,direction)then return false end
 if isClient()then
  local sq=o:getSquare()
  sendClientCommand(player,Native.channel,'rotate',{x=sq:getX(),y=sq:getY(),z=sq:getZ(),index=o:getObjectIndex(),direction=direction})
 else
  if not Native.apply(player,o,direction)then return false end
 end
 ISMoveableCursor.clearCacheForAllPlayers()
 return true
end
Events.OnFillWorldObjectContextMenu.Add(function(n,context,objects,test)
 if test then return end
 local player=getSpecificPlayer(n)
 if not player or player:isDead() then return end
 local candidates,seen={},{}
 local function add(o)
  if o and not seen[o]then seen[o]=true;candidates[#candidates+1]=o end
 end
 for _,picked in ipairs(objects)do
  add(picked)
  -- The native world picker often supplies the floor/window, not the 3D mannequin.
  local sq=picked and picked:getSquare()
  local list=sq and sq:getObjects()
  if list then for i=0,list:size()-1 do add(list:get(i))end end
 end
 -- 3D mannequins can be absent from the world picker entirely. Offer nearby
 -- showroom mannequins explicitly, including when only pavement was picked.
 for x=math.floor(player:getX())-3,math.floor(player:getX())+3 do
  for y=math.floor(player:getY())-3,math.floor(player:getY())+3 do
   local sq=getCell():getGridSquare(x,y,math.floor(player:getZ()))
   local list=sq and sq:getObjects()
   if list then for i=0,list:size()-1 do local o=list:get(i)
    if Native.allowed(player,o,'N')then add(o)end
   end end
  end
 end
 for _,o in ipairs(candidates)do
  if M.showroom(o)then
   local option=context:addOption('Face Showroom Mannequin ('..o:getSquare():getX()..', '..o:getSquare():getY()..')',nil,nil)
   local submenu=ISContextMenu:getNew(context)
   context:addSubMenu(option,submenu)
   for _,direction in ipairs(M.directions)do
    local face=direction;local mannequin=o
    submenu:addOption(face,player,function(p)
     if not M.rotate(p,mannequin,face)then p:Say('Stand beside the showroom mannequin to rotate it.')end
    end)
   end
  end
 end
end)
return M
