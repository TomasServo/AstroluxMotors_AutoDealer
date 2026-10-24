local F={}

local Plan=require 'AstroluxBayTest/ShowroomFloorPlan12'
local tag='TSBAstroluxFlooring'
local function spriteName(obj)
    local sprite=obj and obj:getSprite();return sprite and sprite:getName()
end
local function rollback(undo)
    local clean=true
    for i=#undo,1,-1 do local e=undo[i]
        if not pcall(function()
            if e.action=='create' then
                local obj=e.obj or e.sq:getFloor()
                if obj then e.sq:RemoveTileObject(obj) end
            elseif e.action=='remove' then
                e.sq:AddTileObject(e.obj);e.obj:getModData()[tag]=e.owner
            else
                if e.sq:getFloor()~=e.obj then error('Floor object changed.') end
                e.obj:setSprite(e.sprite);e.obj:getModData()[tag]=e.owner
            end
            e.sq:RecalcAllWithNeighbours(true)
            if e.action~='create' then e.obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW) end
        end) then clean=false end
    end
    return clean
end
function F.paint(record)
    if record.flooring then return true,'Floor already applied; player changes preserved.' end
    local pending={}
    for _,tile in ipairs(Plan.plan(record.x,record.y)) do
        local sq=getCell():getGridSquare(tile.x,tile.y,0)
        if not sq then return nil,'Ground square not loaded at '..tile.x..', '..tile.y end
        local floor=sq:getFloor();local from=spriteName(floor)
        if floor and not from then return nil,'Existing floor sprite has no name at '..tile.x..', '..tile.y end
        local art=getSprite(tile.sprite)
        if not art or art:getName()~=tile.sprite then return nil,'Missing native square tiles: '..tile.sprite end
        local owner=floor and floor:getModData()[tag]
        if owner and owner~=record.id then return nil,'Another structure owns the floor at '..tile.x..', '..tile.y end
        if from~=tile.sprite then
            pending[#pending+1]={sq=sq,obj=floor,sprite=floor and floor:getSprite(),owner=owner,tile=tile,from=from,action=floor and 'paint' or 'create'}
        end
    end
    local undo,stored={},{}
    local ok,err=pcall(function()
        for _,e in ipairs(pending) do
            if e.sq:getFloor()~=e.obj or spriteName(e.obj)~=e.from then error('Ground changed during placement.') end
            undo[#undo+1]=e
            stored[#stored+1]={x=e.tile.x,y=e.tile.y,from=e.from,to=e.tile.sprite,owner=e.owner,created=e.action=='create'}
            if e.action=='create' then
                e.obj=e.sq:addFloor(e.tile.sprite)
                assert(e.obj,'Native floor creation failed.')
            else e.obj:setSprite(getSprite(e.tile.sprite)) end
            e.obj:getModData()[tag]=record.id
            e.sq:RecalcAllWithNeighbours(true)
            -- Sprite-only edits must invalidate the cached native ground render too.
            e.obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
        end
    end)
    if not ok then
        if not rollback(undo) then record.status='hold';record.flooring={revision=1,tiles=stored,hold=true} end
        return nil,'Floor update failed: '..tostring(err)..'. Inspect before retrying.'
    end
    record.flooring={revision=1,tiles=stored}
    return true,'Dark gray square-tile border and gray square-tile center applied.'
end
function F.restore(record)
    if not record.flooring then return true end
    local pending={}
    for _,tile in ipairs(record.flooring.tiles) do
        local sq=getCell():getGridSquare(tile.x,tile.y,0)
        if not sq then return nil,'Load the complete floor before removing the tower.' end
        local floor=sq:getFloor()
        if floor and floor:getModData()[tag]==record.id then
            local current=spriteName(floor)
            local unchanged=current==tile.to
            local action=tile.created and unchanged and 'remove' or 'paint'
            local target=not tile.created and unchanged and tile.from or current
            local original=action~='remove' and getSprite(target) or nil
            if action~='remove' and (not original or original:getName()~=target) then return nil,'Original ground sprite missing: '..tostring(target) end
            pending[#pending+1]={sq=sq,obj=floor,sprite=floor:getSprite(),owner=record.id,to=original,oldOwner=tile.owner,action=action}
        end
    end
    local undo={}
    local ok,err=pcall(function()
        for _,e in ipairs(pending) do
            undo[#undo+1]=e
            if e.action=='remove' then e.sq:RemoveTileObject(e.obj)
            else e.obj:setSprite(e.to);e.obj:getModData()[tag]=e.oldOwner;e.obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW) end
            e.sq:RecalcAllWithNeighbours(true)
        end
    end)
    if not ok then
        if not rollback(undo) then record.status='hold' end
        return nil,'Floor restoration failed: '..tostring(err)
    end
    record.flooring=nil
    return true
end

return F
