if isClient() then return end
local C=require 'TSBAstroluxVend/Config'
local Domain=require 'TSBAstroluxVend/Domain'
local Cash=require 'TSBAstroluxVend/Cash'
local Bank=require 'TSBAstroluxVend/BankPayments'
local V=require 'TSBAstroluxVend/VehicleCatalog'
local Buffs=require 'TSBAstroluxVend/BuffSettings'
local CamperCapacity=require 'TSBAstroluxVend/CamperCapacity'
local Equipment=require 'TSBAstroluxVend/Equipment'
local Accessories=require 'TSBAstroluxVend/Accessories'
local Paint=require 'TSBAstroluxVend/Paint'
local Families=require 'TSBAstroluxVend/VehicleFamilies'
local Demand=require 'TSBAstroluxVend/Demand'
local Prices=require 'TSBAstroluxVend/PriceAdmin'
local Areas=require 'TSBAstroluxVend/SpawnAreas'
local Spawn=require 'TSBAstroluxVend/VehicleSpawn'
local Kiosk=require 'TSBAstroluxVend/Kiosk'
local TradeIn=require 'TSBAstroluxVend/TradeIn'
local Audio=require 'TSBAstroluxVend/AudioSettings'
local S={};TSBAstroluxVendServer=S
local db,service,payments,catalog,trades
local players,last={},{}
local function fail(message) error(message,0) end
local Access=require 'TSBAstroluxVend/AdminAccess'
local function admin(p)return Access.allowed(p)end
local function offers()
    if not catalog then catalog=V.new(getScriptManager(),db.pricing,function(o)
        return Demand.offer(db,o,getGameTime():getWorldAgeHours())
    end) end
    return catalog
end
local function reply(p,data)
    if isServer() then sendServerCommand(p,C.channel,'view',data)
    elseif TSBAstroluxVendClient then TSBAstroluxVendClient.receive(data) end
end
local function init()
    if service then return end
    db=ModData.getOrCreate('TSBAstroluxVend.State.v1')
    trades=TradeIn.new(db,{now=getTimestamp,create=instanceItem,notify=function(container,item)if isServer()then sendAddItemToContainer(container,item)end end})
    payments=Cash.new(db,{now=getTimestamp,createMoney=function() return instanceItem('Base.Money') end,
        notify=function(container,item,added)
            if isServer() then
                if added then sendAddItemToContainer(container,item) else sendRemoveItemFromContainer(container,item) end
            end
        end})
    payments=Bank.new(db,payments,function() return true end)
    service=Domain.new(db,{now=getTimestamp,
        authorizeDelivery=function(order)
            local attempts=order.payment=='serverBank' and db.bankPayments or db.payments
            local attempt=attempts and attempts[order.actor]
            if not attempt or attempt.status~='committed' or attempt.receipt~='astroluxRebuild:'..order.id then
                order.status='hold';order.error='Payment receipt is missing or uncertain; inspect before recovery.'
                fail(order.error)
            end
        end,
        clear=function(t,own,script) return Spawn.choose(db,t,own,script) end,
        charge=function(actor,amount,receipt,apply,method)
            local p=players[actor];if not p then fail('Buyer unavailable.') end
            return payments:charge(p,amount,receipt,apply,method)
        end,
        spawn=function(order)
            local p=players[order.actor];if not p or p:isDead() then fail('Buyer unavailable.') end
            Spawn.create(order,p)
        end,
        completed=function(order) Demand.completed(db,order,getGameTime():getWorldAgeHours()) end})
    for _,o in pairs(db.orders) do
        if o.status=='paid' or o.status=='dispatching' then o.status='hold';o.error='Inspect payment, vehicle and key after restart; do not retry an uncertain delivery.' end
    end
end
local function terminal(p,args)
    if type(args.x)~='number' or type(args.y)~='number' or args.z~=0
        or type(args.index)~='number' or args.index~=math.floor(args.index) then fail('Select a kiosk again.') end
    if p:getZ()~=0 or (p:getX()-args.x)^2+(p:getY()-args.y)^2>9 then return nil,'Stand within three tiles of the sales kiosk, then reopen pricing and try again.' end
    local sq=getCell():getGridSquare(args.x,args.y,0);local list=sq and sq:getObjects()
    if not list or args.index<0 or args.index>=list:size() then fail('Kiosk unavailable.') end
    local obj=list:get(args.index);local id=obj:getModData().TSBAstroluxVend
    local t=id and db.terminals[id];local sprite=obj:getSprite()
    if not t or t.packed or not sprite or t.x~=args.x or t.y~=args.y or t.z~=0 or t.sprite~=sprite:getName()
        or not t.sprite:match('^TSBAstroluxKiosk_[0-3]$') then fail('Registered Astrolux kiosk required.') end
    return t
