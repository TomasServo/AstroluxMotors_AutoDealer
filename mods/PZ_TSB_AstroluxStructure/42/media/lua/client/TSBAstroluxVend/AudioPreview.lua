-- Compatibility module name retained; these control actual local playback.
local Music=require 'TSBAstroluxStructure/ShowroomMusic'
local Audio=require 'TSBAstroluxVend/AudioSettings'
local P={}
function P.pause(kind)
 if kind=='door'then require('TSBAstroluxVend/DoorAudio').pause()elseif kind=='music'then Music.pause()else Audio.pausePurchase()end
end
function P.play(kind)
 if kind=='door'then require('TSBAstroluxVend/DoorAudio').play()elseif kind=='music'then Music.play()else Audio.resumePurchase()end
end
-- Sliders are saved through the existing server settings action.
function P.level()end
-- Closing/hiding a menu must not stop or restart actual audio.
function P.stopAll()end
return P
