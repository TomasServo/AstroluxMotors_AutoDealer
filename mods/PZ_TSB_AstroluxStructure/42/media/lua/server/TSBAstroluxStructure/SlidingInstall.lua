if isClient() or isServer() then return end
local E=require 'TSBAstroluxStructure/Entrances'
local M=require 'TSBAstroluxStructure/SlidingDoors'
local I={}
function I.apply(r)
    if r.slidingDoorsRevision then return true end
    if r.status~='ready' or r.clearWallsRevision~=1 then return nil,'Base not ready' end
    local pending={}
    for _,pair in ipairs(E.plan(r)) do for _,leaf in ipairs(pair.leaves) do
        local sq=getCell():getGridSquare(leaf.x,leaf.y,0)
        if not sq then return nil,'Entrance not loaded' end
        if sq:getMovingObjects():size()>0 or sq:getWorldObjects():size()>0 then return nil,'Clear entrance tiles' end
        local list=sq:getObjects()
        for i=0,list:size()-1 do
            if list:get(i)~=sq:getFloor() then return nil,'Entrance contains an object; nothing replaced' end
        end
        local closed=getSprite('TSBAstroluxSlidingDoor_'..leaf.base)
        local opened=getSprite('TSBAstroluxSlidingDoor_'..(leaf.base+2))
        if not closed or closed:getName()~='TSBAstroluxSlidingDoor_'..leaf.base
            or not opened or opened:getName()~='TSBAstroluxSlidingDoor_'..(leaf.base+2) then return nil,'Sliding assets missing' end
        local obj=IsoDoor.new(getCell(),sq,closed,pair.north)
        obj:setOpenSprite(opened)
        obj:setIsLocked(false);obj:setLockedByKey(false)
        local md=obj:getModData();md.TSBAstroluxStructure=r.id;md.TSBAstroluxStructureKind='slidingDoor'
        pending[#pending+1]={sq=sq,obj=obj}
    end end
    local added={}
    local ok,err=pcall(function()
        for _,e in ipairs(pending) do
            added[#added+1]=e;e.sq:AddSpecialObject(e.obj)
            assert(e.obj:getObjectIndex()>=0,'Door insertion failed')
            e.sq:RecalcAllWithNeighbours(true)
        end
    end)
    if not ok then
        local clean=true
        for i=#added,1,-1 do local e=added[i]
            if not pcall(function()
                if e.obj:getObjectIndex()>=0 then e.sq:RemoveTileObject(e.obj) end
                e.sq:RecalcAllWithNeighbours(true)
            end) then clean=false end
        end
        if not clean then r.status='hold' end
        return nil,'Sliding installation failed: '..tostring(err)
    end
    r.slidingDoorsRevision=1
    return true
end
function M.togglePair(player,a,b)
    if not player or player:isDead() or player:getZ()~=0 or not a or not b then return false end
    if a:isDestroyed() or b:isDestroyed() or a:isBarricaded() or b:isBarricaded() then return false end
    local sa,sb=a:getSquare(),b:getSquare()
    local x=(sa:getX()+sb:getX())/2+(a:getNorth() and 0.5 or 0)
    local y=(sa:getY()+sb:getY())/2+(a:getNorth() and 0 or 0.5)
    if (player:getX()-x)^2+(player:getY()-y)^2>6.25 then return false end
    local desired=not (a:IsOpen() or b:IsOpen())
    if desired and (a:isLocked() or b:isLocked()) then return false end
    if not desired then
        for _,door in ipairs({a,b}) do
            local sq=door:getSquare();local other=door:getOppositeSquare()
            for _,side in ipairs({sq,other}) do
                local moving=side:getMovingObjects()
                for i=0,moving:size()-1 do
                    local obj=moving:get(i)
                    local along=a:getNorth() and obj:getX()-sq:getX() or obj:getY()-sq:getY()
                    local across=a:getNorth() and obj:getY()-sq:getY() or obj:getX()-sq:getX()
                    if obj:getZ()==0 and along>=-0.3 and along<=1.3 and math.abs(across)<0.45 then return false end
                end
            end
        end
    end
    local before={a:IsOpen(),b:IsOpen()}
    local ok=pcall(function()
        for _,door in ipairs({a,b}) do
            if door:IsOpen()~=desired then door:ToggleDoor(player) end
            assert(door:IsOpen()==desired,'Native door refused toggle')
        end
    end)
    if not ok then
        for i,door in ipairs({a,b}) do
            if door:IsOpen()~=before[i] then door:ToggleDoorSilent() end
            door:getSquare():RecalcAllWithNeighbours(true)
        end
        return false
    end
    return true
end
local last=0
Events.OnTick.Add(function()
    if not getDebug() or not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return end
    local now=getTimestampMs();if now-last<1000 then return end;last=now
    for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
    if r and not r.slidingDoorsRevision then
        local ok,reason=I.apply(r)
        if ok then print('[Astrolux doors] Eight sliding leaves installed in four entrances.') end
    end
    end
end)
return I
