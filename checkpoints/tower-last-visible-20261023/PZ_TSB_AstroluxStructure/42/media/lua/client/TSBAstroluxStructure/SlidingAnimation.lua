-- Render-only motion. Native IsoDoor sprites/state, collision and sound remain authoritative.
if isServer()then return end
local M={duration=2000};local tracked=setmetatable({},{__mode='k'});local lastScan=0;local last=0
local function baseIndex(o)
    if not o or o:getObjectIndex()<0 or not instanceof(o,'IsoDoor')or o:isDestroyed()then return end
    local d=o:getModData();if not d.TSBAstroluxStructure or d.TSBAstroluxStructureKind~='slidingDoor'then return end
    local sprite=o:getSprite();local name=sprite and sprite:getName()
    local index=name and tonumber(name:match('^TSBAstroluxSlidingDoor_(%d+)$'))
    if not index or index<0 or index>7 then return end
    return index%4>=2 and index-2 or index
end
local function position(state,now)
    if not state.start then return state.position end
    local t=math.min(1,math.max(0,(now-state.start)/state.duration))
    local ease=t*t*(3-2*t)
    local p=state.from+(state.target-state.from)*ease
    if t>=1 then state.start=nil end
    return p
end
function M.update(o,state,now)
    local base=baseIndex(o);if not base then return false end
    local target=o:IsOpen()and 1 or 0
    if state.base==nil then
        state.base=base;state.x=o:getOffsetX();state.y=o:getOffsetY()
        state.position=target;state.target=target
        local opened=getSprite('TSBAstroluxSlidingDoor_'..(base+2))
        if opened and opened:getName()=='TSBAstroluxSlidingDoor_'..(base+2)then o:setOpenSprite(opened)end
    end
    state.position=position(state,now)
    if target~=state.target then
        state.from=state.position;state.target=target;state.start=now
        state.duration=math.max(1,M.duration*math.abs(target-state.position))
    end
    -- Force the canonical endpoint sprite: do not leave the closed pane across an open doorway.
    local expected='TSBAstroluxSlidingDoor_'..(state.base+(target==1 and 2 or 0))
    local current=o:getSprite();local dirty=false
    if not current or current:getName()~=expected then
        local art=getSprite(expected);if not art or art:getName()~=expected then return false end
        o:setSprite(art);dirty=true
    end
    local second=state.base>=4;local north=state.base%2==1
    local dx=north and(second and 64 or -64)or(second and -64 or 64)
    local dy=second and 32 or -32
    -- Native drawing subtracts these pixel offsets. Move only along the wall plane.
    local residual=state.position-target
    local x=state.x-residual*dx;local y=state.y-residual*dy
    if o:getOffsetX()~=x or o:getOffsetY()~=y then
        o:setOffsetX(x);o:setOffsetY(y);dirty=true
    end
    if dirty then o:invalidateRenderChunkLevel(-1)end
    return true
end
local function track(sq)
    if not sq then return end;local list=sq:getObjects()
    for i=0,list:size()-1 do local o=list:get(i)
        if baseIndex(o)and not tracked[o]then
            local state={};if M.update(o,state,getTimestampMs())then tracked[o]=state end
        end
    end
end
Events.LoadGridsquare.Add(track)
Events.OnTick.Add(function()
    if not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return end
    local now=getTimestampMs();if now-last<25 then return end;last=now
    if now-lastScan>=2000 then
        lastScan=now
        for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i)
            if p then
                for x=math.floor(p:getX())-12,math.floor(p:getX())+12 do
                    for y=math.floor(p:getY())-12,math.floor(p:getY())+12 do
                        track(getCell():getGridSquare(x,y,p:getZ()))
                    end
                end
            end
        end
    end
    for o,state in pairs(tracked)do
        if not M.update(o,state,now)then
            if o:getObjectIndex()>=0 and state.x then o:setOffsetX(state.x);o:setOffsetY(state.y);o:invalidateRenderChunkLevel(-1)end
            tracked[o]=nil
        end
    end
end)
return M
