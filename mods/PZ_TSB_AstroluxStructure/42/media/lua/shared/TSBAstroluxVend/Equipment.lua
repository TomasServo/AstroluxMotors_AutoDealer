-- Audited mappings plus discovery from loaded removable native part definitions.
local Amount=require 'TSBAstroluxVend/Amount'
local Stock=require 'TSBAstroluxVend/Stock'
local C=require 'TSBAstroluxVend/Config'
local Discovery=require 'TSBAstroluxVend/EquipmentDiscovery'
local E={}
local discovered={}
local function slot(part,item,model)return {part=part,item=item,model=model}end
E.definitions={
 {id='camper',label='Camper top',price=500,bonus=46,effect='Native removable bed cover',slots={slot('HLX88TruckBedExtras','Base.88toyotaHiluxBedCap2','HLX88Cap')}},
 {id='roofRack',label='Luggage rack',price=500,requires='camper',effect='Native rack storage; requires camper top',slots={slot('HLX88Roofrack','Base.88toyotaHiluxRoofrack2','Roofrack0')}},
 {id='frontBullbar',label='Front bullbar',price=500,effect='Native front protection',slots={slot('DAMNBumperFront','Base.88toyotaHiluxBullbarFrontA','FrontBullbarA')}},
 {id='rearBullbar',label='Rear bullbar',price=500,effect='Native rear protection',slots={slot('DAMNBumperRear','Base.88toyotaHiluxBullbarRearA','RearBullbarA')}},
 {id='steps',label='Step rails',price=250,effect='Native side-step equipment',slots={slot('DAMNSideSteps','Base.88toyotaHiluxSideSteps2','SideSteps0')}},
 {id='armor',label='Window armor',price=1500,effect='Native protection on compatible windows',partial=true,slots={
  slot('DAMNWindshieldArmor','Base.88toyotaHiluxWindshieldArmor','winda'),
  slot('DAMNFrontLeftArmor','Base.88toyotaHiluxFrontWindowArmor','leftWindowa'),
  slot('DAMNFrontRightArmor','Base.88toyotaHiluxFrontWindowArmor','rightWindowa'),
  slot('DAMNBackLeftArmor','Base.88toyotaHiluxBackWindowArmor','winbla'),
  slot('DAMNBackRightArmor','Base.88toyotaHiluxBackWindowArmor','winbra'),
  slot('DAMNWindshieldRearArmor','Base.88toyotaHiluxWindshieldRearArmor','windra')}},
 {id='bedSpare',label='Bed-mounted spare tire',price=250,effect='Native spare tire and mount',slots={slot('DAMNSpareTireBed','Base.88toyotaHiluxTire2','SpareTire')}},
 {id='spareTire',label='Underbody spare tire',price=250,effect='Native spare tire; hidden underbody mounting',slots={slot('DAMNSpareTire','Base.88toyotaHiluxTire2',false)}},
}
E.byID={};for i,d in ipairs(E.definitions)do E.byID[d.id]=d;d.bit=2^(i-1)end
function E.policy(settings,script,id)
 local d=assert(E.byID[id],'Unknown accessory')
 local per=((settings or {}).accessories or {})[script] or {};local p=per[id] or {}
 local price=p.price
 if price==nil then price=id=='camper' and ((settings or {}).camperTop or C.camperTopPrice) or d.price end
 local bonus=p.capacityBonus
 if bonus==nil then bonus=id=='camper' and (C.camperTopCapacityBonus or 46) or 0 end
 Amount.check(bonus,0)
 if bonus>2147480000 then error('Capacity bonus exceeds the native storage limit.',0)end
 return {enabled=(p.enabled==true or (not d.discovered and p.enabled~=false)),price=Amount.check(price,0),buffEnabled=p.buffEnabled~=false,
  capacityBonus=Amount.check(bonus,0)}
end
function E.compatible(script,d)
 if not script or (d.vehicle and d.vehicle~=script:getFullName()) or (not d.discovered and not Stock.isHilux(script:getFullName()))then return nil end
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
 if not cached or cached.script~=script then
  local covered={}
  for _,d in ipairs(E.definitions)do local slots=E.compatible(script,d)
   for _,s in ipairs(slots or {})do covered[s.part]=true end
  end
  local extra,issues=Discovery.scan(script,covered)
  cached={script=script,extra=extra,issues=issues};discovered[full]=cached
  for _,d in ipairs(extra)do E.byID[d.id]=d end
 end
 local out={};for _,d in ipairs(E.definitions)do out[#out+1]=d end
 for _,d in ipairs(cached.extra)do out[#out+1]=d end
 return out
end
function E.issues(script)E.list(script);return discovered[script:getFullName()].issues end
function E.optional(script,id)
 E.list(script)
 for _,d in ipairs(discovered[script:getFullName()].extra)do for _,s in ipairs(d.slots)do if s.part==id then return true end end end
 return Discovery.optional(id)
end
function E.capacityPart(script)
 local target=Stock.isHilux(script:getFullName()) and 'HLX88Trunk' or 'TruckBed'
 if script.getPartCount then for i=0,script:getPartCount()-1 do if script:getPart(i):getId()==target then return target end end end
end
function E.options(script,settings,includeDisabled)
 local out={}
 for _,d in ipairs(E.list(script))do
  if E.compatible(script,d)then
   local p=E.policy(settings,script:getFullName(),d.id)
   if includeDisabled or (p.enabled and (not d.requires or E.policy(settings,script:getFullName(),d.requires).enabled))then
    out[#out+1]={id=d.id,label=d.label,price=p.price,enabled=p.enabled,requires=d.requires,effect=d.effect,
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
 for id,v in pairs(selected or {})do if v then local d=assert(E.byID[id],'Unknown accessory')
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


