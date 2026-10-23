-- Explicit native configurations. Do not merge unrelated cars by similar names.
local Amount=require 'TSBAstroluxVend/Amount'
local F={}
F.members={
 ['Base.CarStationWagon2']={base='Base.CarStationWagon',kind='paint',label='Wood panel design'},
 -- Optional native windowed body includes the original six-seat layout/stats.
 ['Base.VanSeats']={base='Base.Van',kind='configuration',label='Passenger windows (6 seats)'},
}
function F.canonical(name)return F.members[name] and F.members[name].base or name end
function F.member(base,target,kind)
 local d=F.members[target]
 return d and d.base==base and (not kind or d.kind==kind) and d or nil
end
function F.id(target)return 'configuration:'..target end
function F.target(id)
 if type(id)~='string'then return nil end
 local target=id:match('^configuration:(.+)$')
 return F.members[target] and F.members[target].kind=='configuration' and target or nil
end
function F.policy(settings,base,target)
 local p=((((settings or {}).accessories or {})[base] or {})[F.id(target)]) or {}
 return {enabled=p.enabled~=false,price=Amount.check(p.price or 0,0)}
end
function F.adminRows(settings,base,installable)
 local out={}
 for target,d in pairs(F.members)do
  if d.base==base and d.kind=='configuration' and installable[target]then
   local p=F.policy(settings,base,target)
   out[#out+1]={id=F.id(target),label=d.label,effect='Native factory configuration; includes its original seating and stats',
    enabled=p.enabled,price=p.price,buffEnabled=false,capacityBonus=0,activeBonus=0,capacitySupported=false,configuration=true}
  end
 end
 table.sort(out,function(a,b)return a.id<b.id end)
 return out
end
return F
