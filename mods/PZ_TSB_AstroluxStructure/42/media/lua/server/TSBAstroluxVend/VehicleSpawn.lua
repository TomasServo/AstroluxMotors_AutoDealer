if isClient() then return end
local A=require 'TSBAstroluxVend/SpawnAreas'
local Delivery=require 'TSBAstroluxVend/Delivery'
local Accessories=require 'TSBAstroluxVend/Accessories'
local Paint=require 'TSBAstroluxVend/Paint'
local SpawnDefaults=require 'TSBAstroluxVend/SpawnDefaults'
local CamperCapacity=require 'TSBAstroluxVend/CamperCapacity'
local Equipment=require 'TSBAstroluxVend/Equipment'
local BorderPlan=require 'TSBAstroluxVend/DeliveryBorderPlan'
local S={}
function S.emptyStorage(vehicle)
    for i=0,vehicle:getPartCount()-1 do
        local container=vehicle:getPartByIndex(i):getItemContainer()
        if container then
            -- Only delivery storage contents: installed parts are separate items.
            if isServer() and container:getItems():size()>0 then
                sendRemoveItemsFromContainer(container,container:getItems())
            end
            while container:getItems():size()>0 do
                container:DoRemoveItem(container:getItems():get(0))
            end
            container:clear();container:setExplored(true)
        end
    end
end
function S.regions()
    local regions={}
    if not isServer() then
        for i=0,getNumActivePlayers()-1 do
            local map=getCell():getChunkMap(i)
            if map then regions[#regions+1]={x1=map:getWorldXMinTiles(),y1=map:getWorldYMinTiles(),
                x2=map:getWorldXMaxTiles()-1,y2=map:getWorldYMaxTiles()-1} end
        end
    else
        -- Server world squares remain authoritative: these are search windows,
        -- not permission/distance limits on an area or on its kiosk.
        local players=getOnlinePlayers()
        for i=0,players:size()-1 do local p=players:get(i)
            regions[#regions+1]={x1=math.floor(p:getX())-128,y1=math.floor(p:getY())-128,
                x2=math.floor(p:getX())+128,y2=math.floor(p:getY())+128}
        end
    end
    return regions
end
function S.obstacles(db,own)
    local blockers={}
    for _,order in pairs(db.orders or {}) do
        if order~=own and order.status~='delivered' and order.placement then blockers[#blockers+1]=order.placement end
    end
    local vehicles=getCell():getVehicles():iterator()
    while vehicles:hasNext() do
        local v=vehicles:next()
        if v:getZ()<1 then
            local ok,bounds=pcall(A.vehicleBounds,v)
            if not ok then return nil end -- Unknown geometry cannot authorize a spawn.
            blockers[#blockers+1]=bounds
        end
    end
    return blockers
end
function S.clear(db,p,own,blockers)
    blockers=blockers or S.obstacles(db,own)
    if not blockers then return false end
    for _,b in ipairs(blockers)do
        if A.overlap(p,b) then return false end
    end
    for x=p.x-p.rx,p.x+p.rx do for y=p.y-p.ry,p.y+p.ry do
        local sq=getCell():getGridSquare(x,y,0)
        if not sq or not sq:TreatAsSolidFloor() or not sq:isOutside() or not sq:isFree(false)
            or sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0
            or sq:getWorldObjects():size()>0 then return false end
        local objects=sq:getObjects()
        for i=0,objects:size()-1 do local obj=objects:get(i);if obj~=sq:getFloor() and not BorderPlan.isMarker(obj)then return false end end
    end end
    return true
end
function S.choose(db,t,own,scriptName,soft)
    local function reject(message)if soft then return nil,message end;error(message,0)end
    local area=t.spawnArea
    if not area then return reject('An owner must designate a vehicle spawn area first.') end
    local script=getScriptManager():getVehicle(scriptName)
    local rx,ry=A.measure(script,area.heading)
    local function shape(p)return A.footprint(script,area.heading,p.x+.5,p.y+.5)end
    -- Snapshot global reservations and actual parked cars once per selection.
    -- Every quote, buy and dispatch obtains a new snapshot; nothing caches a bay.
    local blockers=S.obstacles(db,own)
    if not blockers then return reject('A parked vehicle has unavailable dimensions. Delivery paused; no new vehicle was spawned.') end
    if own and own.placement then
        local stored=own.placement
        if stored.heading~=area.heading or stored.areaRevision~=area.revision then error('Paid order area changed; administrator inspection required.',0) end
        -- Recompute physical bounds after reload in case an enabled vehicle
        -- mod changed dimensions; never trust a smaller saved footprint.
        rx,ry=math.max(rx,stored.rx or rx),math.max(ry,stored.ry or ry)
        local p={x=stored.x,y=stored.y,rx=rx,ry=ry,heading=area.heading,areaRevision=area.revision,gap=area.gap or 0,rowGap=area.rowGap}
        p.footprint=shape(p)
        if not A.contains(area,p) or not S.clear(db,p,own,blockers) then
            if own.status=='queued' then
                local ready=A.find(area,rx,ry,S.regions(),function(q) return S.clear(db,q,own,blockers) end,shape)
                if ready then return ready end
            end
            error('Delivery queued: waiting for a clear, loaded space in the selected area.',0)
        end
        return p
    end
    local p,why=A.find(area,rx,ry,S.regions(),function(candidate) return S.clear(db,candidate,own,blockers) end,shape)
    if p then return p end
    return reject('Delivery area must be clear and loaded. No order placed. '..tostring(why))
end
function S.create(order,player)
    local p=order.placement;local script=getScriptManager():getVehicle(order.script)
    Accessories.verify(order.camperTop,script)
    Equipment.selection(order.equipment,script,order.camperTop)
    Paint.verify(order.paint,script)
    local dir=IsoDirections[p.heading]
    local sq=getCell():getGridSquare(p.x,p.y,0)
    if not sq or not dir then error('Reserved spawn square is unavailable.',0) end
    local vehicle=SpawnDefaults.create(order.script,function() return addVehicleDebug(order.script,dir,nil,sq) end)
    if not vehicle then error('Native vehicle creation failed.',0) end
    -- Record identity immediately: any later failure is held, never respawned.
    order.vehicleId=vehicle:getId()
    vehicle:getModData().TSBAstroluxVendOrder=order.id;vehicle:transmitModData()
    if not vehicle:getSquare() then error('Native vehicle was not placed.',0) end
    -- Vanilla debug creation adds +/-0.2 radians. Remove that variation with
    -- native degree-based setAngles, using the same direction-to-yaw convention.
    vehicle:setDir(dir)
    vehicle:setAngles(0,(math.deg(dir:toAngle())+180)%360,0)
    Delivery.restore(vehicle,order.camperTop,order.equipment);Paint.apply(vehicle,order.paint)
    CamperCapacity.update(vehicle)
    S.emptyStorage(vehicle)
    local cap=vehicle:getPartById('HLX88TruckBedExtras')
    local item=cap and cap:getInventoryItem()
    print('[AstroluxCamper] order='..tostring(order.id)..' selected='..tostring(order.camperTop)..' item='..tostring(item and item:getFullType() or 'none'))
    local key=vehicle:createVehicleKey()
    if not key then error('Vehicle key creation failed.',0) end
    local added=player:getInventory():AddItem(key)
    if not added then error('Vehicle key inventory insertion failed.',0) end
    order.keyIssued=true
    if isServer() then sendAddItemToContainer(player:getInventory(),key) end
end
return S
