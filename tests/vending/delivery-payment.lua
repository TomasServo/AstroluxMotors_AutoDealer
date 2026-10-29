local staged='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
local live=staged
package.path=staged..'shared/?.lua;'..staged..'server/?.lua;'..live..'shared/?.lua;'..live..'server/?.lua;'..package.path
local F=dofile('tests/vending/cash-fixture.lua')
local Cash=require 'TSBAstroluxVend/Cash'
local Bank=require 'TSBAstroluxVend/BankPayments'
local Domain=require 'TSBAstroluxVend/Domain'
local terminal={id='kiosk'}
local offer={id='car',script='Base.Van',price=63}
local function rejects(fn)local ok,e=pcall(fn);assert(not ok,'expected rejection');return tostring(e)end
local function setup()
 local db={};local p=F.player('alice',1,0);local cash=Cash.new(db,F.adapter())
 local bank=Bank.new(db,cash,function()return true end)
 local env={ready=true,spawns=0,charged=0}
 local a={requireFunds=function(_,amount,method)
 if method=='cash'then return cash:balance(p)>=amount,'Insufficient cash'end
 return SpacebarEconomyServer.serviceBalance()>=amount,'Insufficient bank funds'
 end,now=function()return 10 end,clear=function()return {deferred=not env.ready}end,
  charge=function(actor,amount,receipt,apply,method,before)
   env.charged=env.charged+1;return bank:charge(p,amount,receipt,apply,method,before)
  end,
  authorizeDelivery=function(o)
   local attempts=o.payment=='serverBank' and db.bankPayments or db.payments
   assert(attempts.alice and attempts.alice.status=='committed')
  end,
  spawn=function(o)
   env.spawns=env.spawns+1
   if o.payment=='vanillaCash' and o.paymentTiming=='onDelivery'then assert(cash:balance(p)==100,'cash removed before physical creation')end
   o.vehicleId=123
   if env.failSpawn then error('native spawn/key failure')end
   o.keyIssued=true
  end}
 local service=Domain.new(db,a)
 local function buy(method)
  local q=service:quote('alice',terminal,offer,method)
  return service:buy('alice',q.token,terminal,offer,method)
 end
 return db,p,cash,env,service,buy,a
end
do
 local db,p,c,e,s,buy=setup();local o=buy()
 assert(o.status=='delivered' and o.vehicleId==123 and o.keyIssued and o.paymentCommitted and c:balance(p)==37)
 rejects(function()s:deliver('alice',terminal)end);assert(e.spawns==1 and #db.cashAudit==1)
 print('PASS vehicle/key exist before cash removal; exact change, receipt and duplicate protection')
end
do
 local db,p,c,e,s,buy,a=setup();e.ready=false;rejects(buy)
 assert(not db.orders.alice and c:balance(p)==100 and e.spawns==0 and e.charged==0)
 e.ready=true;local q=s:quote('alice',terminal,offer);e.ready=false
 rejects(function()s:buy('alice',q.token,terminal,offer)end)
 assert(not db.orders.alice and e.spawns==0,'Zone revalidated after quote')
 e.ready=true;local o=buy();assert(o.status=='delivered' and c:balance(p)==37)
 print('PASS unloaded quote and changed zone rejected before effects; fresh quote succeeds')
end

do
 local db,p,c,e,s,buy=setup();p.inventory.items={}
 local result,why=buy();assert(not result and why and not db.orders.alice and e.spawns==0)
 p.inventory:AddItem(F.item('Base.MoneyBundle'));local o=buy()
 assert(o.status=='delivered' and e.spawns==1)
 print('PASS insufficient funds never create an order; replenishment requires fresh quote')
end

do
 local db,p,c,e,s,buy=setup();e.failSpawn=true;rejects(buy)
 assert(c:balance(p)==100 and db.orders.alice.status=='hold' and not db.orders.alice.paymentCommitted)
 rejects(function()s:deliver('alice',terminal)end);assert(e.spawns==1)
 print('PASS partial native failure takes no cash, held without respawn')
end
do
 local db,p,c,e,s,buy=setup();p.inventory.failRemove=true;rejects(buy)
 assert(c:balance(p)==100 and db.orders.alice.status=='hold' and db.orders.alice.vehicleId==123)
 rejects(function()s:deliver('alice',terminal)end);assert(e.spawns==1)
 print('PASS post-spawn debit failure preserves cash and holds vehicle/order for inspection')
end
do
 local db,p,c,e,s,buy=setup()
 db.orders.alice={id='old',actor='alice',terminal='kiosk',script='Base.Van',price=63,payment='vanillaCash',status='queued',placement={deferred=true}}
 db.payments.alice={status='committed',receipt='old'}
 s:deliver('alice',terminal);assert(db.orders.alice.status=='delivered' and e.charged==0 and c:balance(p)==100)
 print('PASS legacy prepaid queue never charged twice')
end
do
 local balance=100;local debits=0
 SpacebarEconomyServer={autoVendBridgeVersion=1,serviceBalance=function()return balance end,
  chargeService=function(actor,amount,receipt,apply)
   debits=debits+1;balance=balance-amount
   apply({set=function(_,obj,key,value)obj[key]=value end});return true
  end}
 local db,p,c,e,s,buy,a=setup();e.ready=false;rejects(function()buy('bank')end)
 assert(debits==0 and balance==100 and not db.orders.alice)
 a.spawn=function(order)assert(balance==37 and db.bankPayments.alice.status=='committed');order.vehicleId=123;e.spawns=e.spawns+1 end
 e.ready=true;local o=buy('bank')
 assert(debits==1 and e.spawns==1 and o.status=='delivered' and c:balance(p)==100)
 print('PASS unloaded bank purchase rejected unpaid; native spawn follows committed bank transaction')
end
assert(loadfile(staged..'server/TSBAstroluxVend/Server.lua'))
print('PASS all delivery-payment regression checks and server syntax')
