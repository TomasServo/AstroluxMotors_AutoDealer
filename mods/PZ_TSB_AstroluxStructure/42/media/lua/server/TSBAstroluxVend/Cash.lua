local Amount=require 'TSBAstroluxVend/Amount'
-- Standalone vanilla currency. Native UnpackMoneyBundle yields 100 Base.Money.
local Cash={values={['Base.Money']=1,['Base.MoneyBundle']=100}}
local function fail(message)error(message,0)end
function Cash.collect(player)
    if not player or player:isDead() then fail('Buyer is unavailable.')end
    local bills,bundles,total,visited={},{},0,{}
    local function walk(container)
        if visited[container] then return end;visited[container]=true
        local items=container:getItems()
        for i=0,items:size()-1 do
            local item=items:get(i);local value=Cash.values[item:getFullType()]
            if value and not item:isEquipped() and not item:isFavorite() then
                local target=value==100 and bundles or bills
                target[#target+1]={item=item,container=container,value=value};total=total+value
            elseif instanceof(item,'InventoryContainer') then walk(item:getInventory()) end
        end
    end
    walk(player:getInventory())
    return bills,bundles,total
end
function Cash.new(db,adapter)
    db.payments=db.payments or {};db.cashAudit=db.cashAudit or {}
    for _,attempt in pairs(db.payments)do
        if attempt.status=='processing' then attempt.status='hold';attempt.error='Interrupted cash payment; inspect inventory and order.'end
    end
    local self={}
    function self:balance(player)local _,_,total=Cash.collect(player);return total end
    function self:charge(player,amount,receipt,apply,beforeDebit)
        if not Amount.valid(amount,1) then fail('Invalid cash amount.')end
        if type(receipt)~='string' or #receipt>100 then fail('Invalid receipt.')end
        local actor=tostring(player:getUsername());local previous=db.payments[actor]
        if previous and (previous.status=='hold' or previous.status=='processing')then fail('Cash payment is on hold for administrator inspection.')end
        if previous and previous.receipt==receipt and previous.status=='committed' then fail('Payment already committed.')end
        local bills,bundles,total=Cash.collect(player)
        if total<amount then fail('Insufficient carried cash: $'..total..' available; $'..amount..' required. Favorite/equipped cash is excluded.')end
        local selected={};local remaining=amount
        local bundleCount=math.min(#bundles,math.floor(remaining/100))
        for i=1,bundleCount do selected[#selected+1]=bundles[i];remaining=remaining-100 end
        local billCount=math.min(#bills,remaining)
        for i=1,billCount do selected[#selected+1]=bills[i];remaining=remaining-1 end
        local change=0
        if remaining>0 then
            assert(bundles[bundleCount+1],'Cash plan failed')
            selected[#selected+1]=bundles[bundleCount+1];change=100-remaining
        end
        local attempt={receipt=receipt,amount=amount,change=change,status='processing',time=adapter.now()}
        db.payments[actor]=attempt
        local undo,removed,added={},{},{}
        local tx={}
        function tx:set(object,key,value)
            local before=object[key];undo[#undo+1]=function()object[key]=before end;object[key]=value
        end
        local inventory=player:getInventory()
        local ok,err=pcall(function()
            -- Validate and plan cash first; create the purchased vehicle before
            -- the first bill is removed. Caller holds partial native effects.
            if beforeDebit then beforeDebit()end
            for _,entry in ipairs(selected)do
                local item,container=entry.item,entry.container
                if item:getContainer()~=container then fail('Cash moved before payment.')end
                removed[#removed+1]=entry
                container:DoRemoveItem(item)
                if item:getContainer() then fail('Native cash removal failed.')end
            end
            for i=1,change do
                local item=adapter.createMoney();if not item then fail('Could not create change.')end
                added[#added+1]=item
                if inventory:AddItem(item)~=item or item:getContainer()~=inventory then fail('Could not return change.')end
            end
            apply(tx)
        end)
        if not ok then
            local restored=true
            for i=#undo,1,-1 do if not pcall(undo[i])then restored=false end end
            for i=#added,1,-1 do
                if not pcall(function()
                    local item=added[i];local container=item:getContainer()
                    if container then assert(container==inventory,'Change moved');container:DoRemoveItem(item);assert(not item:getContainer())end
                end)then restored=false end
            end
            for i=#removed,1,-1 do
                if not pcall(function()
                    local entry=removed[i];local current=entry.item:getContainer()
                    if current~=entry.container then assert(not current,'Cash moved');assert(entry.container:AddItem(entry.item)==entry.item);assert(entry.item:getContainer()==entry.container)end
                end)then restored=false end
            end
            attempt.status=restored and 'failed' or 'hold';attempt.error=tostring(err)
            fail(restored and ('Payment cancelled; cash restored. '..tostring(err)) or 'Cash rollback needs administrator inspection. Further payment is blocked.')
        end
        attempt.status='committed'
        local audit=db.cashAudit;audit[#audit+1]={actor=actor,receipt=receipt,amount=amount,change=change,time=adapter.now()}
        if #audit>2000 then table.remove(audit,1)end
        -- Inventory notifications follow commit. Never repeat payment after a network failure.
        for _,entry in ipairs(removed)do
            if not pcall(adapter.notify,entry.container,entry.item,false)then attempt.syncWarning=true end
        end
        for _,item in ipairs(added)do
            if not pcall(adapter.notify,inventory,item,true)then attempt.syncWarning=true end
        end
        return true
    end
    return self
end
return Cash
