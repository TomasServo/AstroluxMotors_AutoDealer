-- Change only Astrolux clip gain, using exposed native script reload methods.
-- GameSound user volume is ignored when advanced sound options are disabled.
local C={applied={}}
local specs={
 TSBAstroluxSlidingGlassOpen={'Object',false,true,'TSBAstroluxSlidingDoorCycle.wav',0.4875},
 TSBAstroluxSlidingGlassClose={'Object',false,true,'TSBAstroluxSlidingDoorCycle.wav',0.4875},
 TSBAstroluxPurchase={'UI',false,false,'TSBAstroluxPurchase.wav',0.5},
 TSBAstroluxShowroomMusic={'Music',true,false,'TSBAstroluxShowroomMusic.mp3',0.25},
}
function C.set(name,volume)
 local s=assert(specs[name],'Unknown Astrolux sound')
 volume=math.max(0,math.min(1,volume))
 if C.applied[name]==volume then return true end
 local script=ScriptManager.instance:getGameSound(name)
 if not script then return false end
 local body='sound '..name..' { category = '..s[1]..', loop = '..tostring(s[2])..', is3D = '..tostring(s[3])..', clip { file = media/sound/'..s[4]..', volume = '..string.format('%.8f',s[5]*volume)..','
 if s[3]then body=body..' distanceMin = 2, distanceMax = 18,'end
 body=body..' } }'
 script:reset()
 script:Load(name,body)
 GameSounds.OnReloadSound(script)
 C.applied[name]=volume
 return true
end
return C
