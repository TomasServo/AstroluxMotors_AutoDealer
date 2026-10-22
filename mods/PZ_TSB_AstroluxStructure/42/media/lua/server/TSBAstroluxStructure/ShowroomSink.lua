if isClient() or isServer() then return end
require 'Moveables/ISMoveableSpriteProps'
local S={sprite='fixtures_sinks_01_11'}
local function finish(r,obj)
    r.showroomSinkRevision=1
    local defaults=ModData.getOrCreate('TSBAstroluxStructure.DecorDefaults.v1')
    if defaults.profile then
        local objects=defaults.profile.objects;local found=false
        for _,entry in ipairs(objects) do if entry.dx==1 and entry.dy==7 and entry.sprite==S.sprite then found=true end end
        if not found then objects[#objects+1]={dx=1,dy=7,z=0,order=obj:getObjectIndex(),sprite=S.sprite,
            objectType=obj:getObjectName(),renderYOffset=obj:getRenderYOffset(),facing='N'} end
        require('TSBAstroluxStructure/DecorCapture').write(defaults.profile)
    end
end
function S.apply(r,p)
    if r.showroomSinkRevision then return true end
    if r.showroomSinkHold then return nil,'Inspect the previous sink placement before retrying.' end
    if r.status~='ready' or not p then return nil,'Showroom not ready.' end
    local sq=getCell():getGridSquare(r.x+1,r.y+7,0)
    if not sq then return nil,'Sink counter is not loaded.' end
    if sq:getMovingObjects():size()>0 or sq:getWorldObjects():size()>0 then return nil,'Clear the sink counter tile.' end
    local list=sq:getObjects();local counter,existing
    for i=0,list:size()-1 do local obj=list:get(i);local sprite=obj:getSprite();local name=sprite and sprite:getName()
        if name=='fixtures_counters_01_57' then if counter then return nil,'Duplicate counters; inspect the tile.' end;counter=obj
        elseif name==S.sprite then if existing then return nil,'Duplicate sinks; inspect the tile.' end;existing=obj
        elseif obj~=sq:getFloor() then return nil,'Countertop is occupied; nothing replaced.' end
    end
    if not counter then return nil,'Expected the north-facing counter beside the corner cabinet.' end
    if existing then finish(r,existing);return true end
    local props=ISMoveableSpriteProps.new(S.sprite)
    local item=instanceItem('Base.Mov_ChromeSink')
    if not item or not item:ReadFromWorldSprite(S.sprite) or not props:canPlaceMoveable(nil,sq,item) then return nil,'Native sink placement is unavailable.' end
    -- Record a one-time hold before native side effects; never replay an uncertain placement.
    r.showroomSinkHold=true
    local obj=props:placeMoveableInternal(p,sq,item,S.sprite)
    if not obj or obj:getObjectIndex()<0 then return nil,'Sink placement needs inspection; automatic retry stopped.' end
    finish(r,obj);r.showroomSinkHold=nil
    print('[Astrolux sink] Native chrome sink added opposite the coffee maker.')
    return true
end
local last=0
Events.OnTick.Add(function()
    local now=getTimestampMs();if now-last<2000 then return end;last=now
    if not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return end
    local r=ModData.getOrCreate('TSBAstroluxStructure.Lab.v1').tower
    if r and not r.showroomSinkRevision and not r.showroomSinkHold then S.apply(r,getSpecificPlayer(0)) end
end)
return S
