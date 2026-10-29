-- Private MP import of the frozen accepted 2026-10-29 demonstration save.
-- Register its existing record only: never rebuild, repaste, or move objects.
if not isServer() then return end
local function import()
 if tostring(getWorld():getMap())~='Astrolux Test Lot' then return end
 local db=ModData.getOrCreate('TSBAstroluxStructure.Lab.v1')
 local r=db.tower
 if not r or r.id~='structure:118:121' or r.x~=118 or r.y~=121
  or r.combinedSize~=12 or r.status~='ready' then return end
 r.releaseTower=1
 local s=ModData.getOrCreate('TSBAstroluxAcceptedMP.v1')
 if not s.powerInitializedV2 then
  local options=getSandboxOptions()
  options:set('ElecShut',9)
  options:set('ElecShutModifier',options:randomElectricityShut(9))
  options:toLua()
  getWorld():setHydroPowerOn(true)
  s.powerInitializedV2=true
 end
 print('[Astrolux Accepted MP] Registered existing source-of-truth tower 118,121; no rebuild.')
end
Events.OnServerStarted.Add(import)
return {import=import}
