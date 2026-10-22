-- Upgrade this lab's tagged ground-floor glass only. Do not recreate missing panes.
local M={}
TSBAstroluxClearWalls=M
local tag='TSBAstroluxStructure'
local function gap(x,y,north,r)
    local n=north and x-r.x or y-r.y
    return (n==3 or n==4) and (north and (y==r.y or y==r.y+8) or not north and (x==r.x or x==r.x+8))
end
local function name(obj) local s=obj:getSprite();return s and s:getName() end
local function attachments(obj)
    return obj:isBarricaded() or obj:HasCurtains() or obj:haveSheetRope()
end
function M.apply(player)
    if isClient() or isServer() or not getDebug() or not player or player:isDead()
        or not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return nil,'Single-player debug lab only.' end
    local r=ModData.getOrCreate('TSBAstroluxStructure.Lab.v1').tower
    if not r or r.status~='ready' or (r.revision or 1)<2 then return nil,'Convert the tower display first.' end
    if player:getZ()~=0 or (player:getX()-r.x)^2+(player:getY()-r.y)^2>900 then return nil,'Stand near the tower on the ground.' end
    local cell=getCell();local changes,removals,corners={},{},{};local deferred=0
    for _,i in ipairs({0,1,3}) do
        local sprite=getSprite('TSBAstroluxClearGlass_'..i)
        if not sprite or sprite:getName()~='TSBAstroluxClearGlass_'..i then return nil,'Missing transparent glass assets; restart with the complete mod.' end
    end
    for x=r.x,r.x+8 do for y=r.y,r.y+8 do
        if x==r.x or x==r.x+8 or y==r.y or y==r.y+8 then
            local sq=cell:getGridSquare(x,y,0)
            if not sq then return nil,'Wall tile not loaded at '..x..', '..y end
            local objects=sq:getObjects()
            for i=0,objects:size()-1 do
                local obj=objects:get(i);local md=obj:getModData();local kind=md.TSBAstroluxStructureKind
                if md[tag]==r.id then
                    if kind=='window' and instanceof(obj,'IsoWindow') then
                        local north=obj:getNorth();local sprite=name(obj)
                        if gap(x,y,north,r) then
                            if attachments(obj) then return nil,'Remove curtains, ropes or barricades from the planned opening at '..x..', '..y end
                            removals[#removals+1]={sq=sq,obj=obj,kind=kind}
                        elseif sprite=='walls_commercial_01_'..(north and 1 or 0) then
                            if not attachments(obj) and not obj:isDestroyed() and not obj:isSmashed()
                                and not obj:IsOpen() and not obj:isGlassRemoved() and not obj:isInvincible() then
                                local replacement=IsoWindow.new(cell,sq,getSprite('TSBAstroluxClearGlass_'..(north and 1 or 0)),north)
                                if obj:getHealth()==replacement:getHealth() then
                                    replacement:setIsLocked(obj:isLocked());replacement:setPermaLocked(obj:isPermaLocked())
                                    for k,v in pairs(md) do replacement:getModData()[k]=v end
                                    changes[#changes+1]={sq=sq,obj=obj,new=replacement,kind=kind}
                                else deferred=deferred+1 end
                            else deferred=deferred+1 end
                        end
                    elseif kind=='door' or kind=='frame' then
                        -- Use the actual door direction; frame direction is encoded in its native sprite.
                        local north=kind=='door' and obj:getNorth() or name(obj)=='walls_commercial_01_9'
                        if gap(x,y,north,r) then removals[#removals+1]={sq=sq,obj=obj,kind=kind} end
                    elseif kind=='corner' and x==r.x+8 and y==r.y+8 and name(obj)=='walls_commercial_01_2' then
                        corners[#corners+1]={sq=sq,obj=obj,old=obj:getSprite()}
                    end
                elseif obj~=sq:getFloor() then
                    -- Leave foreign objects alone; do not remove a supporting door/window beside them.
                    if gap(x,y,true,r) or gap(x,y,false,r) then return nil,'Clear attached/foreign objects from the opening at '..x..', '..y end
                end
            end
            if (gap(x,y,true,r) or gap(x,y,false,r)) and sq:getWorldObjects():size()>0 then
                return nil,'Clear loose items from the opening at '..x..', '..y
            end
        end
    end end
    local added,removed,changed={},{},{}
    local ok,err=pcall(function()
        for _,e in ipairs(changes) do e.sq:AddSpecialObject(e.new);added[#added+1]=e end
        for _,e in ipairs(changes) do e.sq:RemoveTileObject(e.obj);removed[#removed+1]=e end
        for _,e in ipairs(removals) do e.sq:RemoveTileObject(e.obj);removed[#removed+1]=e end
        for _,e in ipairs(corners) do e.obj:setSprite(getSprite('TSBAstroluxClearGlass_3'));changed[#changed+1]=e end
        for _,group in ipairs({changes,removals,corners}) do for _,e in ipairs(group) do e.sq:RecalcAllWithNeighbours(true) end end
    end)
    if not ok then
        local clean=true
        for i=#changed,1,-1 do local e=changed[i];if not pcall(function() e.obj:setSprite(e.old) end) then clean=false end end
        for i=#added,1,-1 do local e=added[i];if not pcall(function() e.sq:RemoveTileObject(e.new) end) then clean=false end end
        for _,e in ipairs(removed) do
            if not pcall(function()
                if e.kind=='window' or e.kind=='door' then e.sq:AddSpecialObject(e.obj) else e.sq:AddTileObject(e.obj) end
                e.sq:RecalcAllWithNeighbours(true)
            end) then clean=false end
        end
        if not clean then r.status='hold' end
        return nil,'Transparent-wall update failed: '..tostring(err)..(clean and '. Original objects restored.' or '. Held for inspection.')
    end
    r.clearWallsRevision=1
    return true,'Transparent walls applied; centered two-tile openings kept clear. Deferred altered panes: '..deferred
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(function()
    local player=getSpecificPlayer(0)
    local ok,result,reason=pcall(M.apply,player)
    print('[Astrolux clear walls] '..tostring(ok and reason or result))
end) end
return M
