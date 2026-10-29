package.loaded['TSBAstroluxVend/AppraisalProfiles']={resolve=function()return {}end}
local base='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
local installed='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
package.loaded['TSBAstroluxVend/Amount']=dofile(installed..'shared/TSBAstroluxVend/Amount.lua')
package.loaded['TSBAstroluxVend/Config']={tradeInRate=.5}
package.loaded['TSBAstroluxVend/SpawnAreas']={}
package.loaded['TSBAstroluxVend/Appraisal']={calculate=function(v,price)
 return {amount=v.cash,retail=price,maximum=price/2,fingerprint=tostring(v.condition),parts={{id='Engine',condition=100,missing=false,value=v.cash/2,maximum=price/4},{id='Tire',condition=100,missing=false,value=v.cash/2,maximum=price/4}}}
end}
local Trade=dofile(installed..'server/TSBAstroluxVend/TradeIn.lua')
Trade.inArea=function(_,v)return v.inside and not v.removed end
package.loaded['TSBAstroluxVend/TradeIn']=Trade
local B=dofile(base..'server/TSBAstroluxVend/TradeBatch.lua')
local terminal={id='kiosk',spawnArea={}}
local cars
function getCell()return {getVehicles=function()return {iterator=function()local i=0;return {hasNext=function()return i<#cars end,next=function()i=i+1;return cars[i]end}end}end}end
local function vehicle(id,cash)
 local v={id=id,cash=cash,condition=100,inside=true,data={}}
 function v:getId()return self.id end
 function v:getScript()return {getFullName=function()return 'Base.Cerise'..id end,getName=function()return 'Cerise'..id end}end
 function v:getX()return 10 end;function v:getY()return 20 end
 function v:getModData()return self.data end
 function v:isRemovedFromWorld()return self.removed or false end
 function v:isEngineRunning()return self.engine or false end
 function v:hasPassenger()return false end
 function v:getVehicleTowing()end;function v:getTowingPartner()end;function v:getAnimals()end
 function v:getPartCount()return 0 end
 function v:transmitModData()end
 function v:permanentlyRemove()if self.failRemove then error('native removal failure')end;self.removed=true end
 return v
end
local function setup()
 cars={vehicle(1,100),vehicle(2,200)}
 local db={pricing={buybacksEnabled=true,requireBuybackKey=false}}
 local inventory={items={},capacity=100}
 function inventory:getCapacityWeight()return #self.items end
 function inventory:getEffectiveCapacity()return self.capacity end
 function inventory:AddItem(item)
  if self.failAt and #self.items+1==self.failAt then return nil end
  self.items[#self.items+1]=item;item.container=self;return item
 end
 local player={getUsername=function()return 'Buyer'end,getInventory=function()return inventory end}
 local adapter={time=0}
 function adapter.now()return adapter.time end
 function adapter.create(kind)
  if adapter.failCreate then return nil end
  local md={};return {getModData=function()return md end,kind=kind,getActualWeight=function()return 1 end,getContainer=function(s)return s.container end}
 end
 function adapter.notify()end
 local function retail(v)return v.price or v.cash*2 end
 return B.new(db,adapter),db,player,inventory,adapter,retail
end
local s,db,p,inv,adapter,retail=setup()
local list=s:list(p,terminal,retail);assert(#list==2 and list[1].amount==100 and list[2].amount==200)
local q=s:quote(p,terminal,B.resolve(terminal,{1,2}),retail,0)
assert(q.amount==300 and #q.vehicles==2 and q.vehicles[1].amount==100 and q.vehicles[2].amount==200)
cars[#cars+1]=vehicle(3,300)
local amount,count=s:accept(p,terminal,q.token,retail,0)
assert(amount==300 and count==2 and cars[1].removed and cars[2].removed and not cars[3].removed,'quote snapshot excludes later arrivals')
assert(db.tradeIns.Buyer.status=='paid' and #db.tradeIns.Buyer.vehicles==2 and #inv.items==3)
assert(not pcall(s.accept,s,p,terminal,q.token,retail,0),'duplicate accept rejected')
for _,mode in ipairs({'moved','engine','condition','price','expired','revision','capacity','create'})do
 s,db,p,inv,adapter,retail=setup();q=s:quote(p,terminal,B.resolve(terminal,{1,2}),retail,0)
 local revision=0
 if mode=='moved'then cars[2].inside=false elseif mode=='engine'then cars[2].engine=true elseif mode=='condition'then cars[2].condition=90 elseif mode=='price'then cars[2].price=999
 elseif mode=='expired'then adapter.time=61 elseif mode=='revision'then revision=1 elseif mode=='capacity'then inv.capacity=2 elseif mode=='create'then adapter.failCreate=true end
 local ok,result,reason=pcall(s.accept,s,p,terminal,q.token,retail,revision)
 if mode=='capacity'then assert(ok and result==nil and reason:find('capacity'),mode)else assert(not ok,mode)end
 assert(not cars[1].removed and not cars[2].removed and #inv.items==0,mode..' must fail before any removal/payment')
end
s,db,p,inv,adapter,retail=setup();q=s:quote(p,terminal,cars,retail,0);cars[2].failRemove=true
assert(not pcall(s.accept,s,p,terminal,q.token,retail,0))
assert(db.tradeIns.Buyer.status=='hold' and db.tradeIns.Buyer.vehicles[1].removed and not db.tradeIns.Buyer.vehicles[2].removed and db.tradeIns.Buyer.paidItems==0)
assert(not pcall(s.quote,s,p,terminal,{cars[2]},retail,0),'hold blocks retry')
s,db,p,inv,adapter,retail=setup();q=s:quote(p,terminal,cars,retail,0);inv.failAt=2
assert(not pcall(s.accept,s,p,terminal,q.token,retail,0))
assert(db.tradeIns.Buyer.status=='hold' and db.tradeIns.Buyer.removed and db.tradeIns.Buyer.paidItems==1,'partial payout is recorded')
s,db,p,inv,adapter,retail=setup();db.tradeIns.Buyer={status='processing'};B.new(db,adapter);assert(db.tradeIns.Buyer.status=='hold')
s,db,p,inv,adapter,retail=setup()
assert(not pcall(B.resolve,terminal,{1,1})and not pcall(B.resolve,terminal,{99})and not pcall(B.resolve,terminal,{}))
cars[2].engine=true;list=s:list(p,terminal,retail);assert(list[1].eligible and not list[2].eligible and list[2].reason)
db.pricing.buybacksEnabled=false;assert(not s:list(p,terminal,retail)[1].eligible)
print('PASS server batch: itemized totals; explicit ID snapshot; new arrivals excluded; replay/move/engine/condition/price/expiry/revision/capacity/create rejection before removal; interruption holds and paid-item accounting; disabled/ineligible listing')
-- Exercise selector state and event routing independently of the native renderer.
for _,name in ipairs({'ISUI/ISScrollingListBox','ISUI/ISTickBox'})do package.preload[name]=function()return {}end end
local function widget()
 local w={items={},selected=0}
 function w:setBackgroundRGBA()end;function w:setBackgroundColorMouseOverRGBA()end;function w:setBorderRGBA()end
 function w:initialise()end;function w:instantiate()end
 function w:addOption()end
 function w:setSelected(_,v)self.checked=v end;function w:isSelected()return self.checked end
 function w:setEnable(v)self.enabled=v end
 function w:clear()self.items={}end
 function w:addItem(text,item)self.items[#self.items+1]={text=text,item=item}end
 function w:rowAt()return 1 end
 return w
end
ISScrollingListBox={new=function()return widget()end}
ISTickBox={new=function(_,x,y,w,h,name,target,callback)local o=widget();o.callback=callback;return o end}
local UI=dofile(base..'client/TSBAstroluxVend/TradeSelection.lua')
local panel={showTab=function()end};local requests={}
UI.create(panel,function(_,w)return w end,function(_,x,y,w,label,callback)local o=widget();o.callback=callback;return o end,function(_,cmd)requests[#requests+1]=cmd end)
local rows={{id=1,label='Cerise',script='Base.CarStationWagon',eligible=true,amount=100},{id=2,label='Cerise wood',script='Base.CarStationWagon2',eligible=true,amount=200},{id=3,label='Blocked',eligible=false,reason='Engine running'}}
UI.receive(panel,{tradeInsEnabled=true,tradeVehicles=rows})
assert(#UI.ids(panel)==0 and not panel.tradeAll:isSelected(1)and not panel.tradeAccept.enabled and not panel.tradeAppraise.enabled,'no default selection')
panel.tradeAll:setSelected(1,true);panel.tradeAll.callback(panel)
assert(#UI.ids(panel)==2 and #requests==0 and panel.tradeAppraise.enabled,'all selects eligible only and does not sell')
panel.tradeAppraise.callback(panel);assert(requests[1]=='tradeQuote')
UI.receive(panel,{tradeInsEnabled=true,tradeVehicles=rows,tradeQuote=q})
assert(#panel.tradeRows.items==6 and panel.tradeAccept.enabled,'separate vehicle totals and part detail')
UI.receive(panel,{tradeInsEnabled=true,tradeVehicles=rows});assert(#UI.ids(panel)==0 and not panel.tradeAll:isSelected(1),'refresh resets all selections')
panel.tradeVehicleList:onMouseDown(1,1);assert(#UI.ids(panel)==1 and UI.ids(panel)[1]==1)
panel.tradeVehicleList:onMouseDown(1,1);assert(#UI.ids(panel)==0)
print('PASS selector: nothing preselected; Trade In All selects only eligible cars without trading; appraisal routing; per-car/part itemization; refresh reset; individual toggle')
