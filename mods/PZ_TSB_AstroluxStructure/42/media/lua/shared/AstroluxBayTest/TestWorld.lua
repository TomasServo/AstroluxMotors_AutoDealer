local M={}
-- Opt-in, separate map only. Never infer authorization from a save name.
function M.testMap()
 local config=rawget(_G,'TSBAstroluxOptionalTestMap')
 return config and config.id=='PZ_TSB_AstroluxTestMap' and getWorld()
  and tostring(getWorld():getMap())=='Astrolux Test Lot'
  and not isClient() and not isServer() and getNumActivePlayers()==1
end
function M.city()
 return getWorld and getWorld() and tostring(getWorld():getWorld())=='AstroluxStructureLab_LouisvillePerformance'
  and not isClient() and not isServer() and getDebug() and getNumActivePlayers()==1
end
-- Private profile only: explicitly requested building paste in the corner lab.
function M.freshLot()
 local config=rawget(_G,'TSBAstroluxOptionalTestMap')
 return M.testMap() and config.manualPaste==true
end
function M.corner()
 return getWorld and getWorld() and (tostring(getWorld():getWorld())=='AstroluxDiagonalCornerLab_20261027' or M.freshLot())
  and not isClient() and not isServer() and getDebug() and getNumActivePlayers()==1
end
function M.enabled()
 if not getWorld or not getWorld() then return false end
 return tostring(getWorld():getWorld())=='AstroluxStructureLab_12x12_FourSides' or M.city() or M.testMap() or M.corner()
end
return M
