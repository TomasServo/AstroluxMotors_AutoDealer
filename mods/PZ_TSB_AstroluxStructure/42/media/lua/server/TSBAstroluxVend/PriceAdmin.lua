local Amount=require 'TSBAstroluxVend/Amount'
local C=require 'TSBAstroluxVend/Config'
local Equipment=require 'TSBAstroluxVend/Equipment'
local Families=require 'TSBAstroluxVend/VehicleFamilies'
local Groups=require 'TSBAstroluxVend/AdminVehicleGroups'
local A={}
function A.view(settings)
    settings=settings or {}
    return {allowHotwiredBuybacks=settings.allowHotwiredBuybacks~=false,requireBuybackKey=settings.requireBuybackKey~=false,excludeBuybackBattery=settings.excludeBuybackBattery~=false,minimumBuybackParts=settings.minimumBuybackParts or 75,buybacksEnabled=settings.buybacksEnabled==true or (settings.buybacksEnabled==nil and C.tradeInsEnabled==true),buybackPercent=settings.buybackPercent or 50,damagePercent=settings.damagePercent or 100,accessories=settings.accessories or {},revision=settings.revision or 0,normal=settings.normal or C.vehicleClasses[1].price,
        heavy=settings.heavy or C.vehicleClasses[2].price,sports=settings.sports or C.vehicleClasses[3].price,
        addonBuffs=settings.addonBuffs~=false,camperTop=settings.camperTop or C.camperTopPrice,dynamic=settings.dynamic~=false,siren=0,specialPaint=settings.specialPaint or C.specialPaintPrice,modelPrices=settings.modelPrices or {},vehicles=settings.vehicles or {},enabled=settings.enabled or {}}
end
local function amount(n,min)
    if not Amount.valid(n,min) then
        error('Enter finite whole-dollar prices of at least '..min..'.',0)
    end
    return n
