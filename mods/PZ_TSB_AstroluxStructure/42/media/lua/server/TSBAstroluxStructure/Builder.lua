-- Isolated lab: ground-floor conversion only; no commerce or legacy mod hooks.
local P=require 'TSBAstroluxStructure/Plan'
local Flooring=require 'TSBAstroluxStructure/Flooring'
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
local function scan(x,y,record,player)
    local cell=getCell()
    for z=0,P.maxZ do for sx=x-1,x+(z==0 and 9 or 11) do for sy=y-1,y+(z==0 and 9 or 11) do
        local sq=cell:getGridSquare(sx,sy,z)
        local where=' at '..sx..', '..sy..', '..z
        if z==0 then
            if not sq then return nil,'Ground tile is not loaded'..where..'. Move closer or choose another site.' end
            if not sq:TreatAsSolidFloor() then return nil,'No solid ground'..where end
            if not record and not sq:isOutside() then return nil,'Ground is indoors or covered'..where end
        end
        if sq then
            local moving=sq:getMovingObjects()
            for i=0,moving:size()-1 do
                local mover=moving:get(i)
                local margin=sx<x or sx>x+8 or sy<y or sy>y+8
                if mover~=player or not margin then
                    return nil,(mover==player and 'Step outside the tower footprint' or 'Person or animal blocks the site')..where
                end
            end
            if sq:getStaticMovingObjects():size()>0 then return nil,'Body blocks the site'..where end
            if sq:getWorldObjects():size()>0 then return nil,'Dropped item blocks the site'..where end
            local objects=sq:getObjects()
            for i=0,objects:size()-1 do
                local obj=objects:get(i)
                local owned=record and obj:getModData()[tag]==record.id
                if not owned and not (z==0 and obj==sq:getFloor()) then
                    return nil,'Existing object blocks the lab'..where..'. Nothing removed.'
                end
                if owned and obj:getContainer() then return nil,'Remove containers before cleanup'..where end
            end
        end
    end end end
    local vehicles=cell:getVehicles():iterator()
    while vehicles:hasNext() do
        local v=vehicles:next()
        if v:getX()>x-9 and v:getX()<x+17 and v:getY()>y-9 and v:getY()<y+17 then
            return nil,'Vehicle near '..math.floor(v:getX())..', '..math.floor(v:getY())..'. Move it away from the lab.'
        end
    end
    return true
end
local function removeObject(obj,sq)
    sq:RemoveTileObject(obj)
    sq:RecalcAllWithNeighbours(true)
end
function B.preview(player,x,y,multiple)
    if not allowed(player) then return nil,'Use a single-player debug save named AstroluxStructureLab (optional suffix).' end
    if not integer(x) or not integer(y) or not nearby(player,x,y) then return nil,'Choose ground within 30 tiles.' end
    if state().tower and not multiple then return nil,'One lab tower at a time. Use paste furnished showroom here for a separate copy.' end
    if multiple then for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
        if r.x==x and r.y==y then return nil,'This showroom origin is already registered. Nothing replaced.' end
    end end
    local clear,reason=scan(x,y,nil,player)
    if not clear then return nil,reason end
    local plan=P.plan(x,y)
    for _,item in ipairs(plan.objects) do
        local sprite=getSprite(item.sprite)
        if not sprite or sprite:getName()~=item.sprite then return nil,'Missing native sprite: '..item.sprite end
    end
    return plan
end
function B.place(player,x,y,options)
    options=options or {}
    local previous=state().tower
    local plan,reason=B.preview(player,x,y,options.multiple) -- Revalidate immediately before any mutation.
    if not plan then return nil,reason end
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
        local painted,reason=Flooring.paint(record)
        if not painted then error(reason,0) end
        record.status='ready'
        if options.furnished then
            record.clearWallsRevision=1
            local installed,why=require('TSBAstroluxStructure/SlidingInstall').apply(record)
            if not installed then error(why,0) end
            local furnished,why=require('TSBAstroluxStructure/Furnishings').apply(record,player)
            if not furnished then error(why,0) end
        end
    end)
    if not ok then
        local clean=record.status~='hold'
        if clean and record.flooring then
            local ok,restored=pcall(Flooring.restore,record);if not ok or not restored then clean=false end
        end
        for i=#made,1,-1 do
            local entry=made[i]
            if clean and not pcall(removeObject,entry.obj,entry.sq) then clean=false end
        end
        -- Door installation adds native objects outside the structural constructor list.
        if clean and options.furnished then
            for _,pair in ipairs(require('TSBAstroluxStructure/Entrances').plan(record))do for _,leaf in ipairs(pair.leaves)do
                local sq=getCell():getGridSquare(leaf.x,leaf.y,0);local list=sq and sq:getObjects()
                if list then for i=list:size()-1,0,-1 do local obj=list:get(i)
                    if obj:getModData()[tag]==record.id and not pcall(removeObject,obj,sq) then clean=false end
                end end
            end end
        end
        if clean then state().tower=previous else
            record.status='hold'
            if previous then state().showrooms=state().showrooms or {};state().showrooms[record.id]=record;state().tower=previous end
        end
        error(tostring(err)..(clean and ' Prototype objects rolled back.' or ' Partial structure held; inspect before cleanup.'),0)
    end
    if options.multiple then
        state().showrooms=state().showrooms or {};state().showrooms[record.id]=record
        state().tower=previous or record
    end
    return record
