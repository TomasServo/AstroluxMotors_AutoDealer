package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
package.loaded['TSBAstroluxVend/DeliveryBorder']={safeRefresh=function()end}
package.loaded['TSBAstroluxVend/Equipment']={offer=function(o)return o end,options=function()return {}end,list=function()return {}end,issues=function()return {}end}
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
ModData={getOrCreate=function(key) assert(key=='TSBAstroluxVend.State.v1');return db end}
local fixtureData={TSBAstroluxVend='one'}
local fixture={getModData=function() return fixtureData end,transmitModData=function() end,getSprite=function() return {getName=function() return 'TSBAstroluxKiosk_0' end} end}
local sq={getObjects=function() return {size=function() return 1 end,get=function() return fixture end} end}
function getCell() return {getVehicles=function()return {iterator=function()return {hasNext=function()return false end}end}end,getGridSquare=function(_,x,y,z) assert(x==10 and y==20 and z==0);return sq end} end
function getScriptManager() return {getVehicle=function() return {getFullName=function()return "Base.CarNormal"end,getPartCount=function()return 0 end} end} end
package.loaded['TSBAstroluxVend/VehicleCatalog']={new=function()
    local offer={id='sedan',script='Base.CarNormal',price=4000}
    return {offers={offer},byID={sedan=offer},installedScripts={},
        paintVariants=function()return {}end,configurations=function()return {}end,page=function() return {offer},1,1,1 end,variant=function()return offer end,resolve=function() return offer end}
end}
package.loaded['TSBAstroluxVend/Paint']={select=function()return {}end,attach=function(o)return o end,options=function() return {} end,offer=function(o) return o end}
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
S.handle(p,'quote',args);assert(reply.ok and reply.quote,reply.message)
args.token=reply.quote.token;S.handle(p,'buy',args)
assert(reply.ok and reply.order.status=='queued' and reply.balance==10000 and spawns==0)
assert(db.payments.alice==nil)
package.loaded['TSBAstroluxVend/Server']=nil
S=require 'TSBAstroluxVend/Server'
callbacks.OnInitGlobalModData()
assert(db.orders.alice.status=='queued','Restart must retain a known unattempted delivery')
online=false;ready=true;S.deliverQueued();assert(spawns==0)
online=true;S.deliverQueued();assert(spawns==1 and db.orders.alice.status=='delivered' and db.orders.alice.keyIssued)
S.deliverQueued();assert(spawns==1)
S.handle(p,'open',args);assert(reply.balance==6000)
-- A queued order with an uncertain payment must not spawn after reconnection.
ready=false;S.handle(p,'quote',args);args.token=reply.quote.token;S.handle(p,'buy',args)
assert(db.orders.alice.status=='queued' and reply.balance==6000)
db.orders.alice.paymentTiming=nil;db.payments.alice.status='hold';ready=true;S.deliverQueued()
assert(db.orders.alice.status=='hold' and spawns==1)
print('PASS: kiosk quote/cash purchase queues remotely, survives reload, waits for buyer, delivers once, rejects uncertain receipt')
