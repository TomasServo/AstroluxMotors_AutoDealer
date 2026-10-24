-- Called only inside the existing Astrolux server handler after its init/rate limit.
local M={}
local function fail(s)error(s,0)end
local function integer(n)return type(n)=='number' and n==math.floor(n) and math.abs(n)<1000000 end
function M.place(p,args,db)
    if not p then fail('Player unavailable.')end
    if isServer() and tostring(p:getAccessLevel()):lower()~='admin' then fail('Administrator access required.')end
    if not p or p:isDead() or p:getZ()~=0 or not integer(args.x) or not integer(args.y)
        or (p:getX()-args.x)^2+(p:getY()-args.y)^2>25 then fail('Choose ground within five tiles.')end
    if not integer(args.facing) or args.facing<0 or args.facing>3 then fail('Choose a kiosk direction.')end
    if args.confirmed~=true then fail('Confirm kiosk placement first.')end
    local cell=getCell();local sq=cell:getGridSquare(args.x,args.y,0)
    if not sq or not sq:TreatAsSolidFloor() or not sq:isFree(false)
        or sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0 then fail('Kiosk site is unloaded or obstructed.')end
    local objects=sq:getObjects()
    for i=0,objects:size()-1 do if objects:get(i)~=sq:getFloor() then fail('Clear the kiosk tile first; existing fixtures are never replaced.')end end
    local vehicles=cell:getVehicles():iterator()
    while vehicles:hasNext()do local v=vehicles:next()
        if v:getZ()==0 and (v:getX()-args.x)^2+(v:getY()-args.y)^2<25 then fail('Move vehicles at least five tiles from the kiosk site.')end
    end
    for _,hold in pairs(db.kioskHolds or {})do
        if hold.x==args.x and hold.y==args.y then fail('This kiosk site has a held placement. Administrator inspection required.')end
    end
    local count=0
    for _,t in pairs(db.terminals)do
        count=count+1
        if t.x==args.x and t.y==args.y and t.z==0 then fail('A terminal is already registered here.')end
    end
    for _ in pairs(db.kioskHolds or {})do count=count+1 end
    if count>=32 then fail('Terminal limit reached.')end
    local name='TSBAstroluxKiosk_'..args.facing;local sprite=getSprite(name)
    if not sprite or sprite:getName()~=name then fail('Kiosk sprites unavailable. Restart with the complete Astrolux mod.')end
    db.serial=db.serial+1
    local id='terminal:'..db.serial
    local t={id=id,x=args.x,y=args.y,z=0,sprite=name,kiosk=true}
    db.kioskHolds=db.kioskHolds or {}
    db.kioskHolds[id]={x=args.x,y=args.y,z=0,actor=tostring(p:getUsername()),status='placing'}
    local obj
    local ok,err=pcall(function()
        obj=IsoThumpable.new(cell,sq,name,false,{})
        obj:setIsThumpable(false);obj:setIsDismantable(false)
        obj:setBlockAllTheSquare(true);obj:setCanPassThrough(false);obj:setHoppable(false)
        obj:getModData().TSBAstroluxVend=id;obj:getModData().TSBAstroluxKiosk=true
        sq:AddTileObject(obj);obj:transmitCompleteItemToClients();sq:RecalcAllWithNeighbours(true)
    end)
    if not ok then
        local clean=pcall(function()
            if obj then
                obj:getModData().TSBAstroluxVend=nil
                if obj:getObjectIndex()>=0 then sq:transmitRemoveItemFromSquare(obj)end
                sq:RecalcAllWithNeighbours(true)
                if obj:getObjectIndex()>=0 then fail('Kiosk rollback incomplete.')end
            end
        end)
        if clean then db.kioskHolds[id]=nil else db.kioskHolds[id].status='hold' end
        fail('Kiosk placement failed: '..tostring(err)..(clean and ' Rolled back.' or ' Site held for inspection.'))
    end
    db.terminals[id]=t;db.kioskHolds[id]=nil
    return t
end
-- Explicit retirement works for registered kiosks and old unregistered brush art.
function M.remove(p,args,db)
    if not p or (isServer() and tostring(p:getAccessLevel()):lower()~='admin') then fail('Administrator access required.') end
    if p:isDead() or p:getZ()~=0 or not integer(args.x) or not integer(args.y)
        or (p:getX()-args.x)^2+(p:getY()-args.y)^2>25 then fail('Stand within five tiles of the kiosk.') end
    if args.confirmed~=true then fail('Confirm kiosk removal first.') end
    local sq=getCell():getGridSquare(args.x,args.y,0)
    local objects=sq and sq:getObjects()
    if not objects or not integer(args.index) or args.index<0 or args.index>=objects:size() then fail('Kiosk unavailable; reopen the menu.') end
    local obj=objects:get(args.index)
    local sprite=obj:getSprite();local name=sprite and sprite:getName()
    if type(name)~='string' or not name:match('^TSBAstroluxKiosk_[0-3]$') or name~=args.sprite then fail('Select the Astrolux sales kiosk again.') end
    local id=obj:getModData().TSBAstroluxVend
    local ids={}
    for key,t in pairs(db.terminals) do
        if key==id then
            if t.x~=args.x or t.y~=args.y or t.z~=0 or t.sprite~=name then fail('Kiosk registration mismatch; administrator inspection required.') end
            ids[#ids+1]=key
        elseif t.x==args.x and t.y==args.y and t.z==0 and t.sprite==name then
            ids[#ids+1]=key
        end
    end
    for _,key in ipairs(ids) do
        for _,order in pairs(db.orders or {}) do
            if order.terminal==key and order.status~='delivered' then fail('Resolve outstanding purchases before removing this kiosk.') end
        end
    end
    for _,hold in pairs(db.kioskHolds or {}) do
        if hold.x==args.x and hold.y==args.y then fail('Resolve the held kiosk placement before removal.') end
    end
    sq:transmitRemoveItemFromSquare(obj)
    if obj:getObjectIndex()>=0 then fail('Native kiosk removal was not confirmed; registration retained.') end
    -- Retire registration only after confirmed native removal; retain paid history.
    for _,key in ipairs(ids) do db.terminals[key]=nil end
    sq:RecalcAllWithNeighbours(true)
    return {removed=ids}
end
function M.command(p,args,db,removing)
    local ok,result=pcall(removing and M.remove or M.place,p,args,db)
    local data={ok=ok,message=ok and (removing and 'Astrolux sales kiosk removed. Registration and spawn area retired; transaction history retained.' or 'Astrolux Motors sales kiosk placed. Right-click it to open sales, then designate a vehicle spawn area.') or tostring(result)}
    if isServer()then sendServerCommand(p,require('TSBAstroluxVend/Config').channel,'kioskResult',data)
    elseif TSBAstroluxKioskClient then TSBAstroluxKioskClient.receive(data)end
    if ok then return result end
end
return M
