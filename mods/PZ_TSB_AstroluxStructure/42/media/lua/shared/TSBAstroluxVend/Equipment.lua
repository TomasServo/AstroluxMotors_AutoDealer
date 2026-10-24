-- Audited mappings plus discovery from loaded removable native part definitions.
local Amount=require 'TSBAstroluxVend/Amount'
local Stock=require 'TSBAstroluxVend/Stock'
local C=require 'TSBAstroluxVend/Config'
local Discovery=require 'TSBAstroluxVend/EquipmentDiscovery'
local E={}
local discovered={}
local function slot(part,item,model)return {part=part,item=item,model=model}end
local Adapters=require 'TSBAstroluxVend/VehicleAdapters'
require 'TSBAstroluxVend/Adapters/Hilux88'
E.definitions=Adapters.definitions
E.byID={}
local function sync()for _,d in ipairs(E.definitions)do E.byID[d.id]=d end end
sync()
function E.policy(settings,script,id)
 sync();local d=assert(E.byID[id],'Unknown accessory')
 sync();local per=((settings or {}).accessories or {})[script] or {};local p=per[id] or (d.policyAlias and per[string.format(d.policyAlias,script)]) or {}
 local price=p.price
 if price==nil then price=d.priceSetting and ((settings or {})[d.priceSetting] or C[d.priceSetting..'Price']) or d.price end
 local bonus=p.capacityBonus
 if bonus==nil then bonus=(d.bonusSetting and C[d.bonusSetting]) or d.bonus or 0 end
 Amount.check(bonus,0)
 if bonus>2147480000 then error('Capacity bonus exceeds the native storage limit.',0)end
 return {enabled=(p.enabled==true or (not d.discovered and p.enabled~=false)),price=Amount.check(price,0),buffEnabled=p.buffEnabled~=false,
  capacityBonus=Amount.check(bonus,0)}
