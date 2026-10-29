-- Defaults for the private manual-paste test lot only.
require 'TSBAstroluxTestMap/Config'
local W=require 'AstroluxBayTest/TestWorld'
local M={}
function M.apply()
 if not W.freshLot() then return end
 local state=ModData.getOrCreate('TSBAstroluxTestMap.Defaults.v1')
 -- Upgrade existing test saves as well as new ones. Later deliberate sandbox
 -- changes remain available to the user; this is not a per-tick weather lock.
 if state.visibilityDefaultsVersion==2 then return end
 local options=getSandboxOptions()
 options:set('Map.MapAllKnown',true)
 options:set('MaxFogIntensity',4) -- Native "None" option in Build 42.21.
 options:toLua()
 state.mapKnownApplied=true
 state.visibilityDefaultsVersion=2
 print('[Astrolux Test Lot] Map revealed; weather fog disabled.')
end
Events.OnGameStart.Add(M.apply)
return M
