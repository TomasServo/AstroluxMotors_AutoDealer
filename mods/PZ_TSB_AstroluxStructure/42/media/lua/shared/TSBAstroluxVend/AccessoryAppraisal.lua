local Amount=require 'TSBAstroluxVend/Amount'
local Equipment=require 'TSBAstroluxVend/Equipment'
local Pricing=require 'TSBAstroluxVend/AccessoryPricing'
local Stock=require 'TSBAstroluxVend/Stock'
local Roles=require 'TSBAstroluxVend/AppraisalPartRoles'
local M={}
local function condition(value)
 if type(value)~='number' or value~=value or value<0 or value>100 then error('Invalid accessory condition.',0) end
 return value
end
function M.calculate(vehicle,byId,rate,damageRate,settings,baseParts)
 local rows,marks,claimed={}, {}, {}
 local earned,maximum=0,0
 local covered={}
 for _,id in ipairs(baseParts or {})do covered[id]=true end
 local script=vehicle:getScript()
 local definitions={}
 for _,d in ipairs(Equipment.list(script))do definitions[#definitions+1]=d end
 table.sort(definitions,function(a,b)return a.id<b.id end)
 for _,d in ipairs(definitions)do
  local compatible=Equipment.compatible(script,d)
  if compatible then
   local policy=Equipment.policy(settings,script:getFullName(),d.id)
   -- Resale is independent of whether the admin offers this upgrade for sale.
   local classified=false
   for _,slot in ipairs(compatible)do if Roles.get(settings,script:getFullName(),slot.part)then classified=true end end
   if not classified and not Pricing.lightbar(d.id) then
    local slots,seen,installed={}, {}, false
    for _,slot in ipairs(compatible)do
     if seen[slot.part] then error('Duplicate accessory appraisal slot.',0)end
     seen[slot.part]=true
     local part=byId[slot.part]
     local item=part and part:getInventoryItem()
     local matches=item and item:getFullType()==slot.item
     slots[#slots+1]={slot=slot,part=part,matches=matches==true}
     if matches then installed=true end
    end
    table.sort(slots,function(a,b)return a.slot.part<b.slot.part end)
    if installed then
     local retail,estimated=Pricing.price(settings,script:getFullName(),d,policy)
     local price=Amount.check(retail,0)
     local cap=math.floor(price*rate)
     -- Divide the complete upgrade surcharge once, including missing pieces.
     -- Quotient/remainder avoids multiplying large prices by slot counts.
     local share=math.floor(cap/#slots);local remainder=cap-share*#slots
     marks[#marks+1]='accessory:'..d.id..':retail:'..price
     for i,entry in ipairs(slots)do
      local slot=entry.slot
      local c=entry.matches and condition(entry.part:getCondition()) or 0
      if entry.matches then
       if claimed[slot.part] then error('Overlapping accessory appraisal mappings; review required.',0)end
       claimed[slot.part]=true
      end
      local max=share+(i<=remainder and 1 or 0)
      local value=entry.matches and math.floor(max*(1-damageRate*(100-c)/100)) or 0
      local label=d.label..(estimated and ' (estimated upgrade value)' or ' (upgrade value)')
      if #slots>1 then label=label..' - '..slot.part end
      rows[#rows+1]={id='accessory:'..d.id..':'..slot.part,label=label,optional=true,
       condition=c,missing=not entry.matches,maximum=max,value=value,estimated=estimated,retail=price}
      earned=Amount.add(earned,value);maximum=Amount.add(maximum,max)
      marks[#marks+1]=slot.part..':'..slot.item..':'..tostring(entry.matches)..':'..c..':'..max
     end
    end
   end
  end
 end
 -- Installed equipment with ambiguous/no purchase mapping still has resale value.
 -- Do not infer installation recipes or enable it in the sales catalog.
 local ids={};for id in pairs(byId)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do
  local part=byId[id];local item=part:getInventoryItem()
  local itemType=item and item:getFullType()
  local role=Roles.get(settings,script:getFullName(),id)
  if itemType and (not role or role.role=='accessory') and not claimed[id] and not covered[id] and not Stock.blank(script:getFullName(),id)
   and not Pricing.lightbar(id) and not Pricing.lightbar(itemType)then
   local key='native:'..script:getFullName()..':'..id..':'..itemType
   local override=(((settings or {}).accessories or {})[script:getFullName()] or {})[key] or {}
   local reviewed=role and role.price or override.price
   local estimated=reviewed==nil
   local price=Amount.check(estimated and Pricing.estimate(id..':'..itemType) or reviewed,0)
   local c=condition(part:getCondition());local cap=math.floor(price*rate)
   local value=math.floor(cap*(1-damageRate*(100-c)/100))
   rows[#rows+1]={id='accessory:'..key,label=id..(estimated and ' (estimated upgrade value)' or ' (upgrade value)'),optional=true,condition=c,missing=false,maximum=cap,value=value,estimated=estimated,retail=price}
   marks[#marks+1]=key..':retail:'..price..':condition:'..c
   earned=Amount.add(earned,value);maximum=Amount.add(maximum,cap)
  end
 end
 return rows,marks,earned,maximum
end
return M
