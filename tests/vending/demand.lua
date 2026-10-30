package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local base='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
assert(loadfile(base..'client/TSBAstroluxVend/AdminPricing.lua'));assert(loadfile(base..'server/TSBAstroluxVend/Server.lua'))
local installed='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/TSBAstroluxVend/'
package.loaded['TSBAstroluxVend/Amount']=dofile(installed..'Amount.lua')
package.loaded['TSBAstroluxVend/Config']={demandFamilies={},catalog={},vehicleClasses={{price=4000},{price=6000},{price=8000}},camperTopPrice=500,specialPaintPrice=500}
local D=dofile(base..'shared/TSBAstroluxVend/Demand.lua');package.loaded['TSBAstroluxVend/Demand']=D
local offer={script='Base.CarStationWagon',price=4000}
local db={};assert(D.policy().increase==2 and D.policy().recovery==2)
local order={script=offer.script,status='delivered'};assert(D.completed(db,order,0));assert(D.offer(db,offer,0).price==4080,'legacy default retained')
assert(not D.completed(db,order,0),'count delivered order once')
db={pricing={demandIncrease=.25,demandRecovery=.25}}
assert(D.completed(db,{script=offer.script,status='delivered'},0));assert(D.offer(db,offer,0).price==4010,'quarter-percent increase is ten dollars')
assert(D.offer(db,offer,24).price==4000,'daily recovery')
assert(D.offer(db,offer,1000).price==4000,'never below base')
db={vehicleDemand={[offer.script]={points=2,hours=0,revision=1}},pricing={demandIncrease=.25,demandRecovery=2}}
D.settle(db,12);assert(db.vehicleDemand[offer.script].points==1 and db.vehicleDemand[offer.script].hours==12)
db.pricing.demandRecovery=.25;local points=D.state(db,offer.script,24);assert(points==.875,'new rate only applies after policy switch')
local before=db.vehicleDemand[offer.script].hours;D.settle(db,4);assert(db.vehicleDemand[offer.script].hours==before,'clock rewind does not rewind settlement')
db.pricing.dynamic=false;assert(D.offer(db,offer,24).price==4000 and not D.completed(db,{script=offer.script,status='delivered'},24))
assert(not D.completed({}, {script=offer.script,status='paid'},0),'uncompleted purchase does not affect demand')
db={pricing={demandIncrease=0,demandRecovery=0}};assert(D.completed(db,{script=offer.script,status='delivered'},0));assert(D.offer(db,offer,0).price==4000)
db.vehicleDemand[offer.script].points=1000;assert(D.offer(db,offer,0).price==44000,'no total demand ceiling')
for _,bad in ipairs({-1,math.huge,'0.25',0/0})do assert(not pcall(D.policy,{demandIncrease=bad,demandRecovery=2}))end
package.loaded['TSBAstroluxVend/Equipment']={}
package.loaded['TSBAstroluxVend/VehicleFamilies']={target=function()end}
package.loaded['TSBAstroluxVend/AdminVehicleGroups']={}
local Admin=dofile(base..'server/TSBAstroluxVend/PriceAdmin.lua')
local result=Admin.edit({}, {revision=0,action='demand',demandIncrease=.25,demandRecovery=.5},{})
assert(result.revision==1 and result.demandIncrease==.25 and result.demandRecovery==.5)
assert(not pcall(Admin.edit,result,{revision=0,action='demand',demandIncrease=.25,demandRecovery=.5},{}),'stale edit rejected')
assert(not pcall(Admin.edit,{}, {revision=0,action='demand',demandIncrease=.25},{}),'missing rate rejected')
print('PASS demand controls: legacy compatibility, fractional increase/recovery, ten-dollar example, old-rate settlement, no below-base/upper cap, clock rewind, static/zero, single delivery counting, invalid/stale edits and Lua syntax')
