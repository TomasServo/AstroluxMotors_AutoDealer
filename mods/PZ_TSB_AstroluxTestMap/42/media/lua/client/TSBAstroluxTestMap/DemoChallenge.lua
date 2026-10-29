if isClient()or isServer()then return end
local C={id='AstroluxMotorsDemo',gameMode='Astrolux Motors Auto Dealer',world='Astrolux Test Lot',x=135,y=135,z=0,hourOfDay=12,zombiesMinPerChunk=0,zombiesMaxPerChunk=0,image='media/textures/Item_TSBAstroluxLogoRug.png'}
function C.OnInitWorld()
 SandboxVars.Zombies=6
 SandboxVars.ZombieConfig=SandboxVars.ZombieConfig or {}
 SandboxVars.ZombieConfig.PopulationMultiplier=0
 SandboxVars.ZombieConfig.RespawnHours=0
 SandboxVars.StartTime=4
 SandboxVars.ElecShutModifier=2147483647
 SandboxVars.WaterShutModifier=2147483647
 SandboxVars.Map=SandboxVars.Map or {};SandboxVars.Map.MapAllKnown=true
 SandboxVars.MaxFogIntensity=4
end
function C.AddPlayer()end
function C.RemovePlayer()end
function C.Render()end
function C.Init()end
function C.onBackButtonWheel()end
Events.OnChallengeQuery.Add(function()addChallenge(C)end)
return C
