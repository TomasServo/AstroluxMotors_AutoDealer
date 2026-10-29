-- Optional test map only. Terrain's vision mask is independent of CanSeeAll.
local Access=require 'TSBAstroluxStructure/TestLotAccess'
local M={}
local option='FBORenderChunk.RenderVisionPolygon'
local previous=nil
local warned=false
function M.restore()
 if previous~=nil then
  getDebugOptions():setBoolean(option,previous)
  previous=nil
 end
end
function M.update()
 local allowed=Access.map()and getNumActivePlayers()>0
 for i=0,getNumActivePlayers()-1 do
  local p=getSpecificPlayer(i)
  if not p or(isClient()and tostring(p:getAccessLevel()):lower()~='admin')then allowed=false end
 end
 if not allowed then M.restore();warned=false;return end
 if not isDebugEnabled()then
  M.restore()
  if not warned then
   print('[Astrolux test visibility] Terrain reveal requires launching the test client with debug enabled. CanSeeAll does not remove the terrain mask.')
   warned=true
  end
  return
 end
 local options=getDebugOptions()
 if previous==nil then previous=options:getBoolean(option)end
 options:setBoolean(option,false)
end
Events.OnTick.Add(M.update)
Events.OnMainMenuEnter.Add(M.restore)
Events.OnDisconnect.Add(M.restore)
return M
