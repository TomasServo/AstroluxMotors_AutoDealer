-- Restore native blocking flags on captured showroom furniture, without replacing it.
if isClient() then return end
local Records=require 'TSBAstroluxStructure/Records'
local Layout=require 'TSBAstroluxStructure/DefaultFurnishings'
local F={sprites={}}
for _,entry in ipairs(Layout.objects)do
    if entry.objectType=='Thumpable' and not entry.sprite:find('furniture_tables_low_',1,true) then
        F.sprites[entry.sprite]=true
    end
end
local checked=setmetatable({},{__mode='k'})
function F.repair(square)
    if not square or square:getZ()~=0 then return end
    -- Do not trap a person or animal currently overlapping a broken fixture.
    if square:getMovingObjects():size()>0 or square:getStaticMovingObjects():size()>0 then return end
    local objects=square:getObjects()
    for i=0,objects:size()-1 do
        local obj=objects:get(i)
        local sprite=obj:getSprite()
        if not checked[obj] and sprite and F.sprites[sprite:getName()] then
            if instanceof(obj,'IsoThumpable') then
                -- Retain health, container identity/items, ModData and kiosk registration.
                obj:setBlockAllTheSquare(true)
                obj:setCanPassThrough(false)
                obj:setHoppable(false)
                obj:transmitCompleteItemToClients()
                -- RecalcAllWithNeighbours alone can reuse properties and does not
                -- invalidate the polygonal player-movement obstacle cache.
                square:RecalcProperties()
                square:RecalcAllWithNeighbours(true)
                square:setSquareChanged()
                checked[obj]=true
                print('[Astrolux furniture] Collision cache refreshed: '..sprite:getName()
                    ..' solid='..tostring(square:isSolid())
                    ..' solidtrans='..tostring(square:isSolidTrans())
                    ..' besideWindow='..tostring(square:isAdjacentToWindow())
                    ..' besideHoppable='..tostring(square:isAdjacentToHoppable())
                    ..' open='..tostring(obj:IsOpen())
                    ..' blockAll='..tostring(obj:isBlockAllTheSquare())
                    ..' passThrough='..tostring(obj:isCanPassThrough()))
            else
                -- Unknown object classes need inspection; never discard their state.
                checked[obj]=true
                print('[Astrolux furniture] Collision inspection required: '..sprite:getName()..' class='..tostring(obj:getObjectName()))
            end
        end
    end
end
local last=0
Events.OnTick.Add(function()
    local now=getTimestampMs();if now-last<3000 then return end;last=now
    for _,record in ipairs(Records.all())do
        if record.status=='ready' then
            for x=0,8 do for y=0,8 do
                F.repair(getCell():getGridSquare(record.x+x,record.y+y,0))
            end end
        end
    end
end)
return F
