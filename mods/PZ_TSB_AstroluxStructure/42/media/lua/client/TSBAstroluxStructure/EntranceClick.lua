if isClient() or isServer() then return end
local E=require 'TSBAstroluxStructure/Entrances'
local C={}
local lastClick={}
function C.click(object,player,x,y)
    -- A picked Astrolux sign takes precedence over the projected doorway plane.
    -- Fall through to vanilla doClickLightSwitch and its normal timed action.
    if object and instanceof(object,'IsoLightSwitch') then
        local sprite=object:getSprite();local name=sprite and sprite:getName()
        if type(name)=='string' and name:match('^TSBAstroluxMotorsSign_[0-3]$') then return false end
    end
    if not player or player:isDead() or player:getZ()~=0 or player:isAiming()
        or player:isIgnoreContextKey() or not player:getCurrentSquare() then return false end
    local speed=UIManager.getSpeedControls()
    if speed and speed:getCurrentGameSpeed()==0 then return false end
    if not (tostring(getWorld():getWorld()):match('^AstroluxStructureLab') or require('AstroluxBayTest/TestWorld').testMap() or require('AstroluxBayTest/TestWorld').corner()) then return false end
    local r=require('TSBAstroluxStructure/Records').near(player:getX(),player:getY())
    if not r or r.status~='ready' or not r.slidingDoorsRevision then return false end
    -- Project the entire doorway plane, including its empty center at handle
    -- height. A picked floor/background object is not required to be a leaf.
    -- Native door clicks retain their own actions and pair synchronization.
    if object and instanceof(object,'IsoDoor') then return false end
    local pair=E.screenHit(r,x,y,function(wx,wy,wz)
        return isoToScreenX(0,wx,wy,wz),isoToScreenY(0,wx,wy,wz)
    end)
    if not pair then return false end
    local now=getTimestampMs()
    local key=r.id..':'..pair.edge
    local previous=lastClick[player]
    if previous and previous.key==key and now-previous.time<400 then return true end
    local first=pair.leaves[1];local sq=getCell():getGridSquare(first.x,first.y,0)
    local doors=TSBAstroluxSlidingDoors
    if not sq or not doors or not doors.togglePair then return false end
    local list=sq:getObjects()
    for i=0,list:size()-1 do
        local a=list:get(i);local md=a:getModData()
        if md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='slidingDoor' then
            local b=doors.partner(a,getCell())
            -- Consume a doorway-center click even when a lock/occupant refuses it.
            if b then
                lastClick[player]={key=key,time=now}
                doors.togglePair(player,a,b);return true
            end
        end
    end
    return false
end
local installed=false
function C.install()
    if installed then return true end
    -- Native server Lua loads after client Lua in single player. Do not require
    -- that server file from the client path or index its global during loading.
    if not ISObjectClickHandler or type(ISObjectClickHandler.doClickSpecificObject)~='function' then return false end
    local original=ISObjectClickHandler.doClickSpecificObject
    ISObjectClickHandler.doClickSpecificObject=function(object,index,player)
        if index==0 and C.click(object,player,getMouseX(),getMouseY()) then return true end
        return original(object,index,player)
    end
    installed=true
    print('[Astrolux doors] Doorway-center click handler attached.')
    return true
end
if Events then
    Events.OnGameStart.Add(C.install)
    Events.OnTick.Add(function() if not installed then C.install() end end)
end
return C