end
function E.compatible(script,d)
 if not script or (d.vehicle and d.vehicle~=script:getFullName()) or (d.vehicles and not d.vehicles[script:getFullName()])then return nil end
 local found={}
 for _,s in ipairs(d.slots)do
  local part
  for i=0,script:getPartCount()-1 do local p=script:getPart(i);if p:getId()==s.part then part=p;break end end
  local valid=part and (not s.model or part:getModelById(s.model)~=nil)
  for _,model in ipairs(s.models or {})do if not part or not part:getModelById(model)then valid=false end end
  local manager=getScriptManager and getScriptManager()
  if valid and manager and manager.FindItem and not manager:FindItem(s.item)then valid=false end
  if valid then found[#found+1]=s elseif not d.partial then return nil end
 end
 return #found>0 and found or nil
end
function E.list(script)
 local full=script:getFullName();local cached=discovered[full]
 sync()
 for _,d in ipairs(E.definitions)do if d.orderAlias and d.vehicles[full]then
  local id=string.format(d.orderAlias,full);local alias={};for k,v in pairs(d)do alias[k]=v end;alias.id=id;alias.bit=nil;alias.vehicle=full;E.byID[id]=alias
 end end
 if not cached or cached.script~=script or cached.version~=Adapters.version then
  local covered={}
  for _,d in ipairs(E.definitions)do local slots=E.compatible(script,d)
   for _,s in ipairs(slots or {})do covered[s.part]=true end
  end
  local extra,issues=Discovery.scan(script,covered)
  cached={script=script,extra=extra,issues=issues,version=Adapters.version};discovered[full]=cached
  for _,d in ipairs(extra)do E.byID[d.id]=d end
 end
 local out={};for _,d in ipairs(E.definitions)do out[#out+1]=d end
 for _,d in ipairs(cached.extra)do out[#out+1]=d end
 return out
end
function E.issues(script)E.list(script);return discovered[script:getFullName()].issues end
function E.optional(script,id)
 -- Strip only reviewed/discovered choices that Astrolux can also reinstall.
 -- Unknown provider equipment keeps its native spawn setup.
 for _,d in ipairs(E.list(script))do
  for _,slot in ipairs(E.compatible(script,d) or {})do if slot.part==id then return true end end
 end
 return false
end
function E.capacityPart(script)
 local adapter=Adapters.get(script:getFullName());local target=adapter and adapter.capacityPart or 'TruckBed'
 if script.getPartCount then for i=0,script:getPartCount()-1 do if script:getPart(i):getId()==target then return target end end end
end
function E.options(script,settings,includeDisabled)
 local out={}
 for _,d in ipairs(E.list(script))do
  if E.compatible(script,d)then
   local p=E.policy(settings,script:getFullName(),d.id)
   if includeDisabled or (p.enabled and (not d.requires or E.policy(settings,script:getFullName(),d.requires).enabled))then
    out[#out+1]={id=d.id,label=d.label,price=p.price,enabled=p.enabled,requires=d.requires,requiresAny=d.requiresAny,exclusiveGroup=d.exclusiveGroup,effect=d.effect,
      buffEnabled=p.buffEnabled,capacityBonus=p.capacityBonus,capacitySupported=E.capacityPart(script)~=nil,discovered=d.discovered==true,
      activeBonus=(settings or {}).addonBuffs~=false and p.buffEnabled and p.capacityBonus or 0}
   end
  end
 end
 return out
end
function E.selection(value,script,camper)
 if value~=nil and type(value)~='table'then error('Invalid accessory selection.',0)end
 if camper~=nil and type(camper)~='boolean'then error('Invalid camper selection.',0)end
 E.list(script)
 local selected={}
 for id,v in pairs(value or {})do
  if type(id)~='string' or not E.byID[id] or type(v)~='boolean'then error('Invalid accessory selection.',0)end
  if v then selected[id]=true end
 end
 if camper==true then selected.camper=true end -- Compatibility with existing camper orders.
 for id in pairs(selected)do
  local d=E.byID[id]
  if not E.compatible(script,d)then error('Accessory no longer compatible: '..d.label,0)end
  if d.requires and not selected[d.requires]then error(d.label..' requires the camper top.',0)end
 end
 local groups={};for id in pairs(selected)do local d=E.byID[id];if d.exclusiveGroup then if groups[d.exclusiveGroup]then error('Choose only one accessory for '..d.exclusiveGroup..'.',0)end;groups[d.exclusiveGroup]=id end end
 for id in pairs(selected)do
  local d=E.byID[id]
  if d.requiresAny then local found=false;for _,other in ipairs(d.requiresAny)do if selected[other]then found=true end end
   if not found then error(d.label..' requires one of its listed supporting accessories.',0)end
  end
 end
 local parts=E.parts(script,selected)
 for id in pairs(selected)do local d=E.byID[id]
  for _,partID in ipairs(d.requiredParts or {})do
   if E.optional(script,partID) and not parts[partID]then error(d.label..' requires selected '..partID,0)end
   local exists=false;for i=0,script:getPartCount()-1 do if script:getPart(i):getId()==partID then exists=true end end
   if not exists then error(d.label..' requires missing '..partID,0)end
  end
  for _,partID in ipairs(d.excludedParts or {})do if parts[partID] or not E.optional(script,partID)then error(d.label..' conflicts with '..partID,0)end end
 end
 return selected
end
function E.key(selected)
 local mask=0;local dynamic={}
 for id,v in pairs(selected or {})do if v then sync();local d=assert(E.byID[id],'Unknown accessory')
  if d.bit then mask=mask+d.bit else dynamic[#dynamic+1]=id end
 end end
 table.sort(dynamic)
 local out=string.format('%d',mask)
 for _,id in ipairs(dynamic)do out=out..'|'..#id..':'..id end
 return out
end
function E.parts(script,selected)
 local out={}
 for id in pairs(selected or {})do
  for _,s in ipairs(assert(E.compatible(script,E.byID[id]),'Accessory part unavailable'))do
   assert(not out[s.part],'Conflicting accessory parts');out[s.part]=s
  end
 end
 return out
end
function E.offer(offer,script,settings,value,camper)
 local selected=E.selection(value,script,camper)
 local result={};for k,v in pairs(offer)do result[k]=v end
 local total=offer.price;local lines={};local priceKey={E.key(selected)}
 for _,d in ipairs(E.list(script))do if selected[d.id]then
  local p=E.policy(settings,script:getFullName(),d.id)
  if not p.enabled then error('Accessory disabled by owner: '..d.label,0)end
  total=Amount.add(total,p.price);lines[#lines+1]=d.label..' +$'..p.price
  priceKey[#priceKey+1]=d.id..':'..p.price
 end end
 result.equipment=selected;result.equipmentKey=table.concat(priceKey,'|');result.equipmentLabel=table.concat(lines,', ')
 result.camperTop=selected.camper==true
 result.camperSurcharge=selected.camper and E.policy(settings,script:getFullName(),'camper').price or 0
 result.price=total
 return result
end
return E


