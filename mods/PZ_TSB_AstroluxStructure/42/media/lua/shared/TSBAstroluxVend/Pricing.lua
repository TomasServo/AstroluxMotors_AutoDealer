local Amount=require 'TSBAstroluxVend/Amount'
local C=require 'TSBAstroluxVend/Config'
local P={}
local function money(n)
    if not Amount.valid(n,0)then error('Invalid vehicle price component.',0)end
    return n
end
function P.forScript(script,override,settings)
    settings=settings or {}
    override=override or {}
    local kind=override.class or script:getMechanicType()
    local class=C.vehicleClasses[kind]
    if not class then kind=1;class=C.vehicleClasses[1] end
    local base=money(override.basePrice or settings[({[1]='normal',[2]='heavy',[3]='sports'})[kind]] or class.price)
    local extras,labels=0,{}
    -- Sirens are included in the vehicle price; saved legacy surcharges are ignored.
    -- Deliveries are stock-only. Legacy optional addon configuration is ignored;
    -- explicit administrator prices still take precedence below.
    local total=money(Amount.add(base,extras))
    if override.price~=nil then total=money(override.price)end
    if total<1 then error('Vehicle price must be positive.',0)end
    return {class=class.name,base=base,addons=extras,total=total,condition=100,
        details=table.concat(labels,', '),fixed=override.price~=nil}
end
return P
