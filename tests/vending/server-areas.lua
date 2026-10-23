package.loaded['TSBAstroluxVend/DeliveryBorder']={safeRefresh=function()end}
function getOnlinePlayers()return {size=function()return 0 end}end
package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local callbacks={}
Events=setmetatable({},{__index=function(t,k) local e={Add=function(fn) callbacks[k]=fn end};t[k]=e;return e end})
function isClient() return false end
function isServer() return true end
local now=1000
function getTimestampMs() now=now+1000;return now end
function getTimestamp() return now end
local reply
function sendServerCommand(p,module,command,data) reply=data end
local db={terminals={one={id='one',x=100,y=200,z=0,sprite='TSBAstroluxKiosk_0'}},orders={}}
ModData={getOrCreate=function(key) assert(key=='TSBAstroluxVend.State.v1');return db end}
package.loaded['TSBAstroluxVend/Cash']={new=function() return {} end}
package.loaded['TSBAstroluxVend/BankPayments']={new=function() return {} end}
local service={quotes={alice={token='old'}}}
package.loaded['TSBAstroluxVend/Domain']={new=function() return service end}
-- Configuring remote areas must not request or modify their physical tiles.
function getCell() error('Area configuration must not require loaded tiles') end
local S=require 'TSBAstroluxVend/Server'
local p={getUsername=function() return 'alice' end,isDead=function() return false end,getAccessLevel=function() return 'admin' end}
local args={terminal='one',ax=-50000,ay=-60000,bx=1000000,by=2000000,heading='E',confirmed=true}
S.handle(p,'areaSet',args)
if reply and not reply.ok then print(reply.message)end
assert(reply.ok and reply.areaSaved and db.terminals.one.spawnArea.x2==1000000)
assert(db.terminals.one.spawnArea.heading=='E' and not next(service.quotes))
local original=db.terminals.one.spawnArea
db.orders.bob={terminal='one',status='paid'}
S.handle(p,'areaSet',args);assert(not reply.ok and db.terminals.one.spawnArea==original)
db.orders.bob=nil
local user={getUsername=function() return 'user' end,isDead=function() return false end,getAccessLevel=function() return 'None' end}
S.handle(user,'areaSet',args);assert(not reply.ok and db.terminals.one.spawnArea==original)
args.heading='NNW';S.handle(p,'areaSet',args);assert(not reply.ok and db.terminals.one.spawnArea==original)
print('PASS: server remote/huge area configuration without streaming or proximity, admin authorization, quote invalidation and paid-order protection')
