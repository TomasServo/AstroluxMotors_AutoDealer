package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local base='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
assert(loadfile(base..'server/TSBAstroluxVend/Server.lua'))
local installed='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/'
package.loaded['TSBAstroluxVend/Amount']=dofile(installed..'TSBAstroluxVend/Amount.lua')
package.loaded['TSBAstroluxVend/HotelPilot']={enabled=function()return false end}
package.loaded['TSBAstroluxVend/Config']={catalog={},vehicleOverrides={}}
package.loaded['TSBAstroluxVend/Pricing']={forScript=function(script,_,settings)return {total=(settings.prices or {})[script:getFullName()]or 20000}end}
package.loaded['TSBAstroluxVend/CatalogPolicy']={reason=function()end}
local Families=dofile(installed..'TSBAstroluxVend/VehicleFamilies.lua')
package.loaded['TSBAstroluxVend/VehicleFamilies']=Families
Families.members['Mod.WagonWood']={base='Mod.Wagon',kind='paint',label='Mod wood design'}
Families.members['Mod.WagonPassenger']={base='Mod.Wagon',kind='configuration',label='Passenger'}
local V=dofile(base..'shared/TSBAstroluxVend/VehicleCatalog.lua');V.measure=function()return 1,2 end
local names={'Base.CarStationWagon','Base.CarStationWagon2','Mod.Wagon','Mod.WagonWood','Mod.WagonPassenger','Mod.Other','Base.CarStationWagonSmashedRear'}
local scripts={};for _,name in ipairs(names)do
 scripts[#scripts+1]={getFullName=function()return name end,getName=function()return name:match('%.(.+)')end}
end
local manager={getAllVehicleScripts=function()return {size=function()return #scripts end,get=function(_,i)return scripts[i+1]end}end,getVehicle=function(_,name)for _,s in ipairs(scripts)do if s:getFullName()==name then return s end end end}
local settings={prices={['Base.CarStationWagon2']=24000,['Mod.WagonWood']=28000},accessories={['Mod.Wagon']={['configuration:Mod.WagonPassenger']={price=500,enabled=true}}}}
local function demand(offer)local r={};for k,v in pairs(offer)do r[k]=v end;r.price=r.price+100;return r end
local catalog=V.new(manager,settings,demand)
for _,row in ipairs(catalog.offers)do assert(row.script~='Base.CarStationWagon2','wood variant folded from visible rows')end
assert(catalog.byID['Base.CarStationWagon2'],'Exact variant IDs remain addressable')
local wood=catalog:tradeOffer('Base.CarStationWagon2');assert(wood and wood.script=='Base.CarStationWagon2'and wood.price==24100,'folded vanilla variant uses its own price')
assert(catalog:tradeOffer('Mod.WagonWood').price==28100,'folded mod variant generic')
assert(catalog:tradeOffer('Mod.Other').script=='Mod.Other' and catalog:tradeOffer('Mod.Other').price==20100,'direct native offer includes demand')
assert(catalog:tradeOffer('Mod.WagonPassenger').price==20600 and catalog.nativeOffers['Mod.WagonPassenger'].price==20000,'repeated lookups never compound demand or mutate base price')
assert(catalog:tradeOffer('Mod.WagonPassenger').price==20600,'configuration surcharge retained')
assert(not catalog:tradeOffer('Unknown.Car')and not catalog:tradeOffer('Base.CarStationWagonSmashedRear'))
settings.enabled={['Base.CarStationWagon2']=false};assert(not V.new(manager,settings):tradeOffer('Base.CarStationWagon2'),'owner disabled variant rejected')
settings.enabled={['Base.CarStationWagon']=false};assert(V.new(manager,settings):tradeOffer('Base.CarStationWagon2').price==24000,'variant remains valid when parent hidden')
settings.accessories['Mod.Wagon']['configuration:Mod.WagonPassenger'].enabled=false
assert(not pcall(function()V.new(manager,settings):tradeOffer('Mod.WagonPassenger')end),'disabled configuration rejected')
print('PASS generic trade catalog: vanilla wood variant, grouped mod variant, normal mod car, per-variant price/demand, config surcharge, hidden parent, disabled/unknown/wreck/config rejection; server Lua parses')
