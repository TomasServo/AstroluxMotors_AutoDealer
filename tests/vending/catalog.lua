package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;'..package.path
local C=require 'TSBAstroluxVend/Config'
local V=require 'TSBAstroluxVend/VehicleCatalog'
local expected={'SmallCar','SmallCar02','CarNormal','CarLuxury','ModernCar','ModernCar02','SportsCar',
    'CarStationWagon','CarStationWagon2','PickUpTruck','PickUpVan','OffRoad','SUV','Van','VanSeats','StepVan'}
local scripts,byName={},{}
local function add(name,kind)
    local s={getFullName=function()return name end,getName=function()return name:match('%.(.+)$')end,
        getMechanicType=function()return kind or 1 end,getModel=function()return {}end,
        getExtents=function()return {x=function()return 2 end,z=function()return 5 end}end,
        getCenterOfMassOffset=function()return {x=function()return 0 end,z=function()return 0 end}end}
    scripts[#scripts+1]=s;byName[name]=s;return s
end
for _,name in ipairs(expected)do add('Base.'..name,name:find('Van') and 2 or 1)end
local forbidden={'Base.CarLightsPolice','Base.CarLightsRanger','Base.PickUpVanLightsPolice',
    'Base.PickUpTruckLightsFire','Base.PickUpVanLightsFire','Base.CarLightsLouisvilleCounty',
    'Base.StepVan_LouisvilleSWAT','Base.SmallCarSmashedFront','Base.VanBurnt','Base.KST',
    'TSBAstroluxVendPreview.Car','Mods.CivilianNamedScript'}
for _,name in ipairs(forbidden)do add(name)end
add('Mods.Firebird',3);add('Base.VanMail',2)
function getTextOrNull(key)if key=='IGUI_VehicleNameCivilianNamedScript' then return 'Fire Department Truck' end end
local manager={getAllVehicleScripts=function()return {size=function()return #scripts end,get=function(_,i)return scripts[i+1]end}end,
    getVehicle=function(_,name)return byName[name]end}
local catalog=V.new(manager,{})
assert(#catalog.offers==16 and catalog.rejected==0,'All standard native models must be purchasable without owner enablement')
for _,name in ipairs(expected)do
    local found
    for _,o in ipairs(catalog.offers)do if o.script=='Base.'..name then found=o end end
    assert(found,'Missing '..name);assert(catalog:resolve(found.id).script==found.script)
end
assert(catalog.byID.compact.script=='Base.SmallCar' and catalog.byID.sedan.script=='Base.CarNormal')
assert(catalog.byID.pickup.script=='Base.PickUpVan' and catalog.byID.offroad.script=='Base.OffRoad','Keep saved offer identities')
local rows,page,pages,total=catalog:page('Valuline',1);assert(total==2 and #rows==2)
local enabled={};for _,name in ipairs(forbidden)do enabled[name]=true end
enabled['Mods.Firebird']=true;enabled['Base.VanMail']=true
local changed=V.new(manager,{enabled=enabled,vehicles={['Base.Van']=12345}})
assert(changed.byID['Base.Van'].price==12345,'Keep existing owner price overrides')
assert(changed.byID['Mods.Firebird'] and changed.byID['Base.VanMail'],'Unrelated models and owner-enabled variants remain available')
for _,name in ipairs(forbidden)do
    assert(not changed.installable[name],'Excluded fleet/wreck must not be owner-enableable: '..name)
    assert(not pcall(function()changed:resolve(name)end),'Rejected offer must not be purchasable')
end
byName['Base.StepVan']=nil
for i=#scripts,1,-1 do if scripts[i]:getFullName()=='Base.StepVan' then table.remove(scripts,i)end end
assert(not V.new(manager,{}).byID['Base.StepVan'],'Absent scripts must not create phantom stock')
add('Base.StepVan',2)
local hilux=add('Base.88toyotaHiluxSC',2)
add('Base.88toyotaHiluxXC',2);add('Base.88toyotaHiluxXCS',2)
hilux.getExtents=function()return {x=function()return 1.6889 end,z=function()return 4.5556 end}end
hilux.getCenterOfMassOffset=function()return {x=function()return 0 end,z=function()return -0.1889 end}end
local modded=V.new(manager,{})
local truck=modded:resolve('Base.88toyotaHiluxSC')
assert(#modded.offers==17 and truck.script=='Base.88toyotaHiluxSC' and truck.price==6000)
assert(truck.rx==1 and truck.ry==3,'Modded vehicle uses a three-tile-wide native footprint')
assert(not modded.byID['Base.88toyotaHiluxXC'] and not modded.byID['Base.88toyotaHiluxXCS'],'Only one Hilux variant is enabled by default')
local search,_,_,count=modded:page('Hilux',1);assert(count==1 and search[1].id==truck.id)
assert(V.new(manager,{vehicles={['Base.88toyotaHiluxSC']=22000}}):resolve(truck.id).price==22000)
print('PASS: 16 native base models, both vans, saved offer IDs, owner prices, missing scripts and police/fire exclusions')
print('PASS: optional Hilux single cab discovery, native fit, heavy-duty pricing, search and owner override')
