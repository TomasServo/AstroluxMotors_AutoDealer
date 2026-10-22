-- Treat the decorative tower as one visual shell, independently of native glass.
local V={}
local applied=setmetatable({},{__mode='k'})
local transition=setmetatable({},{__mode='k'})
function V.inside(player,record)
    if player:getZ()~=0 then return false end
    -- Include the entire south/east boundary tile, including fractional positions.
    local x,y=math.floor(player:getX()),math.floor(player:getY())
    return x>=record.x and x<=record.x+8 and y>=record.y and y<=record.y+8
end
function V.shouldHide(player,record)
    if player:getZ()~=0 then transition[player]=nil;return false end
    local state=transition[player]
    if not state or state.id~=record.id then state={id=record.id,hidden=false};transition[player]=state end
    -- Hide before the native elevated-structure cutaway reaches the entrance.
    -- Restore farther away so small doorway movements cannot flicker the shell.
    local margin=state.hidden and 5 or 4
    local x,y=math.floor(player:getX()),math.floor(player:getY())
    state.hidden=x>=record.x-margin and x<=record.x+8+margin
        and y>=record.y-margin and y<=record.y+8+margin
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
local function record()
    if isClient() or isServer() or not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return nil end
    return ModData.getOrCreate('TSBAstroluxStructure.Lab.v1').tower
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
    local r=record();if not r then return end
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
    Events.LoadGridsquare.Add(function(square) track(square,record()) end)
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
