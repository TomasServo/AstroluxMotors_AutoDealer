-- Isolated lab: ground-floor conversion only; no commerce or legacy mod hooks.
local P=require 'AstroluxBayTest/ShowroomPlan11'
require 'AstroluxBayTest/ShowroomEntrances11'
local Flooring=require 'AstroluxBayTest/ShowroomFlooring11'
local B={}

local tag='TSBAstroluxStructure'
local function allowed(player)
    return not isClient() and not isServer() and getDebug() and player and not player:isDead()
        and tostring(getWorld():getWorld())=='AstroluxStructureLab_12x12_FourSides'
end
local function state() return ModData.getOrCreate('TSBAstroluxStructure.Lab.v1') end
local function integer(n) return type(n)=='number' and n==n and math.abs(n)<1000000 and n==math.floor(n) end
local function nearby(player,x,y)
    return player:getZ()==0 and (player:getX()-x)^2+(player:getY()-y)^2<=900
end
local function scan(x,y,record,player)
    local cell=getCell()
    for z=0,P.maxZ do for sx=x-1,x+12 do for sy=y-1,y+12 do
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
                local margin=sx<x or sx>x+11 or sy<y or sy>y+11
                if mover~=player or not margin then
                    return nil,(mover==player and 'Step outside the tower footprint' or 'Person or animal blocks the site')..where
                end
            end
            if sq:getStaticMovingObjects():size()>0 then return nil,'Body blocks the site'..where end
            if sq:getWorldObjects():size()>0 then return nil,'Dropped item blocks the site'..where end
            local objects=sq:getObjects()
            for i=0,objects:size()-1 do
                local obj=objects:get(i)
                local md=obj:getModData()
                local furnishing=md.movableData and md.movableData.TSBAstroluxFurnishingV1
                local owned=record and (md[tag]==record.id or (furnishing and furnishing.tower==record.id))
                if not owned and not (z==0 and obj==sq:getFloor()) then
                    return nil,'Existing object blocks the lab'..where..'. Nothing removed.'
                end
                -- Replacement inventory is captured before removal by Combined11.
            end
        end
    end end end
    local vehicles=cell:getVehicles():iterator()
    while vehicles:hasNext() do
        local v=vehicles:next()
        if v:getX()>x-9 and v:getX()<x+20 and v:getY()>y-9 and v:getY()<y+20 then
            return nil,'Vehicle near '..math.floor(v:getX())..', '..math.floor(v:getY())..'. Move it away from the lab.'
        end
    end
    return true
end
local function removeObject(obj,sq)
    sq:RemoveTileObject(obj)
    sq:RecalcAllWithNeighbours(true)
end
function B.preview(player,x,y,multiple,replacement)
    if not allowed(player) then return nil,'Use a single-player debug save named AstroluxStructureLab (optional suffix).' end
    if not integer(x) or not integer(y) or not nearby(player,x,y) then return nil,'Choose ground within 30 tiles.' end
    if state().tower and not multiple then return nil,'One lab tower at a time. Use paste furnished showroom here for a separate copy.' end
    if multiple then for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
        if r.x==x and r.y==y and r~=replacement then return nil,'This showroom origin is already registered. Nothing replaced.' end
    end end
    local clear,reason=scan(x,y,replacement,player)
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
    local record={id='structure:'..x..':'..y,x=x,y=y,revision=P.revision,combinedSize=11,replacementProfile=options.profile,status='placing'}
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
            local furnished,why=require('AstroluxBayTest/ShowroomFurnishings11').apply(record,player)
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

return B
