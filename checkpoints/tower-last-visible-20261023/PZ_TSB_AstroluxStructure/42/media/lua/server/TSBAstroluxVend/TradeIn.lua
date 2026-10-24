local Appraisal=require 'TSBAstroluxVend/Appraisal'
local C=require 'TSBAstroluxVend/Config'
local Areas=require 'TSBAstroluxVend/SpawnAreas'
local T={}
local function fail(s)error(s,0)end
-- Count reviewed standard slots equally. Battery and optional extras do not count.
function T.checkParts(appraisal,settings)
    settings=settings or {};local minimum=settings.minimumBuybackParts or 75
    local installed,total=0,0
    for _,part in ipairs(appraisal.parts)do
        if part.id~='Battery' or settings.excludeBuybackBattery==false then
            total=total+1
            if not part.missing then installed=installed+1 end
        end
    end
    if total==0 or installed*100<total*minimum then
        fail('Trade-in requires at least '..minimum..'% of standard parts installed'..(settings.excludeBuybackBattery~=false and ', excluding the battery' or '')..' ('..installed..'/'..total..').')
    end
end
local function keyIn(container,id,seen)
    seen=seen or {};if seen[container]then return end;seen[container]=true
    local items=container:getItems()
    for i=0,items:size()-1 do
        local item=items:get(i)
        if instanceof(item,'Key') and item:getKeyId()==id then return item end
        if instanceof(item,'InventoryContainer')then local key=keyIn(item:getInventory(),id,seen);if key then return key end end
    end
end
-- Match the physical world bounds used by delivery obstruction checks.
-- Native getSquare() uses the physics Z; a slightly negative resting height
-- can resolve below ground. Resolve loaded ground explicitly instead.
function T.inArea(terminal,vehicle)
    local a=terminal and terminal.spawnArea
    if not a or not vehicle or vehicle:isRemovedFromWorld() then return false end
    local z=vehicle:getZ()
    if type(z)~='number' or z~=z or z < -0.5 or z >= 0.5 then return false end
    local cell=getCell()
    if not cell or not cell:getGridSquare(math.floor(vehicle:getX()),math.floor(vehicle:getY()),0) then return false end
    local ok,bounds=pcall(Areas.vehicleBounds,vehicle)
    if not ok or not bounds then return false end
    -- Inclusive selected tiles occupy [x1,x2+1) by [y1,y2+1).
    return Areas.overlap({x=(a.x1+a.x2+1)/2,y=(a.y1+a.y2+1)/2,
        rx=(a.x2-a.x1+1)/2,ry=(a.y2-a.y1+1)/2,world=true},bounds)
end
function T.validate(player,terminal,vehicle,settings)
    settings=settings or {}
    if not terminal.spawnArea or not vehicle or vehicle:isRemovedFromWorld() then return nil,'Park a vehicle in this terminal delivery area.'end
    local a=terminal.spawnArea
    if not T.inArea(terminal,vehicle) then return nil,'Vehicle moved outside the trade-in area.'end
    if vehicle:isEngineRunning() or vehicle:hasPassenger() then return nil,'Switch off the engine and have everyone exit the vehicle.'end
    if vehicle:getVehicleTowing() or vehicle:getTowingPartner() then return nil,'Detach all towing connections before trade-in.'end
    local animals=vehicle:getAnimals();if animals and animals:size()>0 then return nil,'Remove all animals before trade-in.'end
    for i=0,vehicle:getPartCount()-1 do
        local inventory=vehicle:getPartByIndex(i):getItemContainer()
        if inventory and inventory:getItems():size()>0 then return nil,'Empty the '..tostring(vehicle:getPartByIndex(i):getId())..' container before trading in this vehicle.'end
    end
    if settings.allowHotwiredBuybacks==false and vehicle:isHotwired() then return nil,'Hotwired vehicle trade-ins are disabled by the administrator.'end
    if settings.requireBuybackKey~=false and not keyIn(player:getInventory(),vehicle:getKeyId()) then return nil,'Carry this vehicle key to authorize its trade-in.'end
    if vehicle:getModData().AstroluxTradeIn then return nil,'Vehicle has an earlier trade-in record; administrator inspection is required.'end
    return true
end
function T.enabled(db)
    local settings=db.pricing or {}
    if settings.buybacksEnabled~=nil then return settings.buybacksEnabled==true end
    return C.tradeInsEnabled==true
