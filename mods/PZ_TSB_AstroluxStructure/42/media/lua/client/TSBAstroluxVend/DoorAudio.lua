-- Native IsoDoor playback keeps its positional attenuation and timing.
local Audio=require 'TSBAstroluxVend/AudioSettings'
local Clips=require 'TSBAstroluxVend/ClipVolume'
local D={ticks=0}
function D.pause()
 if D.handle then getSoundManager():stopUISound(D.handle);D.handle=nil end
end
function D.refresh()
 local player=getSpecificPlayer(0)
 if not player then return end
 local volume=Audio.playbackEnabled('doorSound',player) and Audio.playbackVolume('doorVolume',player) or 0
 Clips.set('TSBAstroluxSlidingGlassOpen',volume)
 Clips.set('TSBAstroluxSlidingGlassClose',volume)
 if volume==0 then D.pause()end
 return volume
end
function D.play()
 D.pause()
 if (D.refresh() or 0)>0 then D.handle=getSoundManager():playUISound('TSBAstroluxSlidingGlassOpen')end
end
Events.OnGameStart.Add(D.refresh)
Events.OnTick.Add(function()D.ticks=D.ticks+1;if D.ticks%10==0 then D.refresh()end end)
return D
