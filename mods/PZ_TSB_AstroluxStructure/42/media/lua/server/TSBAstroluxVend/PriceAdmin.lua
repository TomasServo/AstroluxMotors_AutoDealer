local Amount=require 'TSBAstroluxVend/Amount'
local C=require 'TSBAstroluxVend/Config'
local A={}
function A.view(settings)
    settings=settings or {}
    return {revision=settings.revision or 0,normal=settings.normal or C.vehicleClasses[1].price,
        heavy=settings.heavy or C.vehicleClasses[2].price,sports=settings.sports or C.vehicleClasses[3].price,
        dynamic=settings.dynamic~=false,siren=0,specialPaint=settings.specialPaint or C.specialPaintPrice,vehicles=settings.vehicles or {},enabled=settings.enabled or {}}
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
    if args.action=='mode' then
        if type(args.dynamic)~='boolean' then error('Choose static or dynamic pricing.',0)end
        next.dynamic=args.dynamic
    elseif args.action=='paint' then
        next.specialPaint=amount(args.specialPaint,1)
    elseif args.action=='addVehicle' then
        if type(args.script)~='string' or not catalog.installable[args.script] then error('Choose an installed, enabled vehicle with supported native dimensions.',0)end
        enabled[args.script]=true;vehicles[args.script]=amount(args.price,1)
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
