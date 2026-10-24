-- Treat the decorative tower as one visual shell, independently of native glass.
local V={}
local applied=setmetatable({},{__mode='k'})
local transition=setmetatable({},{__mode='k'})
function V.inside(player,record)
    if player:getZ()~=0 then return false end
    -- Match the actual 8 x 8 ground floor. The south/east outer tile is outside.
    local x,y=player:getX(),player:getY()
    return x>=record.x and x<record.x+8 and y>=record.y and y<record.y+8
end
function V.shouldHide(player,record)
    if player:getZ()~=0 then transition[player]=nil;return false end
    local records=transition[player]
    if not records then records={};transition[player]=records end
    local state=records[record.id]
    if not state then state={id=record.id,hidden=false};records[record.id]=state end
    -- Cut away only on the building footprint, including doorway boundary tiles.
    state.hidden=V.inside(player,record)
    return state.hidden
end
function V.isShell(obj,record)
    local md=obj:getModData()
    if md.TSBAstroluxStructure~=record.id then return false end
    local sprite=obj:getSprite();local name=sprite and sprite:getName()
    if md.TSBAstroluxStructureKind=='art' then
        return name and name:sub(1,19)=='TSBAstroluxDisplay_'
    end
    if md.TSBAstroluxStructureKind=='floor' and name=='floors_interior_tilesandwood_01_0' then
        local sq=obj:getSquare()
        return sq and sq:getZ()==1 and sq:getX()>=record.x and sq:getX()<record.x+8
            and sq:getY()>=record.y and sq:getY()<record.y+8
    end
    return false
end
function V.update(obj,record)
    if not V.isShell(obj,record) then return end
    local count,inside=0,0
    local dirty=applied[obj]==nil
    -- Native building collapse must not independently cut sections out of the
    -- decorative shell. Scope the square override to owned shell/ceiling tiles;
    -- never change the shared native ceiling sprite or ground-floor glass.
    local square=obj:getSquare()
    if square then
        local props=square:getProperties()
        if not props:has(IsoFlagType.forceRender) then
            props:set(IsoFlagType.forceRender)
            square:setSquareChanged()
            dirty=true
        end
    end
    for i=0,getNumActivePlayers()-1 do
        local player=getSpecificPlayer(i)
        if player then
            count=count+1
            local hide=V.shouldHide(player,record)
            if hide then inside=inside+1 end
            local alpha=hide and 0 or 1
            if obj:getAlpha(i)~=alpha or obj:getTargetAlpha(i)~=alpha then
                obj:setAlphaAndTarget(i,alpha);dirty=true
            end
        end
    end
    local visible=count==0 or inside<count
    if obj:getDoRender()~=visible then obj:setDoRender(visible);dirty=true end
    if visible and count>0 and obj:isSceneCulled() then obj:setSceneCulled(false);dirty=true end
    -- Rebuild the cached object classification, including newly discovered slices.
    -- A texture redraw alone can leave the previous object layer in use.
    if applied[obj]~=visible then dirty=true end
    applied[obj]=visible
    if dirty then obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY) end
end
-- Keep Lua wrappers alive between discovery passes; prune unloaded objects below.
local tracked={}
local lastReport
local layout=require 'TSBAstroluxStructure/DisplayPlan'
local function records()
    if isClient() or isServer() or not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return {} end
    return require('TSBAstroluxStructure/Records').all()
end
local function track(square,r)
    if not square or not r then return end
    local objects=square:getObjects()
    for i=0,objects:size()-1 do
        local obj=objects:get(i)
        if V.isShell(obj,r) then
            tracked[obj]=r;V.update(obj,r)
        end
    end
end
local function discover()
    for _,r in ipairs(records())do
    local seen={}
    for _,piece in ipairs(layout) do
        local key=piece.x..':'..piece.y..':'..piece.z
        if not seen[key] then
            seen[key]=true
            track(getCell():getGridSquare(r.x+piece.x,r.y+piece.y,piece.z),r)
        end
    end
    -- The native ceiling is separate from the artwork anchors. Discover all
    -- 64 tagged ceiling tiles so no checkerboard cap is left behind.
    for x=0,7 do for y=0,7 do
        track(getCell():getGridSquare(r.x+x,r.y+y,1),r)
    end end
    end
    local total,hidden=0,0
    for obj in pairs(tracked) do
        if obj:getObjectIndex()>=0 then
            total=total+1
            if not obj:getDoRender() then hidden=hidden+1 end
        end
    end
    local report=total..' shell pieces loaded (art + ceiling); '..hidden..' hidden'
    if report~=lastReport then lastReport=report;print('[Astrolux cutaway] '..report) end
end
if Events then
    Events.OnGameStart.Add(discover)
    Events.LoadGridsquare.Add(function(square)for _,r in ipairs(records())do track(square,r)end end)
    local last=0
    Events.OnTick.Add(function()
        local now=getTimestampMs()
        if now-last>=1000 then last=now;discover() end
        for obj,r in pairs(tracked) do
            if obj:getObjectIndex()<0 then tracked[obj]=nil;applied[obj]=nil else V.update(obj,r) end
        end
    end)
    Events.OnRenderTick.Add(function()
        for obj,r in pairs(tracked) do
            if obj:getObjectIndex()<0 then tracked[obj]=nil else V.update(obj,r) end
        end
    end)
end
return V
