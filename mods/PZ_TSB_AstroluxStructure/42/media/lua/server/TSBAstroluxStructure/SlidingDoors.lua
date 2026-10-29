-- Server-authoritative pair state; native doors own collisions and persistence.
if isClient()then return end
local M={};TSBAstroluxSlidingDoors=M;local tracked=setmetatable({},{__mode='k'});local last=0;local lastScan=0
local function valid(o)
    local s=o and o:getSprite();local d=o and o:getModData()
    return o and o:getObjectIndex()>=0 and instanceof(o,'IsoDoor') and not o:isDestroyed()
        and d.TSBAstroluxStructure and d.TSBAstroluxStructureKind=='slidingDoor' and s and s:getName()
        and s:getName():match('^TSBAstroluxSlidingDoor_%d+$')
end
function M.partner(o,cell)
    if not valid(o)then return end
    local s=o:getSquare();local north=o:getNorth();local n=tonumber(o:getSprite():getName():match('_(%d+)$'))
    local step=n>=4 and -1 or 1
    local other=cell:getGridSquare(s:getX()+(north and step or 0),s:getY()+(north and 0 or step),s:getZ())
    if not other then return end
    local found;local list=other:getObjects()
    for i=0,list:size()-1 do local candidate=list:get(i)
        if valid(candidate) and candidate:getNorth()==north and candidate:getModData().TSBAstroluxStructure==o:getModData().TSBAstroluxStructure then
            local j=tonumber(candidate:getSprite():getName():match('_(%d+)$'))
            if (j>=4)~=(n>=4)then if found then return end;found=candidate end
        end
    end
    return found
end
function M.reconcile(a,b,previous)
    if not valid(a)or not valid(b)then return false end
    if a:isBarricaded()or b:isBarricaded()then return false end
    local av,bv=a:IsOpen(),b:IsOpen()
    if av==bv then return av end
    local desired
    if previous==nil then desired=av or bv
    elseif av~=previous then desired=av else desired=bv end
    -- Opening a linked pair cannot bypass the other leaf's lock.
    if desired and ((not av and a:isLocked())or(not bv and b:isLocked()))then desired=false end
    if not desired and (IsoDoor.isDoorObstructed(a)or IsoDoor.isDoorObstructed(b))then return previous end
    local changed={}
    local ok=pcall(function()
        for _,o in ipairs({a,b})do
            if o:IsOpen()~=desired then
                changed[#changed+1]={obj=o,open=o:IsOpen()};o:ToggleDoorSilent()
                if o:IsOpen()~=desired then error('Sliding leaf did not change state')end
                o:syncIsoObject(false,0,nil,nil)
                o:getSquare():RecalcAllWithNeighbours(true)
            end
        end
    end)
    if not ok then
        for i=#changed,1,-1 do local entry=changed[i];local o=entry.obj
            pcall(function()if o:IsOpen()~=entry.open then o:ToggleDoorSilent()end;o:syncIsoObject(false,0,nil,nil);o:getSquare():RecalcAllWithNeighbours(true)end)
        end
        return previous
    end
    return desired
end
local function track(sq)
    if not sq then return end;local list=sq:getObjects()
    for i=0,list:size()-1 do local o=list:get(i);if valid(o)then tracked[o]=tracked[o]or{}end end
end
if Events then Events.LoadGridsquare.Add(track)
Events.OnTick.Add(function()
    if not isServer() and #require('TSBAstroluxStructure/ReleaseSites').all()==0 and not (tostring(getWorld():getWorld()):match('^AstroluxStructureLab') or require('AstroluxBayTest/TestWorld').testMap() or require('AstroluxBayTest/TestWorld').corner()) then return end
    local now=getTimestampMs();if now-last<100 then return end;last=now
    -- Catch newly migrated/placed leaves as well as squares loaded from saves.
    local function scan(p)
        if not p then return end
        for x=math.floor(p:getX())-12,math.floor(p:getX())+12 do
            for y=math.floor(p:getY())-12,math.floor(p:getY())+12 do track(getCell():getGridSquare(x,y,0))end
        end
    end
    if now-lastScan>=2000 then
        lastScan=now
        if isServer()then local ps=getOnlinePlayers();for i=0,ps:size()-1 do scan(ps:get(i))end
        else scan(getSpecificPlayer(0))end
    end
    local seen={}
    for a,state in pairs(tracked)do
        if not valid(a)then tracked[a]=nil
        elseif not seen[a]then
            local b=M.partner(a,getCell())
            if b then
                seen[a]=true;seen[b]=true
                local previous=state.open
                if previous==nil and tracked[b]then previous=tracked[b].open end
                local value=M.reconcile(a,b,previous)
                state.open=value;tracked[b]=tracked[b]or{};tracked[b].open=value
            end
        end
    end
end)
end
return M
