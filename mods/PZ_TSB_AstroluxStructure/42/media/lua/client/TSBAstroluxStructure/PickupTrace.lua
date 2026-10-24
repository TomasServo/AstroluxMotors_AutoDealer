-- Temporary showroom-only pickup diagnostics; no selection/visibility override.
local count=0
local seen={}
local function install()
 local C=ISMoveableCursor
 if not C then return false end
 if C.TSBAstroluxPickupTrace then return true end
 local original=C.getObjectList
 C.getObjectList=function(self,...)
  local result=original(self,...)
  local sq=self.currentSquare
  if not getDebug() or not sq or count>=80 then return result end
  local x,y,z=sq:getX(),sq:getY(),sq:getZ()
  local inside=false
  for _,r in ipairs((require 'TSBAstroluxStructure/Records').all())do
   local n=r.combinedSize or 8
   if r.status=='ready' and z==0 and x>=r.x and y>=r.y and x<=r.x+n and y<=r.y+n then inside=true;break end
  end
  if not inside then return result end
  local key=x..','..y..','..z..':'..tostring(self.canSeeCurrentSquare)..':'..#result
  if seen[key] then return result end
  seen[key]=true;count=count+1
  local names={};local objects=sq:getObjects()
  for i=0,objects:size()-1 do
   local sprite=objects:get(i):getSprite()
   if sprite then names[#names+1]=tostring(sprite:getName()) end
  end
  print('[Astrolux Pickup Trace] square='..key..' objects='..table.concat(names,','))
  return result
 end
 C.TSBAstroluxPickupTrace=true
 return true
end
local done=false
Events.OnGameStart.Add(function()if getDebug() then done=install() end end)
Events.OnTick.Add(function()if not done and getDebug() then done=install() end end)
