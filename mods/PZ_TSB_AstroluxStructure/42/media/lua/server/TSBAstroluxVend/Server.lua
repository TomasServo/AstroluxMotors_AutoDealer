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
local Power=require 'TSBAstroluxVend/Power'
local TradeIn=require 'TSBAstroluxVend/TradeIn'
local Border=require 'TSBAstroluxVend/DeliveryBorder'
local TradeBatch=require 'TSBAstroluxVend/TradeBatch'
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
    trades=TradeBatch.new(db,{now=getTimestamp,create=instanceItem,notify=function(container,item)if isServer()then sendAddItemToContainer(container,item)end end})
    payments=Cash.new(db,{now=getTimestamp,createMoney=function() return instanceItem('Base.Money') end,
        notify=function(container,item,added)
            if isServer() then
                if added then sendAddItemToContainer(container,item) else sendRemoveItemFromContainer(container,item) end
            end
        end})
    payments=Bank.new(db,payments,function() return true end)
    service=Domain.new(db,{now=getTimestamp,
        requireFunds=function(actor,amount,method)
            local p=players[actor];if not p then fail('Buyer unavailable.') end
            local balance=payments:balance(p,method)
            if balance<amount then
                local source=method=='cash' and 'carried cash' or 'bank balance'
                return false,'Purchase rejected: insufficient '..source..'. $'..balance..' available; $'..amount..' required. No order placed or payment taken.'
            end
            return true
        end,
        preflight=function(order) require('TSBAstroluxVend/DeliveryPreflight').verify(order,getScriptManager()) end,
        authorizeDelivery=function(order)
            local attempts=order.payment=='serverBank' and db.bankPayments or db.payments
            local attempt=attempts and attempts[order.actor]
            if not attempt or attempt.status~='committed' or attempt.receipt~='astroluxRebuild:'..order.id
                or (order.payment=='serverBank' and (attempt.provider or 'tsb')~=((order.paymentMethod or 'bank'):match('^bank:(.+)$') or 'tsb')) then
                order.status='hold';order.error='Payment receipt is missing or uncertain; inspect before recovery.'
                fail(order.error)
            end
        end,
        clear=function(t,own,script) Power.require(t);return Spawn.choose(db,t,own,script) end,
        charge=function(actor,amount,receipt,apply,method,beforeDebit)
            local p=players[actor];if not p then fail('Buyer unavailable.') end
            return payments:charge(p,amount,receipt,apply,method,beforeDebit)
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
    local obj=require('TSBAstroluxVend/KioskIdentity').resolve(list,args)
    if not obj then fail('Kiosk unavailable; close and reopen the sales menu.') end
    local id=obj:getModData().TSBAstroluxVend
    local t=id and db.terminals[id];local sprite=obj:getSprite()
    if not t or t.packed or not sprite or t.x~=args.x or t.y~=args.y or t.z~=0 or t.sprite~=sprite:getName()
        or not t.sprite:match('^TSBAstroluxKiosk_[0-3]$') then fail('Registered Astrolux kiosk required.') end
    for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
        if r.releaseTower and r.status~='ready'and t.x>=r.x and t.x<=r.x+12 and t.y>=r.y and t.y<=r.y+12 then fail('Tower placement is held. Use Inspect Held Astrolux Placements before trading.')end
    end
    return t
end
local function tradeRetail(vehicle)
    local offer=offers():tradeOffer(vehicle:getScript():getFullName())
    return offer and offer.price
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
    local paymentOptions=payments:options(p)
    local bankOK=#paymentOptions.methods>1
    local bankBalance=paymentOptions.balances[args and args.payment] or paymentOptions.balances[paymentOptions.methods[2]]
    require('TSBAstroluxVend/KioskLabels').ensure(db)
    local pricing=admin(p) and Prices.view(db.pricing) or nil
    if pricing then pricing.recoveryTrades=require('TSBAstroluxVend/TradeRecovery').rows(db,t.id);pricing.audio=Audio.settings();pricing.recoveryOrders=require('TSBAstroluxVend/OrderRecovery').rows(db,t.id,getCell():getVehicles())end
    if pricing then pricing.vehicleAvailability=offers().vehicleAvailability;pricing.scripts=offers().installedScripts;pricing.scriptLabels=offers().scriptLabels;pricing.accessoryOptions={};pricing.accessoryIssues={};pricing.colorOptions={}
        for _,name in ipairs(pricing.scripts)do
            pricing.colorOptions[name]=Paint.options(getScriptManager():getVehicle(name),db.pricing)
            pricing.accessoryOptions[name]=Equipment.options(getScriptManager():getVehicle(name),db.pricing,true)
            pricing.accessoryIssues[name]=Equipment.issues(getScriptManager():getVehicle(name))
            for _,row in ipairs(Families.adminRows(db.pricing,name,offers().installable))do
                pricing.accessoryOptions[name][#pricing.accessoryOptions[name]+1]=row
            end
        end
    end
    local order=db.orders[tostring(p:getUsername())]
    local rules=Prices.view(db.pricing)
    reply(p,{ok=true,message=message or (not Power.available(t) and Power.message) or 'Select a vehicle and request a price quote.',terminal=t.id,displayNumber=t.displayNumber,spawnArea=t.spawnArea,deliveryBorder=t.deliveryBorder==true,deliveryNumber=t.deliveryNumber~=false,
        offers=list,page=page,pages=pages,total=total,quote=quote,
        order=order and {id=order.id,status=order.status,terminal=order.terminal},simple=true,
        bankAvailable=bankOK,bankBalance=bankOK and bankBalance or nil,paymentMethods=paymentOptions.methods,paymentLabels=paymentOptions.labels,bankBalances=paymentOptions.balances,
        tradeVehicles=trades:list(p,t,tradeRetail),tradeSuccess=tradeSuccess,tradeRules={buybackPercent=rules.buybackPercent,minimumBuybackParts=rules.minimumBuybackParts},tradeInsEnabled=TradeIn.enabled(db),tradeQuote=tradeQuote,balance=payments:balance(p),adminPricing=pricing})
end
local function handle(p,command,args)
    init()
    if not p or p:isDead() or type(args)~='table' then return end
    local actor=tostring(p:getUsername());players[actor]=p
    local now=getTimestampMs();if last[actor] and now-last[actor]<250 then reply(p,{ok=false,message='Please wait a moment, then try again.'});return end;last[actor]=now
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
        local area,why=Areas.rectangle(args.ax,args.ay,args.bx,args.by,args.heading,args.gap~=nil and args.gap or (t.spawnArea and t.spawnArea.gap),args.rowGap~=nil and args.rowGap or (t.spawnArea and t.spawnArea.rowGap))
        if not area then fail(why) end
        for _,o in pairs(db.orders) do
            if o.terminal==t.id and o.status~='delivered' then fail('Resolve outstanding orders before changing the area.') end
        end
        -- No tower, kiosk-distance, total-size or current streaming requirement.
        area.revision=(t.spawnArea and t.spawnArea.revision or 0)+1
        t.spawnArea=area;service.quotes={};if trades then trades.quotes={} end
        Border.safeRefresh(db,Spawn.regions())
        reply(p,{ok=true,areaSaved=true,terminal=t.id,spawnArea=area,deliveryBorder=t.deliveryBorder==true,deliveryNumber=t.deliveryNumber~=false,message='Vehicle spawn area saved. Vehicles face '..area.heading..'.'})
        return
    end
    local t,why=terminal(p,args)
    if not t then reply(p,{ok=false,message=why});return end
    if command=='areaGap'then
        local area=require('TSBAstroluxVend/AreaGap').apply(db,t,args,admin(p))
        service.quotes={};if trades then trades.quotes={}end
        reply(p,{ok=true,areaSaved=true,terminal=t.id,spawnArea=area,deliveryBorder=t.deliveryBorder==true,deliveryNumber=t.deliveryNumber~=false,message='Car spacing saved: '..tostring(area.gap)..' tiles; rows: '..tostring(area.rowGap or area.gap)..' tiles minimum. Rectangle and direction unchanged.'})
        return
    end
    if command=='areaDelete'then
        require('TSBAstroluxVend/AreaDelete').apply(db,t,args,admin(p))
        service.quotes={};if trades then trades.quotes={}end
        Border.safeRefresh(db,Spawn.regions())
        reply(p,{ok=true,areaSaved=true,terminal=t.id,deliveryBorder=false,message='Delivery zone deleted. Designate a new zone before buying vehicles. Existing vehicles were not moved or removed.'})
        return
    end
    if command=='zoneNumber'then
        if not admin(p)then fail('Administrator access required.')end
        if type(args.deliveryNumber)~='boolean'or not t.spawnArea then view(p,t,'Configure a delivery zone and choose its number visibility.',nil,args);return end
        t.deliveryNumber=args.deliveryNumber
        view(p,t,t.deliveryNumber and 'Yellow delivery number enabled.'or 'Yellow delivery number disabled.',nil,args);return
    end
    if command=='zoneBorder'then
        if not admin(p)then fail('Administrator access required.')end
        if type(args.deliveryBorder)~='boolean'then fail('Choose whether to display the delivery border.')end
        if args.deliveryBorder and not t.spawnArea then fail('Configure this kiosk delivery zone first.')end
        t.deliveryBorder=args.deliveryBorder
        Border.safeRefresh(db,Spawn.regions())
        view(p,t,t.deliveryBorder and 'Yellow delivery border enabled.'or 'Yellow delivery border disabled.',nil,args);return
    end
    if command=='setPrices' and (args.action=='tradeRecoveryRefresh' or args.action=='tradeRecoveryResolve')then
        if not admin(p)then reply(p,{ok=false,message='Administrator access required.'});return end
        local message='Held trade-ins refreshed.'
        if args.action=='tradeRecoveryResolve'then
            local ok,why=require('TSBAstroluxVend/TradeRecovery').resolve(db,t.id,args,p,{
                now=getTimestamp,create=instanceItem,
                player=function(name)
                    if not isServer()then return tostring(p:getUsername())==name and p or nil end
                    local list=getOnlinePlayers();for i=0,list:size()-1 do local other=list:get(i);if tostring(other:getUsername())==name then return other end end
                end,
                notify=function(inv,item)if isServer()then sendAddItemToContainer(inv,item)end end})
            message=why
            if ok then trades:decline({getUsername=function()return args.tradeActor end})end
        end
        view(p,t,message,nil,args);return
    end
    if command=='setPrices' and (args.action=='orderRefresh' or args.action=='orderCancel') then
        if not admin(p) then reply(p,{ok=false,message='Administrator access required.'});return end
        local message='Orders refreshed; no changes made.'
        if args.action=='orderCancel' then
            local ok,why=require('TSBAstroluxVend/OrderRecovery').cancel(db,t.id,args,getCell():getVehicles(),actor,getTimestamp())
            message=why
            if ok then service.quotes[args.orderActor]=nil;S.refreshKioskLocks() end
        end
        view(p,t,message,nil,args);return
    end
    local oldOrder=db.orders[actor]
    if oldOrder and oldOrder.terminal==t.id and oldOrder.status=='queued'
        and not oldOrder.spawnStarted and not oldOrder.paymentCommitted and not oldOrder.keyIssued and oldOrder.vehicleId==nil then
        local recovery=require 'TSBAstroluxVend/OrderRecovery'
        local allowed,reason,manual=recovery.check(db,oldOrder,getCell():getVehicles())
        if allowed and not manual then
            recovery.cancel(db,t.id,{confirmed=true,orderActor=actor,orderId=tostring(oldOrder.id)},getCell():getVehicles(),'automatic_no_queue_migration',getTimestamp())
        end
    end
    local pending=db.orders[actor]
    if pending and pending.status~='delivered' and (command=='open' or command=='quote' or command=='buy'
        or (command=='deliver' and pending.status~='queued' and pending.status~='paid')) then
        service.quotes[actor]=nil
        local message='Order '..tostring(pending.id)..' is '..tostring(pending.status)..'. Resolve this order before purchasing again.'
        if admin(p) then
            local summary,detail=require('TSBAstroluxVend/OrderInspection').inspect(db,pending,getCell():getVehicles())
            message=summary..' Inspection only; no payment or vehicle changes made.'
            print('[Astrolux Order Inspection] '..detail)
        end
        view(p,t,message,nil,args);return
    end
    if command=='open' then view(p,t,nil,nil,args);return end
    if command=='tradeDecline' then trades:decline(p);view(p,t,'Trade-in declined. Your vehicle is unchanged.',nil,args);return end
    if command=='tradeQuote' or command=='tradeAccept' then
        if not TradeIn.enabled(db)then fail('Vehicle buybacks are disabled.')end
        if not t.spawnArea then fail('Configure a delivery zone first.')end
        local revision=(db.pricing or {}).revision or 0
        if command=='tradeQuote'then
            trades:decline(p)
            local vehicles=TradeBatch.resolve(t,args.tradeVehicles)
            local appraisal=trades:quote(p,t,vehicles,tradeRetail,revision)
            view(p,t,'Review every selected vehicle and its cash value. Accepting removes the selected vehicles.',nil,args,appraisal)
        else
            local amount,count=trades:accept(p,t,args.tradeToken,tradeRetail,revision)
            if not amount then view(p,t,count,nil,args);return end
            view(p,t,'Traded in '..count..' vehicles. $'..amount..' cash added to your inventory.',nil,args,nil,args.tradeToken)
        end
        return
    end
    if command=='setPrices' then
        if not admin(p) then fail('Administrator access required.') end
        if args.action=='audio'then
            db.audio=Audio.edit(args);Audio.publish()
            view(p,t,'Sound settings saved.',nil,args);return
        end
        if args.action=='partRole'then
            local valid,why=require('TSBAstroluxVend/AppraisalPartRoles').validateEdit(args,getScriptManager())
            if not valid then view(p,t,why,nil,args);return end
        end
        local candidate=Prices.edit(db.pricing,args,offers())
        local rebuilt=V.new(getScriptManager(),candidate,function(o) return Demand.offer(db,o,getGameTime():getWorldAgeHours()) end)
        if args.action~='availability' then for _,o in ipairs(offers().offers) do if not rebuilt.byID[o.id] then fail('Price settings would invalidate an existing offer.') end end end
        if args.action=='demand'then Demand.settle(db,getGameTime():getWorldAgeHours())end
        local resetCount
        if args.action=='resetDemand'then resetCount=Demand.reset(db,args.demandClass,getScriptManager(),getGameTime():getWorldAgeHours())end
        if args.action=='resetModelDemand'then resetCount=Demand.resetModel(db,offers(),args.script,getGameTime():getWorldAgeHours())end
        db.pricing=candidate;catalog=rebuilt;service.quotes={};if trades then trades.quotes={} end
        Buffs.publish();CamperCapacity.scan()
        local message=resetCount and ('Demand reset to base for '..resetCount..' vehicle families; unpaid quotes cancelled.')or 'Prices saved; unpaid quotes cancelled.'
        view(p,t,message,nil,args);return
    end
    if command=='deliver' then
        view(p,t,'Automatic and queued delivery are disabled. Resolve any old order, then request a fresh quote.',nil,args);return
    end
    if command~='quote' and command~='buy' then fail('Unsupported sales command.') end
    if not Power.available(t) then service.quotes[actor]=nil;view(p,t,Power.message,nil,args);return end
    local offer=offers():resolve(args.offer)
    -- The color/design menu includes ordinary variants as well as factory options.
    -- Let the authoritative catalog enforce family, availability and pricing.
    if args.configuration~=nil and type(args.configuration)~='string'then
        service.quotes[actor]=nil;view(p,t,'Invalid vehicle variation. Select a vehicle again.',nil,args);return
    end
    local validVariant,selectedVariant=pcall(function()return offers():variant(offer.id,args.configuration)end)
    if not validVariant then
        service.quotes[actor]=nil;view(p,t,'Vehicle variation unavailable: '..tostring(selectedVariant),nil,args);return
    end
    offer=selectedVariant
    local paint=Paint.select(getScriptManager():getVehicle(offer.script),db.pricing,args.paint,offers():paintVariants(offer))
    if paint.script then offer=offers():variant(offer.id,paint.script)end
    offer=Paint.attach(offer,paint)
    offer=Equipment.offer(offer,getScriptManager():getVehicle(offer.script),db.pricing,args.equipment,args.camperTop)
    -- Definition/configuration errors are normal refusal, before any order or charge.
    local ready,reason=pcall(require('TSBAstroluxVend/DeliveryPreflight').verify,offer,getScriptManager())
    if not ready then service.quotes[actor]=nil;view(p,t,'Delivery unavailable: '..tostring(reason),nil,args);return end
    local method=payments:method(args.payment)
    -- Ordinary placement rejection is user feedback, not a Lua exception.
    -- Revalidate again in Domain immediately before charging; never weaken clearance.
    local position,why=Spawn.choose(db,t,nil,offer.script,true)
    if not position then service.quotes[actor]=nil;reply(p,{ok=false,message=why});return end
    if command=='quote' then view(p,t,'Review the quote and confirm within 60 seconds.',service:quote(actor,t,offer,method),args)
    else
        local order,reason=service:buy(actor,args.token,t,offer,method)
        if not order then view(p,t,reason,nil,args);return end
        local message='Vehicle delivered; its key is in your inventory.'
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
    -- Immediate purchases only. Never automatically retry an old unpaid order.
end

local lastDelivery=0
Events.OnTick.Add(function()
    local now=getTimestampMs();if now-lastDelivery<2000 then return end;lastDelivery=now
    S.deliverQueued();S.refreshKioskLocks();Border.safeRefresh(db,Spawn.regions())
end)
if Events.OnDisconnect then Events.OnDisconnect.Add(function(p)
    if p then local actor=tostring(p:getUsername());players[actor]=nil;last[actor]=nil;if service then service.quotes[actor]=nil end;if trades then trades.quotes[actor]=nil end end
end) end
return S
