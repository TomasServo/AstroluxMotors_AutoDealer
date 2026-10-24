-- Local ambience follows actual ground-floor showroom entry, not kiosk UI.
local Audio=require 'TSBAstroluxVend/AudioSettings'
local Clips=require 'TSBAstroluxVend/ClipVolume'
local Records=require 'TSBAstroluxStructure/Records'
local M={sound=nil,ticks=0}
function M.inside(player,record)
    return player and not player:isDead() and player:getZ()==0
        and player:getX()>=record.x and player:getX()<record.x+8
        and player:getY()>=record.y and player:getY()<record.y+8
end
function M.stop()
    if M.sound then
        pcall(function()getSoundManager():stopUISound(M.sound)end)
        M.sound=nil
    end
end
function M.volume(player)
    -- Showroom ambience has its own saved control, independent of the vanilla
    -- soundtrack slider. Clip gain caps full menu volume at one quarter of file volume.
    if not Audio.playbackEnabled('showroomMusic',player)then return 0 end
    return Audio.playbackVolume('musicVolume',player)
end
function M.pause()
 M.paused=true;M.stop()
end
function M.play()
 M.paused=false;M.stop();M.update()
end
function M.update()
    if M.paused then M.stop();return end
    local volume=0
    if not Audio.enabled('showroomMusic')then M.stop();return end
    local inside=false
    local records=Records.all()
    for i=0,getNumActivePlayers()-1 do
        local player=getSpecificPlayer(i)
        for _,record in ipairs(records)do
            if M.inside(player,record)then inside=true;volume=math.max(volume,M.volume(player));break end
        end
    end
    if not inside or volume<=0 then M.stop();return end
    Clips.set('TSBAstroluxShowroomMusic',volume)
    local manager=getSoundManager()
    if not M.sound or not manager:isPlayingUISound(M.sound)then
        local sound=manager:playUISound('TSBAstroluxShowroomMusic')
        M.sound=sound and sound~=0 and sound or nil
    end
end
Events.OnTick.Add(function()
    M.ticks=M.ticks+1
    if M.ticks<30 then return end
    M.ticks=0
    pcall(M.update)
end)
Events.OnGameStart.Add(M.stop)
if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(M.stop)end
if Events.OnDisconnect then Events.OnDisconnect.Add(M.stop)end
return M
