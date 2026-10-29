local Electricity=require 'TSBAstroluxStructure/Electricity'
-- Local ambience follows actual ground-floor showroom entry, not kiosk UI.
local Audio=require 'TSBAstroluxVend/AudioSettings'
local Clips=require 'TSBAstroluxVend/ClipVolume'
local Records=require 'TSBAstroluxStructure/Records'
local M={sound=nil,ticks=0}
function M.inside(player,record)
    local size=record.combinedSize or 8
    return player and not player:isDead() and player:getZ()==0
        and player:getX()>=record.x and player:getX()<record.x+size
        and player:getY()>=record.y and player:getY()<record.y+size
end
-- Smooth distance falloff outside the footprint; never use camera zoom.
function M.attenuation(player,record)
    if not player or player:isDead() or player:getZ()~=0 then return 0 end
    local size=record.combinedSize or 8
    local dx=math.max(record.x-player:getX(),0,player:getX()-record.x-size)
    local dy=math.max(record.y-player:getY(),0,player:getY()-record.y-size)
    local t=math.min(1,math.sqrt(dx*dx+dy*dy)/6)
    return 1-t*t*(3-2*t)
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
    local volume=0;local track=Audio.track()
    if not Audio.enabled('showroomMusic')then M.stop();return end
    local nearby=false
    local records={}
    for _,record in ipairs(Records.all())do
        if Electricity.showroom(record) then records[#records+1]=record end
    end
    for i=0,getNumActivePlayers()-1 do
        local player=getSpecificPlayer(i)
        for _,record in ipairs(records)do
            local gain=M.attenuation(player,record)
            if gain>0 then nearby=true;local v=M.volume(player)*gain;if v>volume then volume=v;track=Audio.playbackTrack(player)end end
        end
    end
    if not nearby or volume<=0 then M.stop();return end
    local name=track==2 and 'TSBAstroluxElevatorMusic' or 'TSBAstroluxShowroomMusic'
    if M.track~=name then M.stop();M.track=name end
    Clips.set(name,volume)
    local manager=getSoundManager()
    if not M.sound or not manager:isPlayingUISound(M.sound)then
        local sound=manager:playUISound(name)
        M.sound=sound and sound~=0 and sound or nil
    end
end
Events.OnTick.Add(function()
    M.ticks=M.ticks+1
    if M.ticks<6 then return end
    M.ticks=0
    pcall(M.update)
end)
Events.OnGameStart.Add(M.stop)
if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(M.stop)end
if Events.OnDisconnect then Events.OnDisconnect.Add(M.stop)end
return M