end
function T.new(db,adapter)
    db.tradeIns=db.tradeIns or {};db.tradeSerial=db.tradeSerial or 0;db.tradeAudit=db.tradeAudit or {}
    for _,r in pairs(db.tradeIns)do if r.status=='processing' then r.status='hold';r.error='Interrupted trade-in; inspect vehicle and cash.'end end
    local self={quotes={}}
    local function available(actor)
        local r=db.tradeIns[actor]
        if r and (r.status=='hold' or r.status=='processing')then fail('Previous trade-in needs administrator inspection.')end
    end
    local function settled(vehicle)
        local id=vehicle:getModData().TSBAstroluxVendOrder
        if id then
            for _,order in pairs(db.orders or {})do
                if order.id==id and order.status~='delivered' then fail('Resolve the vehicle purchase hold before trading it in.')end
            end
        end
    end
    function self:quote(player,terminal,vehicle,retail,revision)
        if not T.enabled(db) then fail('Trade-ins are disabled pending testing.')end
        local actor=tostring(player:getUsername());available(actor);local valid,why=T.validate(player,terminal,vehicle,db.pricing);if not valid then fail(why)end;settled(vehicle)
        local appraisal=Appraisal.calculate(vehicle,retail,((db.pricing or {}).buybackPercent or C.tradeInRate*100)/100,((db.pricing or {}).damagePercent or 100)/100)
        T.checkParts(appraisal,db.pricing)
        if appraisal.amount<1 then
 self.quotes[actor]=nil
 return {script=vehicle:getScript():getFullName(),amount=0,retail=retail,maximum=appraisal.maximum,parts=appraisal.parts,
 reason='No payable offer: current base retail $'..retail..', buyback '..tostring((db.pricing or {}).buybackPercent or C.tradeInRate*100)..'%. The whole-dollar appraisal is $0. An administrator can review the vehicle price and buyback settings.'}
 end
        db.tradeSerial=db.tradeSerial+1
        local token=tostring(db.tradeSerial)
        self.quotes[actor]={token=token,vehicle=vehicle,terminal=terminal.id,expires=adapter.now()+60,
            revision=revision,appraisal=appraisal,script=vehicle:getScript():getFullName()}
        return {token=token,script=vehicle:getScript():getFullName(),amount=appraisal.amount,retail=retail,
            maximum=appraisal.maximum,parts=appraisal.parts,expires=adapter.now()+60}
    end
    function self:decline(player)self.quotes[tostring(player:getUsername())]=nil end
    function self:accept(player,terminal,token,retail,revision)
        if not T.enabled(db) then fail('Trade-ins are disabled pending testing.')end
        local actor=tostring(player:getUsername());available(actor)
        local q=self.quotes[actor]
        if not q or q.token~=token or q.terminal~=terminal.id or q.expires<adapter.now() or q.revision~=revision then fail('Trade-in quote expired. Request another appraisal.')end
        local valid,why=T.validate(player,terminal,q.vehicle,db.pricing);if not valid then fail(why)end;settled(q.vehicle)
        local fresh=Appraisal.calculate(q.vehicle,retail,((db.pricing or {}).buybackPercent or C.tradeInRate*100)/100,((db.pricing or {}).damagePercent or 100)/100)
        T.checkParts(fresh,db.pricing)
        if fresh.fingerprint~=q.appraisal.fingerprint or fresh.amount~=q.appraisal.amount or retail~=q.appraisal.retail then
            self.quotes[actor]=nil;fail('Vehicle condition or price changed. Request another appraisal.')
        end
        -- Prepare physical currency and check capacity before irreversible removal.
        local payout={};local weight=0;local amount=fresh.amount
        local function add(kind,count)
            for i=1,count do
                local item=adapter.create(kind);if not item then fail('Could not prepare trade-in payment.')end
                payout[#payout+1]=item;weight=weight+item:getActualWeight()
            end
        end
        add('Base.MoneyBundle',math.floor(amount/100));add('Base.Money',amount%100)
        local inventory=player:getInventory()
        if inventory:getCapacityWeight()+weight>inventory:getEffectiveCapacity(player) then fail('Make room in your main inventory for the cash payment.')end
        self.quotes[actor]=nil
        local record={token=token,script=q.script,amount=amount,status='processing',paidItems=0,time=adapter.now()}
        db.tradeIns[actor]=record
        local ok,err=pcall(function()
            q.vehicle:getModData().AstroluxTradeIn={actor=actor,token=token}
            q.vehicle:transmitModData()
            q.vehicle:permanentlyRemove()
            if not q.vehicle:isRemovedFromWorld() then fail('Native removal was not confirmed.')end
            record.removed=true
            for _,item in ipairs(payout)do
                if inventory:AddItem(item)~=item or item:getContainer()~=inventory then fail('Cash payout was interrupted.')end
                record.paidItems=record.paidItems+1
            end
        end)
        if not ok then record.status='hold';record.error=tostring(err);fail('Trade-in needs administrator inspection. Do not retry; vehicle/cash state has been recorded.')end
        record.status='paid'
        db.tradeAudit[#db.tradeAudit+1]={actor=actor,token=token,script=q.script,amount=amount,time=adapter.now()}
        if #db.tradeAudit>200 then table.remove(db.tradeAudit,1)end
        for _,item in ipairs(payout)do if not pcall(adapter.notify,inventory,item)then record.syncWarning=true end end
        return amount
    end
    return self
end
return T
