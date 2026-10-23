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

print(n..' standalone Astrolux payment checks passed')
