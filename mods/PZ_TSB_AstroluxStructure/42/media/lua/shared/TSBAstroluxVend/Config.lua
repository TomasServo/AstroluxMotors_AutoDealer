local C={channel='TSBAstroluxVend',version=1}
C.vehicleClasses={[1]={name='Normal',price=4000},[2]={name='Heavy Duty',price=6000},[3]={name='Sports',price=10000}}
C.sirenPrice=0 -- Legacy config retained for compatibility; sirens have no surcharge.
-- Hotel paint pilot: solid colors included; special existing skins cost extra.
C.specialPaintPrice=500
-- Optional server per-script/per-texture classification, label and surcharge.
-- C.paintJobs['Mod.Car']={['Vehicles/car_decal']={special=true,surcharge=900,label='Stripes'}}
C.paintJobs={}
-- Fraction of new retail value before per-part condition deductions.
C.tradeInRate=0.50
-- Remain disabled until explicit live-test approval.
C.tradeInsEnabled=false
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
-- Server owns this catalog. Prices are provisional test-world defaults.
C.catalog={
    {id='compact',script='Base.SmallCar',name='Chevalier Dartist'},
    {id='sedan',script='Base.CarNormal',name='Chevalier Nyala'},
    {id='pickup',script='Base.PickUpVan',name='Chevalier D6'},
    {id='offroad',script='Base.OffRoad',name='Dash Rancher'},
}
function C.offer(id)
    for _,o in ipairs(C.catalog) do if o.id==id then return o end end
end
return C
