-- Portable native-item blueprints. Never persist live Java items in ModData.
local I={version=1,maxItems=2000,maxDepth=8}
local fields={
 {'getName','setName'},{'getCondition','setCondition'},{'getFavorite','setFavorite'},
 {'getCount','setCount'},{'getCurrentUses','setCurrentUses'},{'getUsedDelta','setUsedDelta'},
 {'getAge','setAge'},{'getLastAged','setLastAged'},{'isCooked','setCooked'},
 {'isBurnt','setBurnt'},{'getFreezingTime','setFreezingTime'},{'isFrozen','setFrozen'},
 {'getBaseHunger','setBaseHunger'},{'getHungChange','setHungChange'},{'getThirstChange','setThirstChange'},
 {'getBoredomChange','setBoredomChange'},{'getUnhappyChange','setUnhappyChange'},
 {'getCalories','setCalories'},{'getCarbohydrates','setCarbohydrates'},{'getLipids','setLipids'},
 {'getProteins','setProteins'},{'getPoisonPower','setPoisonPower'},
 {'getCurrentAmmoCount','setCurrentAmmoCount'},{'isContainsClip','setContainsClip'},
 {'isRoundChambered','setRoundChambered'},{'isJammed','setJammed'},
 {'getDirtiness','setDirtiness'},{'getBloodLevel','setBloodLevel'},
 {'getKeyId','setKeyId'},{'getColorRed','setColorRed'},
 {'getColorGreen','setColorGreen'},{'getColorBlue','setColorBlue'}
}
local function pure(value,seen,depth)
 local kind=type(value)
 if kind=='string' or kind=='boolean' then return value end
 if kind=='number' then assert(value==value and math.abs(value)<math.huge,'Invalid item number');return value end
 assert(kind=='table','Unsupported item metadata; capture cancelled')
 assert(depth<20 and not seen[value],'Cyclic or over-deep item metadata; capture cancelled')
 seen[value]=true;local result={}
 for k,v in pairs(value)do assert(type(k)=='string' or type(k)=='number','Unsupported metadata key');result[k]=pure(v,seen,depth+1)end
 seen[value]=nil;return result
end
function I.capture(container,depth,budget)
 depth=depth or 0;budget=budget or {count=0}
 assert(depth<=I.maxDepth,'Inventory nesting limit exceeded; previous capture retained')
 local out={};local list=container:getItems()
 for index=0,list:size()-1 do
  budget.count=budget.count+1;assert(budget.count<=I.maxItems,'Inventory capture limit exceeded')
  local item=list:get(index);assert(not (item.getByteData and item:getByteData()),'Packed world-object item cannot be captured safely')
  local entry={fullType=item:getFullType(),values={}}
  for _,field in ipairs(fields)do if item[field[1]] and item[field[2]] then
   local value=item[field[1]](item);if value~=nil then entry.values[field[2]]=pure(value,{},0)end
  end end
  if item.hasModData and item:hasModData() then entry.modData=pure(item:getModData(),{},0)end
  local fluids=item.getFluidContainer and item:getFluidContainer()
  if fluids and fluids:getAmount()>0 then
   assert(Fluid and Fluid.getAllFluids,'Native fluid enumeration unavailable')
   entry.fluids={};local all=Fluid.getAllFluids();local total=0
   for n=0,all:size()-1 do local fluid=all:get(n);local amount=fluids:getSpecificFluidAmount(fluid)
    if amount>0 then entry.fluids[#entry.fluids+1]={name=fluid:getFluidTypeString(),amount=amount};total=total+amount end
   end
   assert(math.abs(total-fluids:getAmount())<0.001,'Unknown fluid contents; capture cancelled')
  end
  if item.getInventory and item:getInventory() then entry.items=I.capture(item:getInventory(),depth+1,budget)end
  out[#out+1]=entry
 end
 return out
end
function I.prepare(entries,depth,budget)
 depth=depth or 0;budget=budget or {count=0};assert(depth<=I.maxDepth,'Inventory nesting limit exceeded')
 local items={}
 for _,entry in ipairs(entries)do
  budget.count=budget.count+1;assert(budget.count<=I.maxItems,'Inventory item limit exceeded')
  local item=instanceItem(entry.fullType);assert(item,'Missing saved inventory item: '..tostring(entry.fullType))
  for setter,value in pairs(entry.values or {})do assert(item[setter],'Saved item state is no longer supported: '..setter);item[setter](item,value)end
  if entry.modData then local md=item:getModData();for k,v in pairs(pure(entry.modData,{},0))do md[k]=v end end
  if entry.fluids then local f=item:getFluidContainer();assert(f,'Saved fluid container unavailable');f:removeFluid()
   for _,fluid in ipairs(entry.fluids)do assert(Fluid.Get(fluid.name),'Saved fluid unavailable: '..fluid.name);f:addFluid(fluid.name,fluid.amount)end
  end
  if entry.items then local c=item:getInventory();assert(c,'Saved nested container unavailable');assert(c:getItems():size()==0,'New nested container unexpectedly has contents')
   for _,child in ipairs(I.prepare(entry.items,depth+1,budget))do assert(c:AddItem(child),'Nested item insertion failed')end
  end
  items[#items+1]=item
 end
 return items
end
function I.captureObject(obj)
 local out={};local count=obj.getContainerCount and obj:getContainerCount() or 0
 for n=0,count-1 do local c=obj:getContainerByIndex(n);out[#out+1]={index=n,kind=c:getType(),items=I.capture(c)}end
 return out
end
function I.prepareObject(entries)
 local out={};for _,entry in ipairs(entries or {})do out[#out+1]={index=entry.index,kind=entry.kind,items=I.prepare(entry.items)}end;return out
end
function I.restoreObject(obj,entries)
 for _,entry in ipairs(entries or {})do
  local c=obj:getContainerByIndex(entry.index);assert(c and c:getType()==entry.kind,'Saved furniture container no longer matches')
  assert(c:getItems():size()==0,'New furnishing contains unexpected items; paste cancelled')
  for _,item in ipairs(entry.items)do assert(c:AddItem(item),'Saved item insertion failed')end
 end
end
return I