end
function B.paste(player,x,y)return B.place(player,x,y,{multiple=true,furnished=true})end
function B.remove(player,x,y)
    if not allowed(player) then return nil,'Cleanup is restricted to the single-player debug lab.' end
    local record=x and y and require('TSBAstroluxStructure/Records').near(x,y) or state().tower
    if not record or not nearby(player,record.x,record.y) then return nil,'Stand near the lab on the ground, outside the tower footprint.' end
    local clear,reason=scan(record.x,record.y,record,player)
    if not clear then return nil,reason end
    local restored,reason=Flooring.restore(record)
    if not restored then return nil,reason end
    -- Reverse height order keeps floors until the glass above has been removed.
    for z=P.maxZ,0,-1 do for sx=record.x-1,record.x+11 do for sy=record.y-1,record.y+11 do
        local sq=getCell():getGridSquare(sx,sy,z)
        if sq then
            local objects=sq:getObjects()
            for i=objects:size()-1,0,-1 do
                local obj=objects:get(i)
                if obj:getModData()[tag]==record.id then removeObject(obj,sq) end
            end
        end
    end end end
    if state().tower==record then state().tower=nil end
    if state().showrooms then state().showrooms[record.id]=nil end
    return true
end
function B.convert(player)
    if not allowed(player) then return nil,'Conversion is restricted to the single-player debug lab.' end
    local record=state().tower
    if not record then return nil,'No placed prototype to convert. Preview a new tower instead.' end
    if (record.revision or 1)>=P.revision then return true end
    if record.status~='ready' then return nil,'Prototype is held for inspection; conversion skipped.' end
    if not nearby(player,record.x,record.y) then return nil,'Stand near the prototype on the ground, outside its footprint.' end
    local clear,reason=scan(record.x,record.y,record,player)
    if not clear then return nil,reason end
    local plan=P.plan(record.x,record.y)
    local old,made,removed={},{},{}
    local cap=0
    for z=1,P.maxZ do for x=record.x-1,record.x+11 do for y=record.y-1,record.y+11 do
        local sq=getCell():getGridSquare(x,y,z)
        if sq then for i=0,sq:getObjects():size()-1 do
            local obj=sq:getObjects():get(i)
            local md=obj:getModData()
            if md[tag]==record.id then
                if z==1 and md.TSBAstroluxStructureKind=='floor' then cap=cap+1
                else old[#old+1]={obj=obj,sq=sq,kind=md.TSBAstroluxStructureKind} end
            end
        end end
    end end end
    if cap~=64 then return nil,'Expected the intact 8 x 8 ceiling above the first floor; conversion skipped.' end
    for _,item in ipairs(plan.objects) do if item.kind=='art' then
        local sprite=getSprite(item.sprite)
        if not sprite or sprite:getName()~=item.sprite then return nil,'Missing display sprite: '..item.sprite..'. Restart with the complete package.' end
    end end
    local ok,err=pcall(function()
        -- Create the replacement first. Native upper objects stay intact until it succeeds.
        for _,item in ipairs(plan.objects) do if item.kind=='art' then
            local cell=getCell()
            local sq=cell:getGridSquare(item.x,item.y,item.z)
            if not sq then sq=cell:createNewGridSquare(item.x,item.y,item.z,true) end
            assert(sq,'Could not create display square.')
            local obj=IsoObject.new(cell,sq,getSprite(item.sprite))
            assert(obj,'Could not create display piece.')
            made[#made+1]={obj=obj,sq=sq}
            obj:getModData()[tag]=record.id
            obj:getModData().TSBAstroluxStructureKind='art'
            sq:AddTileObject(obj);sq:RecalcAllWithNeighbours(true)
        end end
        for i=#old,1,-1 do
            local entry=old[i]
            removeObject(entry.obj,entry.sq);removed[#removed+1]=entry
        end
    end)
    if not ok then
        local clean=true
        for i=#made,1,-1 do if not pcall(removeObject,made[i].obj,made[i].sq) then clean=false end end
        for i=#removed,1,-1 do
            local entry=removed[i]
            if not pcall(function()
                if entry.kind=='window' or entry.kind=='door' then entry.sq:AddSpecialObject(entry.obj)
                else entry.sq:AddTileObject(entry.obj) end
                entry.sq:RecalcAllWithNeighbours(true)
            end) then clean=false end
        end
        if not clean then record.status='hold' end
        return nil,'Conversion failed: '..tostring(err)..(clean and '. Original structure restored.' or '. Partial structure held for inspection.')
    end
    record.revision=P.revision
    record.style='ground-floor-display'
    return true
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(function()
    if isClient() or isServer() then return end
    local player=getSpecificPlayer(0)
    if not allowed(player) then return end
    local record=state().tower
    if not record or (record.revision or 1)>=P.revision then return end
    local ok,result,reason=pcall(B.convert,player)
    local message=ok and (result and 'Ground floor retained; car-display tower applied above.' or reason) or tostring(result)
    print('[Astrolux Structure] '..tostring(message))
    if player then player:Say(tostring(message)) end
end) end
return B
