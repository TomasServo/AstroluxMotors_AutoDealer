-- Deliberately isolated from AutoVend. No migration, commerce or render hooks.
local P=require 'TSBAstroluxStructure/Plan'
local B={}
TSBAstroluxStructure=B
local tag='TSBAstroluxStructure'
local function allowed(player)
    return not isClient() and not isServer() and getDebug() and player and not player:isDead()
        and tostring(getWorld():getWorld()):match('^AstroluxStructureLab')~=nil
end
local function state() return ModData.getOrCreate('TSBAstroluxStructure.Lab.v1') end
local function integer(n) return type(n)=='number' and n==n and math.abs(n)<1000000 and n==math.floor(n) end
local function nearby(player,x,y)
    return player:getZ()==0 and (player:getX()-x)^2+(player:getY()-y)^2<=900
end
local function scan(x,y,record)
    local cell=getCell()
    for z=0,P.levels do for sx=x-1,x+9 do for sy=y-1,y+9 do
        local sq=cell:getGridSquare(sx,sy,z)
        if z==0 and (not sq or not sq:TreatAsSolidFloor() or (not record and not sq:isOutside())) then
            error('Choose clear outdoor solid ground; the full 11 x 11 area must be loaded.',0)
        end
        if sq then
            if sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0 or sq:getWorldObjects():size()>0 then
                error('Clear people, animals, bodies and dropped items from the test area.',0)
            end
            local objects=sq:getObjects()
            for i=0,objects:size()-1 do
                local obj=objects:get(i)
                local owned=record and obj:getModData()[tag]==record.id
                if not owned and not (z==0 and obj==sq:getFloor()) then
                    error('Existing object blocks the lab at '..sx..', '..sy..', '..z..'. Nothing removed.',0)
                end
                if owned and obj:getContainer() then error('Remove containers before cleanup.',0) end
            end
        end
    end end end
    local vehicles=cell:getVehicles():iterator()
    while vehicles:hasNext() do
        local v=vehicles:next()
        if v:getX()>x-9 and v:getX()<x+17 and v:getY()>y-9 and v:getY()<y+17 then
            error('Move vehicles away from the lab.',0)
        end
    end
end
local function removeObject(obj,sq)
    sq:RemoveTileObject(obj)
    sq:RecalcAllWithNeighbours(true)
end
function B.preview(player,x,y)
    assert(allowed(player),'Use a single-player debug save named AstroluxStructureLab (optional suffix).')
    assert(integer(x) and integer(y) and nearby(player,x,y),'Choose ground within 30 tiles.')
    assert(not state().tower,'One lab tower at a time. Clean up the existing prototype first.')
    scan(x,y)
    local plan=P.plan(x,y)
    for _,item in ipairs(plan.objects) do
        local sprite=getSprite(item.sprite)
        assert(sprite and sprite:getName()==item.sprite,'Missing native sprite: '..item.sprite)
    end
    return plan
end
function B.place(player,x,y)
    local plan=B.preview(player,x,y) -- Revalidate immediately before any mutation.
    local record={id='structure:'..x..':'..y,x=x,y=y,revision=P.revision,status='placing'}
    state().tower=record
    local made={}
    local ok,err=pcall(function()
        for _,item in ipairs(plan.objects) do
            local cell=getCell()
            local sq=cell:getGridSquare(item.x,item.y,item.z)
            if not sq then sq=cell:createNewGridSquare(item.x,item.y,item.z,true) end
            assert(sq,'Could not create structural square.')
            local obj
            if item.kind=='floor' then
                obj=sq:addFloor(item.sprite)
            elseif item.kind=='window' then
                obj=IsoWindow.new(cell,sq,getSprite(item.sprite),item.north)
                obj:setPermaLocked(true)
            elseif item.kind=='door' then
                obj=IsoDoor.new(cell,sq,item.sprite,item.north)
            else
                obj=IsoObject.new(cell,sq,getSprite(item.sprite))
            end
            assert(obj,'Could not create '..item.kind)
            -- Track before insertion so a failed insertion can also be rolled back.
            made[#made+1]={obj=obj,sq=sq}
            obj:getModData()[tag]=record.id
            obj:getModData().TSBAstroluxStructureKind=item.kind
            if item.kind=='window' or item.kind=='door' then sq:AddSpecialObject(obj)
            elseif item.kind~='floor' then sq:AddTileObject(obj) end
            sq:RecalcAllWithNeighbours(true)
        end
        record.status='ready'
    end)
    if not ok then
        local clean=true
        for i=#made,1,-1 do
            local entry=made[i]
            if not pcall(removeObject,entry.obj,entry.sq) then clean=false end
        end
        if clean then state().tower=nil else record.status='hold' end
        error(tostring(err)..(clean and ' Prototype objects rolled back.' or ' Partial structure held; inspect before cleanup.'),0)
    end
    return record
end
function B.remove(player)
    assert(allowed(player),'Cleanup is restricted to the single-player debug lab.')
    local record=state().tower
    assert(record and nearby(player,record.x,record.y),'Stand near the lab on the ground, outside its 11 x 11 area.')
    scan(record.x,record.y,record)
    -- Reverse height order keeps floors until the glass above has been removed.
    for z=P.levels,0,-1 do for sx=record.x-1,record.x+9 do for sy=record.y-1,record.y+9 do
        local sq=getCell():getGridSquare(sx,sy,z)
        if sq then
            local objects=sq:getObjects()
            for i=objects:size()-1,0,-1 do
                local obj=objects:get(i)
                if obj:getModData()[tag]==record.id then removeObject(obj,sq) end
            end
        end
    end end end
    state().tower=nil
end
return B
