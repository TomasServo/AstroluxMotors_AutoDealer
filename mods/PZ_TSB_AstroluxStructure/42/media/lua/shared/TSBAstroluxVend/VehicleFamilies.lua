-- Explicit native configurations. Do not merge unrelated cars by similar names.
local Amount=require 'TSBAstroluxVend/Amount'
local F={}
F.members={
 ['Base.CarStationWagon2']={base='Base.CarStationWagon',kind='paint',label='Wood panel design'},
 -- Optional native windowed body includes the original six-seat layout/stats.
 ['Base.VanSeats']={base='Base.Van',kind='configuration',label='Passenger windows (6 seats)'},
}
for name,row in pairs(require 'TSBAstroluxVend/NativeVehicleVariants')do F.members[name]=row end
function F.canonical(name)return F.members[name] and F.members[name].base or name end
function F.member(base,target,kind)
 local d=F.members[target]
 if not d and F.canonical(base)==target and base~=target then d={base=target,kind='variant',label='Standard'} end
 return d and (d.base==base or (d.kind=='variant' and d.base==F.canonical(base))) and (not kind or d.kind==kind) and d or nil
end
function F.id(target)return 'configuration:'..target end
function F.target(id)
 if type(id)~='string'then return nil end
 local target=id:match('^configuration:(.+)$')
 return F.members[target] and (F.members[target].kind=='configuration' or F.members[target].kind=='paint') and target or nil
end
function F.policy(settings,base,target)
 local p=((((settings or {}).accessories or {})[base] or {})[F.id(target)]) or {}
 return {enabled=p.enabled~=false,price=Amount.check(p.price or ((F.members[target] and F.members[target].kind=='paint') and ((settings or {}).specialPaint or require('TSBAstroluxVend/Config').specialPaintPrice) or 0),0)}
end
function F.adminRows(settings,base,installable)
 local out={}
 for target,d in pairs(F.members)do
  if d.base==base and installable[target]then
   local p=F.policy(settings,base,target)
   out[#out+1]={id=F.id(target),label=d.label,effect='Native factory configuration; includes its original seating and stats',
    enabled=p.enabled,price=p.price,buffEnabled=false,capacityBonus=0,activeBonus=0,capacitySupported=false,configuration=true}
  end
 end
 table.sort(out,function(a,b)return a.id<b.id end)
 return out
end
return F

-- Variant policies are also used by color pricing.
