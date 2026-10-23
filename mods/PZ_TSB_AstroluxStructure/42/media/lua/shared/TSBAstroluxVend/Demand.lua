local Amount=require 'TSBAstroluxVend/Amount'
-- Persistent world demand. Base catalog prices are never mutated.
local C=require 'TSBAstroluxVend/Config'
local D={}
local function rate(value,default)
 if value==nil then return default end
 if type(value)~='number' or value~=value or value<0 or value==math.huge then error('Use finite, non-negative demand percentages.',0)end
 return value
end
function D.policy(settings)
 settings=settings or {}
 return {increase=rate(settings.demandIncrease,2),recovery=rate(settings.demandRecovery,2)}
end
function D.family(script)return C.demandFamilies[script] or script end
local function validTime(hours)
    if type(hours)~='number' or hours~=hours or hours<0 or hours==math.huge then error('Invalid demand clock.',0)end
    return hours
end
function D.state(db,script,hours)
    validTime(hours)
    local family=D.family(script)
    local s=db.vehicleDemand and db.vehicleDemand[family]
    if not s then return 0,0,family end
    -- Do not increase demand after a clock rewind or decay it below base.
    local elapsed=math.max(0,hours-s.hours)
    return math.max(0,s.points-elapsed*(D.policy(db.pricing).recovery/24)),s.revision,family
end
function D.offer(db,offer,hours)
    local points,revision,family=D.state(db,offer.script,hours)
    local result={};for k,v in pairs(offer)do result[k]=v end
    result.basePrice=offer.price
    local dynamic=not db.pricing or db.pricing.dynamic~=false
    if not dynamic then points=0;revision=0 end
    result.price=Amount.check(math.floor((offer.price+0.0)*(100+points)/100),1)
    result.pricingRevision=(db.pricing or {}).revision or 0
    result.demandRevision=revision;result.demandFamily=family
    result.pricing={};for k,v in pairs(offer.pricing or {})do result.pricing[k]=v end
    result.pricing.total=result.price;result.pricing.baseTotal=offer.price
    result.pricing.demandMarkup=result.price-offer.price;result.pricing.dynamic=dynamic
    return result
end
-- Settle elapsed time at the old rate before changing recovery policy.
function D.settle(db,hours)
 validTime(hours)
 local recovery=D.policy(db.pricing).recovery
 for _,s in pairs(db.vehicleDemand or {})do
  local elapsed=math.max(0,hours-s.hours)
  s.points=math.max(0,s.points-elapsed*(recovery/24))
  s.hours=math.max(hours,s.hours)
 end
end
function D.resetScope(scope)
 local scopes={normal=1,heavy=2,sports=3,all=0}
 if scopes[scope]==nil then error('Choose Normal, Heavy Duty, Sports or All demand.',0)end
 return scopes[scope]
end
function D.modelFamilies(catalog,script)
 if type(script)~='string' or not catalog.installable[script]then error('Choose an installed vehicle model.',0)end
 local Groups=require 'TSBAstroluxVend/AdminVehicleGroups'
 for _,group in ipairs(Groups.build(catalog.installedScripts,catalog.scriptLabels))do
  local chosen=false
  for _,row in ipairs(group.variants)do if row.script==script then chosen=true;break end end
  if chosen then
   local families={};for _,row in ipairs(group.variants)do families[D.family(row.script)]=true end
   return families
  end
 end
 error('Vehicle model unavailable. Refresh the menu.',0)
end
function D.resetFamilies(db,families,hours)
 validTime(hours)
 local updates={}
 for family in pairs(families)do
  local old=(db.vehicleDemand or {})[family]
  if old then updates[#updates+1]={family=family,points=0,hours=math.max(hours,old.hours),revision=(old.revision or 0)+1}end
 end
 for _,row in ipairs(updates)do db.vehicleDemand[row.family]={points=0,hours=row.hours,revision=row.revision}end
 return #updates
end
function D.resetModel(db,catalog,script,hours)
 return D.resetFamilies(db,D.modelFamilies(catalog,script),hours)
end
function D.reset(db,scope,manager,hours)
 local wanted=D.resetScope(scope);validTime(hours)
 local families={}
 if wanted==0 then
  -- Also clear orphan history from vehicle mods no longer enabled.
  for family in pairs(db.vehicleDemand or {})do families[family]=true end
 else
  local scripts=manager:getAllVehicleScripts()
  for i=0,scripts:size()-1 do
   local script=scripts:get(i)
   local ok,name,kind=pcall(function()
    local name=script:getFullName()
    local override=(C.vehicleOverrides or {})[name] or {}
    local kind=override.class or script:getMechanicType()
    if not C.vehicleClasses[kind]then kind=1 end
    return name,kind
   end)
   if ok and kind==wanted then families[D.family(name)]=true end
  end
 end
 return D.resetFamilies(db,families,hours)
end
function D.completed(db,order,hours)
    if order.status~='delivered' or order.demandCounted then return false end
    if db.pricing and db.pricing.dynamic==false then return false end
    local points,revision,family=D.state(db,order.script,hours)
    db.vehicleDemand=db.vehicleDemand or {}
    local old=db.vehicleDemand[family]
    db.vehicleDemand[family]={points=points+D.policy(db.pricing).increase,hours=math.max(hours,old and old.hours or hours),revision=revision+1}
    order.demandCounted=true;order.demandFamily=family
    return true
end
return D
