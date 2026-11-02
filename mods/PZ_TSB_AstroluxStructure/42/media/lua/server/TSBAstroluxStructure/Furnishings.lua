require 'Moveables/ISMoveableSpriteProps'
local layout=require 'TSBAstroluxStructure/DefaultFurnishings'
local F={}
local function key(x,y)return x..':'..y end
function F.prepare(r)
    local prepared={}
    for index,entry in ipairs(layout.objects)do
        local sq=getCell():getGridSquare(r.x+entry.dx,r.y+entry.dy,0)
        local sprite=getSprite(entry.sprite)
        if not sq or not sq:TreatAsSolidFloor() then return nil,'Furnishing floor is not loaded.' end
        if not sprite or sprite:getName()~=entry.sprite then return nil,'Missing furnishing sprite: '..entry.sprite end
        local props=ISMoveableSpriteProps.new(entry.sprite)
        local item=props:instanceItem(entry.sprite)
        if not props.isMoveable or not item then return nil,'Native furniture item unavailable: '..entry.sprite end
        prepared[#prepared+1]={entry=entry,index=index,sq=sq,props=props,item=item}
    end
    -- Tables and counters must exist before lamps, plants, appliance and sink.
    table.sort(prepared,function(a,b)
        local at,bt=a.props.isTableTop and 1 or 0,b.props.isTableTop and 1 or 0
        if at~=bt then return at<bt end
        if a.entry.dx~=b.entry.dx then return a.entry.dx<b.entry.dx end
        if a.entry.dy~=b.entry.dy then return a.entry.dy<b.entry.dy end
        if a.entry.order~=b.entry.order then return a.entry.order<b.entry.order end
        return a.index<b.index
    end)
    return prepared
end
function F.apply(r,player)
    if r.furnishingsRevision then return true end
    if r.furnishingsHold then return nil,'Previous furnishing paste needs inspection.' end
    local prepared,reason=F.prepare(r);if not prepared then return nil,reason end
    local snapshots={}
    for _,slot in ipairs(prepared)do
        local sq=slot.sq;local k=key(slot.entry.dx,slot.entry.dy)
        if not snapshots[k] then
            if sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0 or sq:getWorldObjects():size()>0 then return nil,'Clear all furnishing tiles before pasting.' end
            local before={};local list=sq:getObjects()
            for i=0,list:size()-1 do local obj=list:get(i);before[obj]=true
                if obj~=sq:getFloor() and obj:getModData().TSBAstroluxStructure~=r.id then return nil,'Existing furnishings block the paste; nothing replaced.' end
            end
            snapshots[k]={sq=sq,before=before}
        end
    end
    local service=TSBAstroluxVendServer or require 'TSBAstroluxVend/Server'
    -- Ensure native placement carries the existing kiosk identity protections.
    require 'TSBAstroluxVend/KioskFurniture'
    local terminals=service.kioskCheckpoint()
    local kioskLocations={}
    for _,slot in ipairs(prepared)do if slot.entry.service=='freshAstroluxKiosk' then
        kioskLocations[(r.x+slot.entry.dx)..':'..(r.y+slot.entry.dy)..':0']=true
    end end
    r.furnishingsHold=true
    local ok,why=pcall(function()
        for _,slot in ipairs(prepared)do
            -- Validate each captured piece directly: the full cursor method
            -- searches player inventory for every part of multi-tile furniture.
            if not slot.props:canPlaceMoveableInternal(nil,slot.sq,slot.item) then error('Native furniture geometry rejected '..slot.entry.sprite,0)end
            local obj=slot.props:placeMoveableInternal(player,slot.sq,slot.item,slot.entry.sprite)
            assert(obj and obj:getObjectIndex()>=0,'Native furnishing insertion not confirmed.')
            obj:setRenderYOffset(slot.entry.renderYOffset)
            local md=obj:getModData();md.movableData=md.movableData or {}
            md.movableData.TSBAstroluxFurnishingV1={tower=r.id,index=slot.index}
            if slot.entry.coffeeSupplies then md.movableData.TSBAstroluxCoffeeSuppliesV1={pending={}} end
            if slot.entry.service=='freshAstroluxKiosk' then
                if not md.TSBAstroluxVend then service.kioskPlaced(obj) end
                assert(md.TSBAstroluxVend and not terminals[md.TSBAstroluxVend],'Fresh kiosk identity was not assigned.')
            end
            obj:transmitModData();slot.sq:RecalcAllWithNeighbours(true)
        end
    end)
    if not ok then
        local clean=true
        -- Native creation may throw after insertion but before returning an object.
        for _,snapshot in pairs(snapshots)do
            local sq=snapshot.sq;local list=sq:getObjects()
            for i=list:size()-1,0,-1 do local obj=list:get(i)
                if not snapshot.before[obj] and not pcall(function()
                    sq:transmitRemoveItemFromSquare(obj)
                    assert(obj:getObjectIndex()<0,'Furnishing rollback incomplete.')
                end) then clean=false end
            end
            sq:RecalcAllWithNeighbours(true)
        end
        if not service.kioskRollbackTo(terminals,kioskLocations) then clean=false end
        if clean then r.furnishingsHold=nil else r.status='hold' end
        return nil,'Furnishing paste failed: '..tostring(why)..(clean and ' Rolled back.' or ' Held for inspection; do not retry.')
    end
    r.furnishingsHold=nil;r.furnishingsRevision=1;r.furnishingCount=#layout.objects;r.showroomSinkRevision=1
    return true
end
return F
