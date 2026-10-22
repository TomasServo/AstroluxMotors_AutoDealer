local root='mods/PZ_TSB_AstroluxStructure'
package.path=root..'/42/media/lua/shared/?.lua;'..root..'/42/media/lua/server/?.lua;'..package.path
local F=dofile('tests/vending/cash-fixture.lua')
local Cash=require 'TSBAstroluxVend/Cash'
local D=require 'TSBAstroluxVend/Domain'
local n=0
local function test(name,fn)fn();n=n+1;print('PASS '..name)end
local function rejects(fn,pattern)local ok,e=pcall(fn);assert(not ok and tostring(e):find(pattern,1,true),tostring(e))end
local function setup(bundles,bills)
 local db={};local a=F.adapter();local p=F.player('alice',bundles or 100,bills or 0)
 return Cash.new(db,a),db,p,a
end
test('loose cash and replay',function()
 local c,db,p=setup(0,10);c:charge(p,7,'a',function()end);assert(c:balance(p)==3)
 rejects(function()c:charge(p,7,'a',function()end)end,'already committed');assert(#db.cashAudit==1)
end)
test('bundle value, change and nested inventory',function()
 local c,db,p=setup(0);local bag=F.item('Base.Bag');bag.bag=true;bag.inventory=F.container();p.inventory:AddItem(bag)
 bag.inventory:AddItem(F.item('Base.MoneyBundle'));c:charge(p,63,'a',function()end)
 assert(c:balance(p)==37 and #bag.inventory.items==0 and db.cashAudit[1].change==37)
end)
test('favorite and equipped currency excluded',function()
 local c,db,p=setup(2,5);p.inventory.items[1].favorite=true;p.inventory.items[2].equipped=true
 assert(c:balance(p)==5);rejects(function()c:charge(p,6,'a',function()end)end,'Insufficient');assert(not db.payments.alice)
end)
test('callback failure restores exact objects and order',function()
 local c,db,p=setup(1);local original=p.inventory.items[1]
 rejects(function()c:charge(p,63,'a',function(tx)tx:set(db,'order',{});error('abort')end)end,'cash restored')
 assert(c:balance(p)==100 and #p.inventory.items==1 and p.inventory.items[1]==original and not db.order)
end)
test('native removal and change failures restore cash',function()
 for _,kind in ipairs({'remove','change'})do
  local c,db,p,a=setup(1)
  if kind=='remove'then p.inventory.failRemove=true else a.createMoney=function()error('change failure')end end
  rejects(function()c:charge(p,63,'a',function()end)end,'cash restored')
  assert(c:balance(p)==100 and db.payments.alice.status=='failed')
 end
end)
test('uncertain rollback and interrupted payments remain held',function()
 local c,db,p,a=setup(1);a.createMoney=function()p.inventory.failAdd=true;error('failure')end
 rejects(function()c:charge(p,63,'a',function()end)end,'inspection');assert(db.payments.alice.status=='hold')
 c=Cash.new(db,a);rejects(function()c:charge(p,1,'b',function()end)end,'on hold')
 db.payments.alice.status='processing';c=Cash.new(db,a);assert(db.payments.alice.status=='hold')
end)
test('notification failure cannot repeat committed payment',function()
 local c,db,p,a=setup(2);a.notify=function()error('network failure')end
 c:charge(p,100,'a',function()end);assert(c:balance(p)==100 and db.payments.alice.syncWarning)
 rejects(function()c:charge(p,100,'a',function()end)end,'already committed')
end)
local function domain()
 local c,db,p,a=setup();local env={clock=10,spawns=0};local t={id='one'};local offer={id='sedan',script='Base.CarNormal',price=4000}
 local s=D.new(db,{now=function()return env.clock end,clear=function()if env.block then error('blocked')end end,
 charge=function(actor,amount,key,apply)assert(actor=='alice');return c:charge(p,amount,key,apply)end,
 spawn=function()env.spawns=env.spawns+1;if env.failSpawn then error('spawn failure')end end})
 return s,c,db,p,env,t,offer
end
test('standalone purchase debits once and delivers once',function()
 local s,c,db,p,e,t,o=domain();local q=s:quote('alice',t,o);s:buy('alice',q.token,t,o)
 assert(c:balance(p)==6000 and e.spawns==1 and db.orders.alice.payment=='vanillaCash')
 rejects(function()s:buy('alice',q.token,t,o)end,'Quote expired');assert(e.spawns==1)
end)
test('expired, foreign and changed quotes cannot debit',function()
 for _,kind in ipairs({'expired','foreign','price','script','terminal'})do
  local s,c,db,p,e,t,o=domain();local q=s:quote('alice',t,o);local actor='alice'
  if kind=='expired'then e.clock=71 elseif kind=='foreign'then actor='bob' elseif kind=='price'then o.price=1 elseif kind=='script'then o.script='Other.Car' else t={id='other'}end
  rejects(function()s:buy(actor,q.token,t,o)end,'Quote expired');assert(c:balance(p)==10000 and e.spawns==0)
 end
end)
test('blocked bay and insufficient funds never spawn',function()
 local s,c,db,p,e,t,o=domain();local q=s:quote('alice',t,o);e.block=true
 rejects(function()s:buy('alice',q.token,t,o)end,'blocked');assert(c:balance(p)==10000)
 e.block=false;p.inventory=F.container();q=s:quote('alice',t,o)
 rejects(function()s:buy('alice',q.token,t,o)end,'Insufficient');assert(e.spawns==0 and not db.orders.alice)
end)
test('uncertain spawn holds paid order without refund or second spawn',function()
 local s,c,db,p,e,t,o=domain();local q=s:quote('alice',t,o);e.failSpawn=true
 rejects(function()s:buy('alice',q.token,t,o)end,'inspection');assert(c:balance(p)==6000 and db.orders.alice.status=='hold')
 rejects(function()s:deliver('alice',t)end,'hold');assert(e.spawns==1)
end)
assert(not SpacebarEconomyServer and not package.loaded['SpacebarEconomy/Engine'])
test('remote purchase queues once and resumes without second debit',function()
 local c,db,p=setup();local ready=false;local spawns=0;local t={id='remote'}
 local offer={id='sedan',script='Base.CarNormal',price=4000}
 local adapter={now=function()return 1 end,
 clear=function(terminal,own)
  if own and not ready then error('waiting for remote area')end
  return {x=100000,y=200000,rx=2,ry=3,heading='N',deferred=not ready}
 end,
 charge=function(actor,amount,key,apply)return c:charge(p,amount,key,apply)end,
 spawn=function()spawns=spawns+1 end}
 local s=D.new(db,adapter);local q=s:quote('alice',t,offer)
 local order=s:buy('alice',q.token,t,offer)
 assert(order.status=='queued'and c:balance(p)==6000 and spawns==0)
 rejects(function()s:quote('alice',t,offer)end,'existing order')
 s=D.new(db,adapter) -- reload safely retains known unattempted queue
 rejects(function()s:deliver('alice',t)end,'waiting');assert(order.status=='queued' and spawns==0)
 ready=true;s:deliver('alice',t)
 assert(order.status=='delivered' and spawns==1 and c:balance(p)==6000)
 rejects(function()s:deliver('alice',t)end,'already delivered');assert(spawns==1)
end)
test('uncertain queued dispatch becomes a non-replayable hold',function()
 local c,db,p=setup();local loaded=false;local attempts=0;local t={id='remote'};local offer={id='car',script='Base.CarNormal',price=4000}
 local s=D.new(db,{now=function()return 1 end,
 clear=function(_,own)if own and not loaded then error('waiting')end;return {deferred=not loaded}end,
 charge=function(_,amount,key,apply)return c:charge(p,amount,key,apply)end,
 spawn=function(order)attempts=attempts+1;order.vehicleId=77;error('injected key failure')end})
 local q=s:quote('alice',t,offer);s:buy('alice',q.token,t,offer);loaded=true
 rejects(function()s:deliver('alice',t)end,'inspection')
 assert(db.orders.alice.status=='hold' and db.orders.alice.vehicleId==77 and attempts==1)
 rejects(function()s:deliver('alice',t)end,'hold');assert(attempts==1 and c:balance(p)==6000)
end)
print(n..' standalone Astrolux payment checks passed')
