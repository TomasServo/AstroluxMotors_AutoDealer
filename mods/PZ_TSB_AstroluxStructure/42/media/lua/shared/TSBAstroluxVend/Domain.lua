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
            pricingRevision=offer.pricingRevision,paint=offer.paint,paintKey=offer.paintKey,payment=method or 'cash',price=offer.price,pricing=offer.pricing,basePrice=offer.basePrice,demandRevision=offer.demandRevision,script=offer.script,expires=adapter.now()+60}
        self.quotes[actor]=q
        return q
    end
    function self:buy(actor,token,terminal,offer,method)
        local q=self.quotes[actor]
        if not q or q.token~=token or q.terminal~=terminal.id or q.offer~=offer.id
            or (q.payment or 'cash')~=(method or 'cash') or q.paintKey~=offer.paintKey
            or q.basePrice~=offer.basePrice or q.demandRevision~=offer.demandRevision or q.pricingRevision~=offer.pricingRevision
            or (q.basePrice==nil and q.price~=offer.price) or q.script~=offer.script or q.expires<adapter.now() then fail('Quote expired. Request a new quote.') end
        self.quotes[actor]=nil
        local old=db.orders[actor]
        if old and old.status~='delivered' then fail('An order is already outstanding.') end
        local position=adapter.clear(terminal,nil,offer.script)
        local order={id=q.token,actor=actor,terminal=terminal.id,script=offer.script,
            pricingRevision=q.pricingRevision,paint=q.paint,paintKey=q.paintKey,price=q.price,basePrice=q.basePrice,pricing=q.pricing,placement=position,condition=100,payment=q.payment=='bank' and 'serverBank' or 'vanillaCash',status='paid',created=adapter.now()}
        adapter.charge(actor,q.price,'astroluxRebuild:'..q.token,function(tx)
            tx:set(db.orders,actor,order)
        end,q.payment)
        -- Queued means no native spawn/key operation has started. It is safe
        -- to resume after reload; dispatching/hold remain non-replayable.
        if order.placement and order.placement.deferred then order.status='queued';return order end
        return self:deliver(actor,terminal)
    end
    function self:deliver(actor,terminal)
        local order=db.orders[actor]
        if not order or order.terminal~=terminal.id then fail('No order at this terminal.') end
        if order.status=='delivered' then fail('This order was already delivered.') end
        if order.status~='paid' and order.status~='queued' then fail('Delivery is on hold. Ask an administrator to inspect the area and order.') end
        if adapter.authorizeDelivery then adapter.authorizeDelivery(order) end
        local position=adapter.clear(terminal,order,order.script)
        if position then order.placement=position end
        -- Set BEFORE native effects. Never automatically replay an uncertain spawn/key operation.
        order.status='dispatching'
        local ok,err=pcall(function()adapter.spawn(order,terminal);order.status='delivered' end)
        if not ok then
            order.status='hold';order.error=tostring(err)
            fail('Payment recorded; delivery needs administrator inspection. Do not buy again.')
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