end
function A.edit(settings,args,catalog)
    local next=A.view(settings)
    if args.revision~=next.revision then error('Prices changed. Refresh the terminal and reopen pricing.',0)end
    local vehicles={};for k,v in pairs(next.vehicles)do vehicles[k]=v end;next.vehicles=vehicles
    local enabled={};for k,v in pairs(next.enabled)do enabled[k]=v end;next.enabled=enabled
    if args.action=='modelPrice' or args.action=='variantPrice' or args.action=='resetVariant' then
        if type(args.script)~='string' or not catalog.installable[args.script]then error('Choose an installed vehicle variation.',0)end
        local modelPrices={};for k,v in pairs(next.modelPrices)do modelPrices[k]=v end;next.modelPrices=modelPrices
        if args.action=='modelPrice'then
            local price=amount(args.price,1);local found
            for _,group in ipairs(Groups.build(catalog.installedScripts,catalog.scriptLabels))do
                for _,row in ipairs(group.variants)do if row.script==args.script then found=group;break end end
                if found then break end
            end
            if not found then error('Vehicle model unavailable; refresh the menu.',0)end
            -- Blanket operation explicitly resets existing overrides for this model.
            for _,row in ipairs(found.variants)do modelPrices[row.script]=price;vehicles[row.script]=nil end
        elseif args.action=='variantPrice'then vehicles[args.script]=amount(args.price,1)
        else vehicles[args.script]=nil end
    elseif args.action=='accessory' and Families.target(args.accessory)then
        local target=Families.target(args.accessory)
        if not Families.member(args.script,target,'configuration') or not catalog.installable[args.script] or not catalog.installable[target]then error('Choose an installed factory configuration.',0)end
        if type(args.enabled)~='boolean' or type(args.buffEnabled)~='boolean'then error('Choose configuration availability.',0)end
        if args.buffEnabled or amount(args.capacityBonus,0)~=0 then error('Factory configurations retain native stats; no extra storage buff is added.',0)end
        local policies={};for k,v in pairs(next.accessories)do policies[k]=v end
        local per={};for k,v in pairs(policies[args.script] or {})do per[k]=v end
        per[args.accessory]={enabled=args.enabled,price=amount(args.accessoryPrice,0),buffEnabled=false,capacityBonus=0}
        policies[args.script]=per;next.accessories=policies
    elseif args.action=='accessory' then
        if type(args.script)~='string' or not catalog.installable[args.script] then error('Choose a compatible installed accessory.',0)end
        Equipment.list(getScriptManager():getVehicle(args.script))
        if not Equipment.byID[args.accessory] or not Equipment.compatible(getScriptManager():getVehicle(args.script),Equipment.byID[args.accessory])then error('Accessory is incompatible with this vehicle.',0)end
        if amount(args.capacityBonus,0)>0 and not Equipment.capacityPart(getScriptManager():getVehicle(args.script))then error('This vehicle has no supported native bed for an added storage bonus.',0)end
        if type(args.enabled)~='boolean' or type(args.buffEnabled)~='boolean'then error('Choose accessory availability and buff state.',0)end
        local policies={};for k,v in pairs(next.accessories)do policies[k]=v end
        local per={};for k,v in pairs(policies[args.script] or {})do per[k]=v end
        per[args.accessory]={enabled=args.enabled,price=amount(args.accessoryPrice,0),buffEnabled=args.buffEnabled,capacityBonus=amount(args.capacityBonus,0)}
        policies[args.script]=per;next.accessories=policies
        local sum=0;local script=getScriptManager():getVehicle(args.script)
        for _,d in ipairs(Equipment.list(script))do if Equipment.compatible(script,d)then
            local policy=Equipment.policy(next,args.script,d.id)
            if policy.buffEnabled then sum=Amount.add(sum,policy.capacityBonus)end
        end end
        if sum>2147480000 then error('Combined bonuses exceed native storage capacity.',0)end
    elseif args.action=='buybacks' then
        if type(args.buybacksEnabled)~='boolean' then error('Choose buyback availability.',0)end
        for _,key in ipairs({'buybackPercent','damagePercent','minimumBuybackParts'})do
            local n=args[key]
            if type(n)~='number' or n~=n or n==math.huge or n<0 or n>100 then error('Enter percentages from 0 to 100.',0)end
        end
        if type(args.allowHotwiredBuybacks)~='boolean' then error('Choose hotwired vehicle availability.',0)end
        next.allowHotwiredBuybacks=args.allowHotwiredBuybacks
        if type(args.requireBuybackKey)~='boolean' or type(args.excludeBuybackBattery)~='boolean' then error('Choose key and battery rules.',0)end
        next.requireBuybackKey=args.requireBuybackKey;next.excludeBuybackBattery=args.excludeBuybackBattery;next.minimumBuybackParts=args.minimumBuybackParts
        next.buybacksEnabled=args.buybacksEnabled;next.buybackPercent=args.buybackPercent;next.damagePercent=args.damagePercent
    elseif args.action=='mode' then
        if type(args.dynamic)~='boolean' then error('Choose static or dynamic pricing.',0)end
        next.dynamic=args.dynamic
    elseif args.action=='buffs' then
        if type(args.addonBuffs)~='boolean' then error('Choose whether add-on buffs are enabled.',0)end
        next.addonBuffs=args.addonBuffs
    elseif args.action=='camper' then
        next.camperTop=amount(args.camperTop,1)
    elseif args.action=='paint' then
        next.specialPaint=amount(args.specialPaint,1)
    elseif args.action=='availability' then
        if type(args.script)~='string' or not catalog.installable[args.script]then error('Choose an installed vehicle variation.',0)end
        if type(args.enabled)~='boolean'then error('Choose whether to offer this vehicle.',0)end
        enabled[args.script]=args.enabled
    elseif args.action=='addVehicle' then
        if type(args.script)~='string' or not catalog.installable[args.script] then error('Choose an installed, enabled vehicle with supported native dimensions.',0)end
        vehicles[args.script]=amount(args.price,1)
    elseif args.action=='classes' then
        next.normal=amount(args.normal,1);next.heavy=amount(args.heavy,1)
        next.sports=amount(args.sports,1);next.siren=0
    elseif args.action=='vehicle' or args.action=='resetVehicle' then
        local offer=catalog:resolve(args.offer)
        vehicles[offer.script]=args.action=='vehicle' and amount(args.price,1) or nil
    else error('Unknown pricing action.',0)end
    next.revision=next.revision+1
    return next
end
return A
