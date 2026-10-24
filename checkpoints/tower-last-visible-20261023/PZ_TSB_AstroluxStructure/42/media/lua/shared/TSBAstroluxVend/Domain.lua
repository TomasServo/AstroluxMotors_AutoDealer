local D={}
local function fail(s) error(s,0) end
function D.new(db,adapter)
    db.terminals=db.terminals or {};db.orders=db.orders or {};db.serial=db.serial or 0
    local self={db=db,a=adapter,quotes={}}
    function self:quote(actor,terminal,offer,method)
        local old=db.orders[actor]
        if old and old.status~='delivered' then fail('An existing order needs delivery or administrator inspection.') end
        adapter.clear(terminal,nil,offer.script)
        db.serial=db.serial+1
        local q={token=tostring(db.serial),terminal=terminal.id,offer=offer.id,
            configurationLabel=offer.configurationLabel,equipment=offer.equipment,equipmentKey=offer.equipmentKey,equipmentLabel=offer.equipmentLabel,camperTop=offer.camperTop,camperSurcharge=offer.camperSurcharge,pricingRevision=offer.pricingRevision,paint=offer.paint,paintKey=offer.paintKey,payment=method or 'cash',price=offer.price,pricing=offer.pricing,basePrice=offer.basePrice,demandRevision=offer.demandRevision,script=offer.script,expires=adapter.now()+60}
        self.quotes[actor]=q
        return q
    end
    function self:buy(actor,token,terminal,offer,method)
        local q=self.quotes[actor]
        if not q or q.token~=token or q.terminal~=terminal.id or q.offer~=offer.id
            or (q.payment or 'cash')~=(method or 'cash') or q.paintKey~=offer.paintKey
            or q.equipmentKey~=offer.equipmentKey
            or q.camperTop~=offer.camperTop or q.camperSurcharge~=offer.camperSurcharge
            or q.basePrice~=offer.basePrice or q.demandRevision~=offer.demandRevision or q.pricingRevision~=offer.pricingRevision
            or (q.basePrice==nil and q.price~=offer.price) or q.script~=offer.script or q.expires<adapter.now() then fail('Quote expired. Request a new quote.') end
        self.quotes[actor]=nil
        local old=db.orders[actor]
        if old and old.status~='delivered' then fail('An order is already outstanding.') end
        local position=adapter.clear(terminal,nil,offer.script)
        local order={id=q.token,actor=actor,terminal=terminal.id,script=offer.script,
            configurationLabel=q.configurationLabel,equipment=q.equipment,equipmentKey=q.equipmentKey,equipmentLabel=q.equipmentLabel,camperTop=q.camperTop,camperSurcharge=q.camperSurcharge,pricingRevision=q.pricingRevision,paint=q.paint,paintKey=q.paintKey,price=q.price,basePrice=q.basePrice,pricing=q.pricing,placement=position,condition=100,payment=q.payment~='cash' and 'serverBank' or 'vanillaCash',paymentMethod=q.payment,status='queued',paymentTiming='onDelivery',created=adapter.now()}
        -- Persist an unpaid queue entry before any external/native operation.
        -- No funds are reserved: ability to pay is rechecked on delivery.
        db.orders[actor]=order
        if order.placement and order.placement.deferred then return order end
        return self:deliver(actor,terminal)
    end
    function self:deliver(actor,terminal)
        local order=db.orders[actor]
        if not order or order.terminal~=terminal.id then fail('No order at this terminal.') end
        if order.status=='delivered' then fail('This order was already delivered.') end
        if order.status~='paid' and order.status~='queued' then fail('Delivery is on hold. Ask an administrator to inspect the area and order.') end
        local payOnDelivery=order.paymentTiming=='onDelivery'
        -- Existing prepaid orders retain receipt validation and never pay twice.
        if not payOnDelivery and adapter.authorizeDelivery then adapter.authorizeDelivery(order) end
        local position=adapter.clear(terminal,order,order.script)
        if position then order.placement=position end
        if order.placement and order.placement.deferred then return order end
        -- Persist before native effects; interrupted dispatch is never replayed.
        order.status='dispatching'
        local started=false
        local function spawn()
            started=true;order.spawnStarted=true
            adapter.spawn(order,terminal)
        end
        local ok,err=pcall(function()
            if payOnDelivery then
                local method=order.payment=='serverBank' and (order.paymentMethod or 'bank') or 'cash'
                -- Cash validates the exact plan, spawns, then deducts. The bank
                -- bridge must commit its own transaction before native effects.
                if method~='cash'then started=true end
                adapter.charge(actor,order.price,'astroluxRebuild:'..order.id,function()end,method,method=='cash' and spawn or nil)
                order.paymentCommitted=true
                if adapter.authorizeDelivery then adapter.authorizeDelivery(order)end
                if method~='cash'then spawn()end
            else spawn()end
            order.status='delivered';order.error=nil
        end)
        -- Insufficient/moved cash before native effects leaves a safe unpaid
        -- queue. Partial spawn, debit or bank uncertainty requires inspection.
        if not ok and payOnDelivery and not started then
            order.status='queued';order.error=tostring(err);fail(tostring(err))
        end
        if not ok then
            order.status='hold';order.error=tostring(err)
            fail('Delivery/payment needs administrator inspection. Do not buy again.')
        end
        -- Delivery succeeded. Never retry the vehicle spawn if demand accounting fails.
        if adapter.completed then
            local counted,why=pcall(adapter.completed,order)
            if not counted then order.demandWarning=tostring(why)end
        end
        return order
    end
    return self
end
return D
