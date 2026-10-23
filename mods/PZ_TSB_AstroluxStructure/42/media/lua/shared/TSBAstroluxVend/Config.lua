local C={channel='TSBAstroluxVend',version=1}
C.vehicleClasses={[1]={name='Normal',price=4000},[2]={name='Heavy Duty',price=6000},[3]={name='Sports',price=10000}}
C.sirenPrice=0 -- Legacy config retained for compatibility; sirens have no surcharge.
-- Hotel paint pilot: solid colors included; special existing skins cost extra.
C.camperTopCapacityBonus=46 -- Added to native bed capacity while the cap is installed.
C.camperTopPrice=500 -- Owner-configurable purchase extra.
C.specialPaintPrice=500
-- Optional server per-script/per-texture classification, label and surcharge.
-- C.paintJobs['Mod.Car']={['Vehicles/car_decal']={special=true,surcharge=900,label='Stripes'}}
C.paintJobs={}
-- Fraction of new retail value before per-part condition deductions.
C.tradeInRate=0.50
-- Remain disabled until explicit live-test approval.
C.tradeInsEnabled=true -- User-authorized test installation; saved admin policy overrides this.
-- Explicit families; unlisted scripts track demand independently.
C.demandFamilies={
    ['Base.88toyotaHiluxSC']='ToyotaHilux88',
    ['Base.88toyotaHiluxXC']='ToyotaHilux88',
    ['Base.88toyotaHiluxXCS']='ToyotaHilux88',
}
-- Included equipment only: {basePrice=5000,addons={{name='Armor package',price=2000}}}.
-- Class override: 1=Normal, 2=Heavy Duty, 3=Sports. price overrides the entire total.
-- Server-side per-script overrides, e.g. ['SomeMod.Bus']={price=12000,disabled=false}.
C.vehicleOverrides={}
C.pageSize=40
-- Vehicle fit is checked against the chosen area, with no fixed radius cap.
-- Standard vanilla models enabled by default; loaded scripts remain authoritative.
-- Preserve the four original offer IDs for saved quotes/orders and demand history.
-- Service/light-bar variants require explicit owner enablement; no default fleet sales.
C.catalog={
    {id='compact',script='Base.SmallCar',name='Chevalier Dart'},
    {id='sedan',script='Base.CarNormal',name='Chevalier Nyala'},
    {id='pickup',script='Base.PickUpVan',name='Dash Bulldriver'},
    {id='offroad',script='Base.OffRoad',name='Dash Rancher'},
    {id='Base.SmallCar02',script='Base.SmallCar02',name='Masterson Horizon'},
    {id='Base.CarLuxury',script='Base.CarLuxury',name='Mercia Lang 4000'},
    {id='Base.ModernCar',script='Base.ModernCar',name='Dash Elite'},
    {id='Base.ModernCar02',script='Base.ModernCar02',name='Chevalier Primani'},
    {id='Base.SportsCar',script='Base.SportsCar',name='Chevalier Cossette'},
    {id='Base.CarStationWagon',script='Base.CarStationWagon',name='Chevalier Cerise Wagon'},
    {id='Base.CarStationWagon2',script='Base.CarStationWagon2',name='Chevalier Cerise Wagon (wood panel)'},
    {id='Base.PickUpTruck',script='Base.PickUpTruck',name='Chevalier D6'},
    {id='Base.SUV',script='Base.SUV',name='Franklin All-Terrain'},
    {id='Base.Van',script='Base.Van',name='Franklin Valuline (cargo)'},
    {id='Base.VanSeats',script='Base.VanSeats',name='Franklin Valuline (passenger)'},
    {id='Base.StepVan',script='Base.StepVan',name='Chevalier Step Van'},
    -- Optional mod probe: offered only when KI5's Hilux scripts are loaded.
    {id='Base.88toyotaHiluxSC',script='Base.88toyotaHiluxSC',name="1988 Toyota Hilux (single cab)"},
}
function C.offer(id)
    for _,o in ipairs(C.catalog) do if o.id==id then return o end end
end
return C
