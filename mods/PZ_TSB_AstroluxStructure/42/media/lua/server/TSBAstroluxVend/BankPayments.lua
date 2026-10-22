local Amount=require 'TSBAstroluxVend/Amount'
local B={}
local function fail(message)error(message,0)end
function B.available()
    local bank=SpacebarEconomyServer
    return bank~=nil and bank.autoVendBridgeVersion==1
        and type(bank.serviceBalance)=='function' and type(bank.chargeService)=='function'
end
local function bridge()
    local bank=SpacebarEconomyServer
    if not B.available() then
        fail('Server bank is unavailable. No payment was taken.')
    end
    return bank
end
function B.new(db,cash,enabled)
    db.bankPayments=db.bankPayments or {};db.bankReceipts=db.bankReceipts or {}
    for _,attempt in pairs(db.bankPayments)do
        if attempt.status=='processing' then attempt.status='hold' end
    end
    local self={}
    function self:bankAvailable() return enabled() and B.available() end
    function self:method(method)
        method=method or 'cash'
        if method~='cash' and (method~='bank' or not enabled()) then fail('Payment method is not enabled.')end
        return method
    end
    function self:balance(player,method)
        if self:method(method)=='cash' then return cash:balance(player)end
        return bridge().serviceBalance(tostring(player:getUsername()))
    end
    function self:charge(player,amount,receipt,apply,method)
        method=self:method(method)
        local actor=tostring(player:getUsername())
        for _,attempt in ipairs({db.bankPayments[actor] or {},(db.payments or {})[actor] or {}})do
            if attempt.status=='hold' or attempt.status=='processing' then fail('Payment needs administrator inspection before another purchase.')end
        end
        if method=='cash' then return cash:charge(player,amount,receipt,apply)end
        if not Amount.valid(amount,1) then fail('Invalid purchase amount.')end
        if type(receipt)~='string' or #receipt>100 then fail('Invalid purchase receipt.')end
        local receipts=db.bankReceipts[actor] or {};db.bankReceipts[actor]=receipts
        if receipts[receipt] then fail('Bank receipt already used.')end
        local bank=bridge()
        if bank.serviceBalance(actor)<amount then fail('Insufficient bank balance. Deposit money at the bank first.')end
        local attempt={receipt=receipt,amount=amount,status='processing'}
        db.bankPayments[actor]=attempt
        local ok,result=pcall(bank.chargeService,actor,amount,receipt,function(tx)
            apply(tx)
            tx:set(receipts,receipt,true)
        end,'vehiclePurchase')
        if not ok or result~=true or not receipts[receipt] then
            attempt.status='hold';attempt.error=tostring(result)
            fail('Bank payment needs administrator inspection. Do not retry with cash.')
        end
        attempt.status='committed'
        return true
    end
    return self
end
return B