end
local function view(p,t,message,quote,args,tradeQuote,tradeSuccess)
    args=args or {};local list,page,pages,total=offers():page(args.search,args.page)
    local function decorate(o)
        local script=getScriptManager():getVehicle(o.script)
        o.equipmentOptions=Equipment.options(script,db.pricing)
        o.paintOptions=Paint.options(script,db.pricing,offers():paintVariants(o))
        return o
    end
    for _,o in ipairs(list)do
        decorate(o);o.configurationOptions={}
        for _,variant in ipairs(offers():configurations(o))do o.configurationOptions[#o.configurationOptions+1]=decorate(variant)end
    end
    for _,o in ipairs(list) do o.camperTopAvailable=Accessories.supports(getScriptManager():getVehicle(o.script));o.camperTopPrice=Accessories.price(db.pricing);o.addonBuffs=Buffs.enabled();o.camperTopCapacityBonus=o.addonBuffs and (C.camperTopCapacityBonus or 46) or 0 end
    local bankOK,bankBalance=false,nil
    if payments:bankAvailable() then bankOK,bankBalance=pcall(function() return payments:balance(p,'bank') end) end
    local pricing=admin(p) and Prices.view(db.pricing) or nil
    if pricing then pricing.audio=Audio.settings()end
    if pricing then pricing.vehicleAvailability=offers().vehicleAvailability;pricing.scripts=offers().installedScripts;pricing.scriptLabels=offers().scriptLabels;pricing.accessoryOptions={};pricing.accessoryIssues={}
        for _,name in ipairs(pricing.scripts)do
            pricing.accessoryOptions[name]=Equipment.options(getScriptManager():getVehicle(name),db.pricing,true)
            pricing.accessoryIssues[name]=Equipment.issues(getScriptManager():getVehicle(name))
            for _,row in ipairs(Families.adminRows(db.pricing,name,offers().installable))do
                pricing.accessoryOptions[name][#pricing.accessoryOptions[name]+1]=row
            end
        end
    end
    local order=db.orders[tostring(p:getUsername())]
    reply(p,{ok=true,message=message or 'Select a vehicle and request a price quote.',terminal=t.id,spawnArea=t.spawnArea,
        offers=list,page=page,pages=pages,total=total,quote=quote,
        order=order and {id=order.id,status=order.status,terminal=order.terminal},simple=true,
        bankAvailable=bankOK,bankBalance=bankOK and bankBalance or nil,paymentMethods=bankOK and {'cash','bank'} or {'cash'},
        tradeSuccess=tradeSuccess,tradeRules=Prices.view(db.pricing),tradeInsEnabled=TradeIn.enabled(db),tradeQuote=tradeQuote,balance=payments:balance(p),adminPricing=pricing})
end
local function handle(p,command,args)
    init()
    if not p or p:isDead() or type(args)~='table' then return end
    local actor=tostring(p:getUsername());players[actor]=p
    local now=getTimestampMs();if last[actor] and now-last[actor]<250 then return end;last[actor]=now
    if command=='coffeeCabinet' then
        if not admin(p) then fail('Administrator access required.') end
        local ok,why=require('TSBAstroluxVend/CoffeeSupplies').designate(p,args)
        if not ok then fail(why) end
        reply(p,{ok=true,message='Coffee cabinet enabled. Missing supplies return after ten real-life minutes.'});return
    end
    if command=='kioskPlace' or command=='kioskRemove' then
        if not admin(p) then fail('Administrator access required.') end
        local result=Kiosk.command(p,args,db,command=='kioskRemove')
        if result then service.quotes={};if trades then trades.quotes={} end end
        return
    end
    if command=='areaSet' then
        if not admin(p) then fail('Administrator access required.') end
        local t=db.terminals[args.terminal]
        if not t then fail('Select a registered kiosk before designating an area.') end
        if args.confirmed~=true then fail('Confirm the two-corner area first.') end
        local area,why=Areas.rectangle(args.ax,args.ay,args.bx,args.by,args.heading)
        if not area then fail(why) end
        for _,o in pairs(db.orders) do
            if o.terminal==t.id and o.status~='delivered' then fail('Resolve outstanding orders before changing the area.') end
        end
        -- No tower, kiosk-distance, total-size or current streaming requirement.
        area.revision=(t.spawnArea and t.spawnArea.revision or 0)+1
        t.spawnArea=area;service.quotes={};if trades then trades.quotes={} end
        reply(p,{ok=true,areaSaved=true,terminal=t.id,spawnArea=area,message='Vehicle spawn area saved. Vehicles face '..area.heading..'.'})
        return
    end
    local t,why=terminal(p,args)
    if not t then reply(p,{ok=false,message=why});return end
    if command=='open' then view(p,t,nil,nil,args);return end
    if command=='tradeDecline' then trades:decline(p);view(p,t,'Trade-in declined. Your vehicle is unchanged.',nil,args);return end
    if command=='tradeQuote' or command=='tradeAccept' then
        if not TradeIn.enabled(db) then reply(p,{ok=false,message='Trade-ins are disabled pending testing.'});return end
        if not t.spawnArea then reply(p,{ok=false,message='Configure a delivery area first.'});return end
        local q=trades.quotes[actor];local vehicle=q and q.vehicle
        if command=='tradeQuote' then
            vehicle=nil;local all=getCell():getVehicles():iterator();local a=t.spawnArea
            while all:hasNext()do local v=all:next()
                if TradeIn.inArea(t,v) then
                    if vehicle then reply(p,{ok=false,message='Leave only the vehicle to appraise in the delivery area.'});return end;vehicle=v
                end
            end
        end
        if not vehicle then
            local a=t.spawnArea
            reply(p,{ok=false,message='No vehicle found in this kiosk delivery area: '..a.x1..', '..a.y1..' to '..a.x2..', '..a.y2..'. Park the vehicle inside that rectangle and request an appraisal.'});return
        end
        local valid,reason=TradeIn.validate(p,t,vehicle,db.pricing)
        if not valid then reply(p,{ok=false,message=reason});return end
        local offer
        for _,o in ipairs(offers().offers)do if o.script==vehicle:getScript():getFullName()then offer=o;break end end
        if not offer then reply(p,{ok=false,message='Vehicle is not in the current Astrolux Motors catalog.'});return end
        local revision=(db.pricing or {}).revision or 0
        if command=='tradeQuote' then
            local appraisal=trades:quote(p,t,vehicle,offer.price,revision)
            view(p,t,appraisal.reason or 'Review the cash appraisal. Accepting permanently removes this vehicle.',nil,args,appraisal)
        else
            local amount=trades:accept(p,t,args.tradeToken,offer.price,revision)
            view(p,t,'Trade-in complete. $'..amount..' cash added to your inventory.',nil,args,nil,args.tradeToken)
        end
        return
    end
    if command=='setPrices' then
        if not admin(p) then fail('Administrator access required.') end
        if args.action=='audio'then
            db.audio=Audio.edit(args);Audio.publish()
            view(p,t,'Sound settings saved.',nil,args);return
        end
        local candidate=Prices.edit(db.pricing,args,offers())
        local rebuilt=V.new(getScriptManager(),candidate,function(o) return Demand.offer(db,o,getGameTime():getWorldAgeHours()) end)
        if args.action~='availability' then for _,o in ipairs(offers().offers) do if not rebuilt.byID[o.id] then fail('Price settings would invalidate an existing offer.') end end end
        db.pricing=candidate;catalog=rebuilt;service.quotes={};if trades then trades.quotes={} end
        Buffs.publish();CamperCapacity.scan()
        view(p,t,'Prices saved; unpaid quotes cancelled.',nil,args);return
    end
    if command=='deliver' then service:deliver(actor,t);view(p,t,'Vehicle delivered; its key is in your inventory.',nil,args);return end
    if command~='quote' and command~='buy' then fail('Unsupported sales command.') end
    local offer=offers():resolve(args.offer)
    if args.configuration~=nil and (type(args.configuration)~='string' or not Families.member(offer.script,args.configuration,'configuration'))then fail('Invalid factory configuration.')end
    offer=offers():variant(offer.id,args.configuration)
    local paint=Paint.select(getScriptManager():getVehicle(offer.script),db.pricing,args.paint,offers():paintVariants(offer))
    if paint.script then offer=offers():variant(offer.id,paint.script)end
    offer=Paint.attach(offer,paint)
    offer=Equipment.offer(offer,getScriptManager():getVehicle(offer.script),db.pricing,args.equipment,args.camperTop)
    local method=payments:method(args.payment)
    -- Ordinary placement rejection is user feedback, not a Lua exception.
    -- Revalidate again in Domain immediately before charging; never weaken clearance.
    local position,why=Spawn.choose(db,t,nil,offer.script,true)
    if not position then service.quotes[actor]=nil;reply(p,{ok=false,message=why});return end
    if command=='quote' then view(p,t,'Review the quote and confirm within 60 seconds.',service:quote(actor,t,offer,method),args)
    else
        local order=service:buy(actor,args.token,t,offer,method)
        local message=order.status=='queued' and 'Purchase recorded. Delivery is queued until someone loads a clear space in the remote area; your key will be issued on delivery.'
            or 'Vehicle delivered; its key is in your inventory.'
        view(p,t,message,nil,args)
    end
end
function S.handle(p,command,args)
    local ok,why=pcall(handle,p,command,args)
    if command=='buy' or command=='deliver' then S.refreshKioskLocks() end
    if not ok and p then reply(p,{ok=false,message=tostring(why)}) end
end
function S.kioskPending(obj)
    init()
    local id=obj:getModData().TSBAstroluxVend
    for _,o in pairs(db.orders) do if o.terminal==id and o.status~='delivered' then return true end end
    return false
end
function S.kioskPacked(id)
    init();local t=db.terminals[id]
    if t then t.packed=true;service.quotes={};if trades then trades.quotes={} end end
end
function S.kioskCheckpoint()
    init();local ids={};for id in pairs(db.terminals)do ids[id]=true end;return ids
end
function S.kioskRollbackTo(ids,locations)
    init()
    local function owned(id,t)return not ids[id] and locations[t.x..':'..t.y..':'..t.z] end
    for id,t in pairs(db.terminals)do if owned(id,t) then
        for _,order in pairs(db.orders)do if order.terminal==id then return false end end
        local sq=getCell():getGridSquare(t.x,t.y,t.z);local list=sq and sq:getObjects()
        if not list then return false end
        for i=0,list:size()-1 do if list:get(i):getModData().TSBAstroluxVend==id then return false end end
    end end
    for id,t in pairs(db.terminals)do if owned(id,t) then db.terminals[id]=nil end end
    service.quotes={};if trades then trades.quotes={} end;return true
end
function S.kioskPreplace(item,sq)
    init()
    if sq:getZ()~=0 or not sq:TreatAsSolidFloor() then fail('Place the sales kiosk on ground-floor flooring.') end
    local md=item:getModData();local saved=md.modData or md
    local id=saved.TSBAstroluxVend
    if id and (not db.terminals[id] or not db.terminals[id].packed) then fail('Kiosk identity is already placed or unavailable; administrator inspection required.') end
end
function S.kioskPlaced(obj)
    init()
    local md=obj:getModData();local id=md.TSBAstroluxVend;local t=id and db.terminals[id]
    if not t then
        db.serial=db.serial+1;id='terminal:'..db.serial
        t={id=id,kiosk=true};db.terminals[id]=t;md.TSBAstroluxVend=id
    end
    local sq=obj:getSquare()
    t.x=sq:getX();t.y=sq:getY();t.z=sq:getZ();t.sprite=obj:getSprite():getName();t.packed=nil
    md.TSBAstroluxKiosk=true;md.TSBAstroluxPending=S.kioskPending(obj)
    obj:setIsThumpable(false);obj:setIsDismantable(false)
    obj:transmitModData();service.quotes={};if trades then trades.quotes={} end
end
function S.refreshKioskLocks()
    init()
    for _,t in pairs(db.terminals) do if not t.packed then
        local sq=getCell():getGridSquare(t.x,t.y,t.z);local list=sq and sq:getObjects()
        if list then for i=0,list:size()-1 do local obj=list:get(i)
            if obj:getModData().TSBAstroluxVend==t.id then
                local pending=S.kioskPending(obj);local md=obj:getModData()
                if md.TSBAstroluxPending~=pending then md.TSBAstroluxPending=pending;obj:transmitModData() end
            end
        end end
    end end
end
Events.OnInitGlobalModData.Add(init)
Events.OnClientCommand.Add(function(module,command,p,args) if module==C.channel then S.handle(p,command,args) end end)
function S.deliverQueued()
    init()
    local online={}
    if isServer() then
        local list=getOnlinePlayers();for i=0,list:size()-1 do local p=list:get(i);online[tostring(p:getUsername())]=p end
    else
        for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i);if p then online[tostring(p:getUsername())]=p end end
    end
    for actor,o in pairs(db.orders) do
        local p=online[actor];local t=db.terminals[o.terminal]
        if o.status=='queued' and p and not p:isDead() and t then
            players[actor]=p
            local ok,why=pcall(service.deliver,service,actor,t)
            if ok then p:Say('Astrolux vehicle delivered. Its key is in your inventory.')
            elseif o.status=='hold' then p:Say('Astrolux delivery needs administrator inspection; do not purchase again.') end
        end
    end
end
local lastDelivery=0
Events.OnTick.Add(function()
    local now=getTimestampMs();if now-lastDelivery<2000 then return end;lastDelivery=now
    S.deliverQueued();S.refreshKioskLocks()
end)
if Events.OnDisconnect then Events.OnDisconnect.Add(function(p)
    if p then local actor=tostring(p:getUsername());players[actor]=nil;last[actor]=nil;if service then service.quotes[actor]=nil end;if trades then trades.quotes[actor]=nil end end
end) end
return S
