if isClient() then return end
local A=require 'TSBAstroluxVend/SpawnAreas'
local Delivery=require 'TSBAstroluxVend/Delivery'
local Paint=require 'TSBAstroluxVend/Paint'
local S={}
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
function S.clear(db,p,own)
    for _,order in pairs(db.orders or {}) do
        if order~=own and order.status~='delivered' and order.placement and A.overlap(p,order.placement) then return false end
    end
    for x=p.x-p.rx,p.x+p.rx do for y=p.y-p.ry,p.y+p.ry do
        local sq=getCell():getGridSquare(x,y,0)
        if not sq or not sq:TreatAsSolidFloor() or not sq:isOutside() or not sq:isFree(false)
            or sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0
            or sq:getWorldObjects():size()>0 then return false end
        local objects=sq:getObjects()
        for i=0,objects:size()-1 do if objects:get(i)~=sq:getFloor() then return false end end
    end end
    local vehicles=getCell():getVehicles():iterator()
    while vehicles:hasNext() do
        local v=vehicles:next()
        if v:getZ()<1 then
            local ok,rx,ry=pcall(A.measure,v:getScript(),'N')
            if not ok then return false end
            -- Orientation-independent envelope protects arbitrary parked cars.
            local radius=math.sqrt(rx*rx+ry*ry)
            if math.abs(v:getX()-p.x)<=radius+p.rx and math.abs(v:getY()-p.y)<=radius+p.ry then return false end
        end
    end
    return true
end
function S.choose(db,t,own,scriptName)
    local area=t.spawnArea
    if not area then error('An owner must designate a vehicle spawn area first.',0) end
    local rx,ry=A.measure(getScriptManager():getVehicle(scriptName),area.heading)
    if own and own.placement then
        local stored=own.placement
        if stored.heading~=area.heading or stored.areaRevision~=area.revision then error('Paid order area changed; administrator inspection required.',0) end
        -- Recompute physical bounds after reload in case an enabled vehicle
        -- mod changed dimensions; never trust a smaller saved footprint.
        local p={x=stored.x,y=stored.y,rx=rx,ry=ry,heading=area.heading,areaRevision=area.revision}
        if not A.contains(area,p) or not S.clear(db,p,own) then
            if own.status=='queued' then
                local ready=A.find(area,rx,ry,S.regions(),function(q) return S.clear(db,q,own) end)
                if ready then return ready end
            end
            error('Delivery queued: waiting for a clear, loaded space in the selected area.',0)
        end
        return p
    end
    local p,why=A.find(area,rx,ry,S.regions(),function(candidate) return S.clear(db,candidate,own) end)
    if p then return p end
    local blockers={}
    for _,o in pairs(db.orders or {}) do
        if o~=own and o.status~='delivered' and o.placement then blockers[#blockers+1]=o.placement end
    end
    -- Loaded obstructions were checked above. Reserve only unstreamed space;
    -- never charge for a known blocked, fully loaded delivery area.
    for _,r in ipairs(S.regions()) do
        blockers[#blockers+1]={x=(r.x1+r.x2)/2,y=(r.y1+r.y2)/2,rx=(r.x2-r.x1)/2,ry=(r.y2-r.y1)/2}
    end
    local reserved=A.reserve(area,rx,ry,blockers)
    if not reserved then error(why,0) end
    return reserved
end
function S.create(order,player)
    local p=order.placement;local script=getScriptManager():getVehicle(order.script)
    Paint.verify(order.paint,script)
    local dir=IsoDirections[p.heading]
    local sq=getCell():getGridSquare(p.x,p.y,0)
    if not sq or not dir then error('Reserved spawn square is unavailable.',0) end
    local vehicle=addVehicleDebug(order.script,dir,nil,sq)
    if not vehicle then error('Native vehicle creation failed.',0) end
    -- Record identity immediately: any later failure is held, never respawned.
    order.vehicleId=vehicle:getId()
    vehicle:getModData().TSBAstroluxVendOrder=order.id;vehicle:transmitModData()
    if not vehicle:getSquare() then error('Native vehicle was not placed.',0) end
    -- Vanilla debug creation adds +/-0.2 radians. Remove that variation with
    -- native degree-based setAngles, using the same direction-to-yaw convention.
    vehicle:setDir(dir)
    vehicle:setAngles(0,(math.deg(dir:toAngle())+180)%360,0)
    Delivery.restore(vehicle);Paint.apply(vehicle,order.paint)
    local key=vehicle:createVehicleKey()
    if not key then error('Vehicle key creation failed.',0) end
    local added=player:getInventory():AddItem(key)
    if not added then error('Vehicle key inventory insertion failed.',0) end
    order.keyIssued=true
    if isServer() then sendAddItemToContainer(player:getInventory(),key) end
end
return S
