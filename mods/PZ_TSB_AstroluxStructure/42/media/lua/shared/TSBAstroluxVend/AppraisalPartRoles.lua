local Amount=require 'TSBAstroluxVend/Amount'
local Pricing=require 'TSBAstroluxVend/AccessoryPricing'
local M={providers={}}
function M.editable(id)return type(id)=='string'and #id>0 and #id<=200 and not Pricing.lightbar(id)end
local function valid(id,value)
 if not M.editable(id)then return nil,'Light bars and sirens retain their existing policy and cannot be edited here.'end
 if type(value)~='table'or(value.role~='base'and value.role~='accessory')then return nil,'Choose Base Component or Accessory.'end
 if value.price~=nil and not Amount.valid(value.price,0)then return nil,'Enter a nonnegative whole-dollar retail value.'end
 if value.role=='accessory'and value.price==nil then return nil,'Enter the full accessory retail value.'end
 if value.role=='accessory'and(id=='Engine'or id=='Heater'or id=='Battery')then return nil,'Engine, heater and battery remain base components. Set their retail value using Base Component.'end
 return true
end
function M.register(script,parts)
 assert(type(script)=='string'and #script>0 and not M.providers[script],'Duplicate/invalid part-role provider')
 local copy={}
 for id,value in pairs(parts)do local ok,why=valid(id,value);assert(ok,why);copy[id]={role=value.role,price=value.price}end
 M.providers[script]=copy
end
function M.get(settings,script,id)
 if not M.editable(id)then return nil end
 settings=settings or {}
 local rule=((settings.partRoles or {})[script]or {})[id]or(settings.partRoleDefaults or {})[id]or(M.providers[script]or {})[id]
 -- Earlier versions allowed batteries to be marked optional. Preserve a saved
 -- price while keeping essential components in their native base-part role.
 if rule and rule.role=='accessory'and(id=='Battery'or id=='Engine'or id=='Heater')then return {role='base',price=rule.price}end
 return rule
end
function M.filter(base,script,settings)
 local name=script:getFullName();local out,seen={},{}
 for _,id in ipairs(base)do local rule=M.get(settings,name,id)
  if not rule or rule.role=='base'then out[#out+1]=id;seen[id]=true end
 end
 for i=0,script:getPartCount()-1 do local id=script:getPart(i):getId();local rule=M.get(settings,name,id)
  if rule and rule.role=='base'and not seen[id]then out[#out+1]=id;seen[id]=true end
 end
 assert(#out>0,'Classification must retain base vehicle components')
 table.sort(out);return out
end
function M.validateEdit(args,manager)
 if type(args)~='table'or type(args.script)~='string'or type(args.part)~='string'then return nil,'Choose a vehicle and part.'end
 if args.scope~=nil and args.scope~='variation'and args.scope~='all'then return nil,'Choose This Variation or All Vehicles.'end
 if not M.editable(args.part)then return nil,'Light bars and sirens retain their existing policy and cannot be edited here.'end
 local script=manager:getVehicle(args.script);if not script then return nil,'Vehicle is not installed.'end
 local found=false
 for i=0,script:getPartCount()-1 do if script:getPart(i):getId()==args.part then found=true end end
 if not found then return nil,'Part is not declared by this vehicle.'end
 if args.role=='automatic'then return true end
 return valid(args.part,{role=args.role,price=args.price})
end
function M.edit(settings,args,manager)
 local ok,why=M.validateEdit(args,manager);if not ok then return nil,why end
 settings=settings or {}
 local all={};for k,v in pairs(settings.partRoles or {})do all[k]=v end
 local defaults={};for k,v in pairs(settings.partRoleDefaults or {})do defaults[k]=v end
 local value=args.role~='automatic'and{role=args.role,price=args.price}or nil
 if args.scope=='all'then defaults[args.part]=value
 else
  local per={};for k,v in pairs(all[args.script]or {})do per[k]=v end
  per[args.part]=value;all[args.script]=per
 end
 return all,defaults
end
return M
