-- Inspection view for the private test lot, not a dealership/server feature.
require 'TSBAstroluxTestMap/Config'
local W=require 'AstroluxBayTest/TestWorld'
local M={}
local previous
local journal
local settings={
 ['FBORenderChunk.NoLighting']=true,
 ['FBORenderChunk.RenderVisionPolygon']=false,
}
function M.restore()
 if not previous then return end
 local options=getDebugOptions()
 for name,value in pairs(previous)do options:setBoolean(name,value)end
 if journal then journal.previous=nil end
 previous=nil
 journal=nil
end
function M.apply()
 if not W.freshLot() or not getDebug() then M.restore();return end
 if previous then return end
 local options=getDebugOptions()
 -- Validate both native options before changing either one.
 for name in pairs(settings)do
  if not options:getOptionByName(name)then
   print('[Astrolux Test Lot] Inspection view unavailable: '..name)
   return
  end
 end
 -- Keep the original values through a debug Lua reload or a saved test session.
 journal=ModData.getOrCreate('TSBAstroluxTestMap.Presentation.v1')
 previous=journal.previous
 if type(previous)~='table' then
  previous={}
  for name in pairs(settings)do previous[name]=options:getBoolean(name)end
  journal.previous=previous
 end
 for name,value in pairs(settings)do options:setBoolean(name,value)end
 -- Do not save the debug settings file: this view belongs to this session/map.
 print('[Astrolux Test Lot] Inspection view: no line-of-sight darkness.')
end
Events.OnGameStart.Add(M.apply)
Events.OnMainMenuEnter.Add(M.restore)
-- OnResetLua fires in the newly loaded Lua environment; reapply if already in
-- this world, without trying to access an unloaded player at the main menu.
Events.OnResetLua.Add(function()
 if getSpecificPlayer(0) then M.apply()end
end)
return M
