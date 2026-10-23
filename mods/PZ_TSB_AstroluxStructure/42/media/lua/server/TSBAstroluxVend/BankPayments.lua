local Amount=require 'TSBAstroluxVend/Amount'
local Adapters=require 'TSBAstroluxVend/BankAdapters'
local B={}
local function fail(message)error(message,0)end
local function providerID(method)
 if method=='bank'then return 'tsb'end -- Existing TSB orders/clients.
 return type(method)=='string' and method:match('^bank:([a-z][a-z0-9_-]*)$')or nil
end
function B.available()return #Adapters.list()>0 end
function B.new(db,cash,enabled)
 db.bankPayments=db.bankPayments or {};db.bankReceipts=db.bankReceipts or {}
 for _,attempt in pairs(db.bankPayments)do if attempt.status=='processing'then attempt.status='hold'end end
 local self={}
 function self:bankAvailable()return enabled() and B.available()end
 function self:method(method)
  method=method or 'cash';if method=='cash'then return method end
  local id=providerID(method)
  if not enabled()or not id or not Adapters.providers[id]then fail('Payment method is not enabled.')end
  return method
 end
 function self:balance(player,method)
  method=self:method(method)
  if method=='cash'then return cash:balance(player)end
  return Amount.check(Adapters.get(providerID(method)).balance(tostring(player:getUsername())),0)
 end
 function self:options(player)
  local result={methods={'cash'},labels={cash='Pay with carried cash'},balances={}}
  if not enabled()then return result end
  for _,id in ipairs(Adapters.list())do
   local method='bank:'..id
   local ok,balance=pcall(self.balance,self,player,method)
   if ok then
    result.methods[#result.methods+1]=method;result.labels[method]='Pay from '..Adapters.providers[id].label
    result.balances[method]=balance
   end
  end
  return result
 end
 function self:charge(player,amount,receipt,apply,method,beforeDebit)
  method=self:method(method);local actor=tostring(player:getUsername())
  for _,attempt in ipairs({db.bankPayments[actor]or {},(db.payments or {})[actor]or {}})do
   if attempt.status=='hold'or attempt.status=='processing'then fail('Payment needs administrator inspection before another purchase.')end
  end
  if method=='cash'then return cash:charge(player,amount,receipt,apply,beforeDebit)end
  if beforeDebit then fail('Bank payments require their transactional debit before delivery.')end
  if not Amount.valid(amount,1)then fail('Invalid purchase amount.')end
  if type(receipt)~='string'or #receipt>100 then fail('Invalid purchase receipt.')end
  local id=providerID(method);local bank=Adapters.get(id)
  local receipts=db.bankReceipts[actor]or {};db.bankReceipts[actor]=receipts
  if receipts[receipt]then fail('Bank receipt already used.')end
  if self:balance(player,method)<amount then fail('Insufficient bank balance. Deposit money at the bank first.')end
  local attempt={receipt=receipt,amount=amount,provider=id,status='processing'}
  db.bankPayments[actor]=attempt
  local applied,active=false,true
  local ok,result=pcall(bank.charge,actor,amount,receipt,function(tx)
   assert(active and not applied,'Bank callback repeated or asynchronous');applied=true
   assert(type(tx)=='table'and type(tx.set)=='function','Bank must provide a rollback-aware transaction')
   apply(tx);tx:set(receipts,receipt,true)
  end)
  active=false
  if not ok or result~=true or not applied or not receipts[receipt]then
   attempt.status='hold';attempt.error=tostring(result)
   fail('Bank payment needs administrator inspection. Do not retry with cash.')
  end
  attempt.status='committed';return true
 end
 return self
end
return B
