package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
package.loaded['TSBAstroluxVend/DeliveryBorder']={safeRefresh=function()end}
package.loaded['TSBAstroluxVend/Equipment']={selection=function()return {}end,parts=function()return {}end,offer=function(o)return o end,options=function()return {}end,list=function()return {}end,issues=function()return {}end}
local F=dofile('tests/vending/cash-fixture.lua')
local p=F.player('alice',100,0);local now=1000;local ready=false;local online=true;local spawns=0
function p:getAccessLevel()return 'admin'end
function p:getX() return 10 end
function p:getY() return 20 end
function p:getZ() return 0 end
function p:Say(message) self.message=message end
function isClient() return false end
function isServer() return false end
function getTimestampMs() now=now+1000;return now end
function getTimestamp() return math.floor(now/1000) end
function instanceItem(kind) return F.item(kind) end
function getGameTime() return {getWorldAgeHours=function() return 1 end} end
function getNumActivePlayers() return online and 1 or 0 end
function getSpecificPlayer() return online and p or nil end
local callbacks={}
Events=setmetatable({},{__index=function(t,k) local e={Add=function(fn) callbacks[k]=fn end};t[k]=e;return e end})
local db={terminals={one={id='one',x=10,y=20,z=0,sprite='TSBAstroluxKiosk_0'}},orders={}}
local stores={['TSBAstroluxVend.State.v1']=db};ModData={getOrCreate=function(key)stores[key]=stores[key]or {};return stores[key]end}
local fixtureData={TSBAstroluxVend='one'}
local fixture={getModData=function() return fixtureData end,transmitModData=function() end,getSprite=function() return {getName=function() return 'TSBAstroluxKiosk_0' end} end}
local powered=true
local sq={getFloor=function()return nil end,haveElectricity=function()return powered end,hasGridPower=function()return false end,getObjects=function() return {size=function() return 1 end,get=function() return fixture end} end}
function getCell() return {getVehicles=function()return {iterator=function()return {hasNext=function()return false end}end}end,getGridSquare=function(_,x,y,z) assert(x==10 and y==20 and z==0);return sq end} end
function getScriptManager() return {getVehicle=function() return {getFullName=function()return "Base.CarNormal"end,getPartCount=function()return 0 end} end} end
package.loaded['TSBAstroluxVend/VehicleCatalog']={new=function()
    local offer={id='sedan',script='Base.CarNormal',price=4000}
    return {offers={offer},byID={sedan=offer},installedScripts={},
        paintVariants=function()return {}end,configurations=function()return {}end,page=function() return {offer},1,1,1 end,variant=function()return offer end,resolve=function() return offer end}
end}
package.loaded['TSBAstroluxVend/Paint']={verify=function()return true end,select=function()return {}end,attach=function(o)return o end,options=function() return {} end,offer=function(o) return o end}
package.loaded['TSBAstroluxVend/Demand']={completed=function() end,policy=function()return {increase=2,recovery=2}end}
package.loaded['TSBAstroluxVend/VehicleSpawn']={
    regions=function()return {}end,choose=function(_,t,own)
        assert(t.spawnArea.x1==100000,'Remote area must remain independent of kiosk coordinates')
        if own and not ready then error('waiting for loaded area') end
        return {x=100002,y=200003,rx=2,ry=3,heading='E',areaRevision=1,deferred=not ready}
    end,
    create=function(order,buyer) assert(ready and buyer==p);spawns=spawns+1;order.vehicleId=100+spawns;order.keyIssued=true end}
local reply
TSBAstroluxVendClient={receive=function(data) reply=data end}
local S=require 'TSBAstroluxVend/Server'
S.handle(p,'areaSet',{terminal='one',ax=100000,ay=200000,bx=100020,by=200030,heading='E',confirmed=true})
assert(reply.ok,reply.message)
local args={x=10,y=20,z=0,z=0,index=0,offer='sedan',payment='cash'}
local nativeError=error;local raised=0
error=function(...) raised=raised+1;return nativeError(...) end
S.handle(p,'open',args)
error=nativeError
assert(raised==0,'Absent optional bank must not raise even a caught error when opening sales')
assert(reply.ok and reply.balance==10000,reply.message)
assert(reply.bankAvailable==false and #reply.paymentMethods==1 and reply.paymentMethods[1]=='cash')
SpacebarEconomyServer={autoVendBridgeVersion=1,serviceBalance=function()return 777 end,chargeService=function()end}
S.handle(p,'open',args);assert(reply.bankAvailable and reply.bankBalance==777 and #reply.paymentMethods==2)
SpacebarEconomyServer=nil
-- Unloaded zones are rejected; new purchases are never left in an unpaid queue.
S.handle(p,'quote',args);assert(not reply.quote and not db.orders.alice and spawns==0)
ready=true;S.handle(p,'quote',args);assert(reply.ok and reply.quote,reply.message)
args.token=reply.quote.token;powered=false;S.handle(p,'buy',args)
assert(not db.orders.alice and spawns==0 and reply.balance==10000,'Power loss prevents side effects')
powered=true;S.handle(p,'quote',args);assert(reply.quote,reply.message)
args.token=reply.quote.token;S.handle(p,'buy',args)
assert(reply.ok and db.orders.alice.status=='delivered' and reply.balance==6000 and spawns==1,reply.message)
assert(db.orders.alice.keyIssued and db.payments.alice.status=='committed')
S.handle(p,'buy',args);assert(spawns==1,'Consumed quote cannot create a second vehicle')
package.loaded['TSBAstroluxVend/Server']=nil
S=require 'TSBAstroluxVend/Server';callbacks.OnInitGlobalModData()
online=false;S.deliverQueued();online=true;S.deliverQueued();assert(spawns==1,'Restart/reconnection never replay delivery')
S.handle(p,'open',args);assert(reply.balance==6000)
-- Legacy queued orders are not silently dispatched by the tick worker.
db.orders.alice={id='legacy',terminal='one',status='queued',price=4000,paymentTiming='onDelivery'}
S.deliverQueued();assert(spawns==1 and db.orders.alice.status=='queued')
S.handle(p,'deliver',args);assert(spawns==1 and reply.balance==6000,'No automatic delivery of old unpaid orders')
print('PASS: kiosk quote/cash purchase validates remote zone and power, delivers immediately once, preserves balance through reload, never auto-dispatches legacy orders')
