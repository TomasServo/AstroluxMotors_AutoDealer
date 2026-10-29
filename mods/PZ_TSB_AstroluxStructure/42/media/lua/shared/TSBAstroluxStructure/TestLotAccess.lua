local M={}
function M.map()
 local config=rawget(_G,'TSBAstroluxOptionalTestMap')
 return config and config.id=='PZ_TSB_AstroluxTestMap'and getWorld()and tostring(getWorld():getMap())=='Astrolux Test Lot'
end
function M.placement(p)
 if not M.map()or isClient()then return false end
 if require('AstroluxBayTest/TestWorld').testMap()then return true end
 return TSBAstroluxReleasePlacementActor==p and require('TSBAstroluxStructure/ReleaseAccess').allowed(p)
end
return M
