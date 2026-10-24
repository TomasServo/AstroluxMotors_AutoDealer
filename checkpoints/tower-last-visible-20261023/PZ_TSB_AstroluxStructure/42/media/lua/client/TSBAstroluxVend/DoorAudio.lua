-- Keep native IsoDoor playback and 3D attenuation; adjust only our two sound definitions.
local Audio=require 'TSBAstroluxVend/AudioSettings'
local D={sounds={},ticks=0}
function D.refresh()
 local player=getSpecificPlayer(0)
 if not player then return end
 local volume=Audio.playbackEnabled('doorSound',player) and Audio.playbackVolume('doorVolume',player) or 0
 -- Use the same GameSound user-volume API as vanilla's advanced sound menu.
 if #D.sounds==0 then
  local sounds=GameSounds.getSoundsInCategory('Object')
  if sounds then for i=0,sounds:size()-1 do
   local sound=sounds:get(i);local name=sound:getName()
   if name=='TSBAstroluxSlidingGlassOpen' or name=='TSBAstroluxSlidingGlassClose'then D.sounds[#D.sounds+1]=sound end
  end end
 end
 for _,sound in ipairs(D.sounds)do sound:setUserVolume(volume)end
end
function D.pause()
 if D.handle then getSoundManager():stopUISound(D.handle);D.handle=nil end
end
function D.play()
 D.pause();D.refresh()
 D.handle=getSoundManager():playUISound('TSBAstroluxSlidingGlassOpen')
end
Events.OnGameStart.Add(D.refresh)
Events.OnTick.Add(function()D.ticks=D.ticks+1;if D.ticks%10==0 then D.refresh()end end)
return D
