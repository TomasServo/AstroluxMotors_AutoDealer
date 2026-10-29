-- Portable native-item blueprints. Never persist live Java items in ModData.
require 'Moveables/ISMoveableSpriteProps'
local I={version=2,maxItems=2000,maxDepth=8}
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
  if instanceof(item,'Moveable') and item:getWorldSprite() then
   entry.worldSprite=item:getWorldSprite()
  end
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
local function createSavedItem(entry)
 local fullType=entry.fullType
 assert(type(fullType)=='string','Saved inventory item type is invalid')
 local script=getScriptManager():getItem(fullType)
 local spriteName=entry.worldSprite
 -- Older captures recorded Moveable's runtime Base.<sprite> type, which is
 -- not an item script. Recover only an exact, native movable sprite; never
 -- substitute a generic item for a missing mod/provider.
 if not spriteName and not script then
  spriteName=fullType:match('^Base%.([%w_]+_%d+)$') or fullType:match('^Moveables%.([%w_]+_%d+)$')
 end
 if not spriteName then return instanceItem(fullType) end
 assert(type(spriteName)=='string','Saved furniture sprite is invalid')
 local sprite=getSprite(spriteName)
 assert(sprite and sprite:getName()==spriteName,'Missing saved furniture sprite: '..spriteName)
 local props=ISMoveableSpriteProps.new(spriteName)
 assert(props.isMoveable,'Saved inventory sprite is not movable: '..spriteName)
 local item
 if script then
  item=instanceItem(fullType)
  assert(item and instanceof(item,'Moveable') and item:ReadFromWorldSprite(spriteName),
   'Saved movable item no longer matches: '..fullType)
 else
  -- Uses the same custom-item/generic-item and sprite initialization path
  -- as vanilla furniture pickup, including multi-tile furniture parts.
  assert(fullType=='Base.'..spriteName or fullType=='Moveables.'..spriteName,
   'Missing saved inventory item: '..fullType)
  item=props:instanceItem(spriteName)
 end
 assert(item and instanceof(item,'Moveable') and item:getWorldSprite()==spriteName,
  'Saved furniture item unavailable: '..spriteName)
 return item
end
function I.prepare(entries,depth,budget)
 depth=depth or 0;budget=budget or {count=0};assert(depth<=I.maxDepth,'Inventory nesting limit exceeded')
 local items={}
 for _,entry in ipairs(entries)do
  budget.count=budget.count+1;assert(budget.count<=I.maxItems,'Inventory item limit exceeded')
  local item=createSavedItem(entry);assert(item,'Missing saved inventory item: '..tostring(entry.fullType))
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
-- Only the synchronous placement caller may supply its pre-placement square snapshot.
-- Native IsoMannequin.initOutfit creates random worn inventory on insertion.
function I.restoreNewFurnishing(obj,entries,snapshot)
 assert(snapshot and snapshot.sq==obj:getSquare() and not snapshot.before[obj]
  and obj:getObjectIndex()>=0,'Inventory restoration requires a newly placed furnishing')
 local mannequin=instanceof(obj,'IsoMannequin') and #entries>0
 if mannequin then
  assert(#entries==1 and entries[1].index==0 and entries[1].kind=='mannequin'
   and obj:getContainerCount()==1,'Saved mannequin container no longer matches')
  local c=obj:getContainerByIndex(0)
  assert(c and c:getType()=='mannequin','Saved mannequin container no longer matches')
  local defaults=c:getItems();local worn=obj:getWornItems()
  -- Do not discard arbitrary loot added by another placement hook.
  for n=0,defaults:size()-1 do
   assert(worn:contains(defaults:get(n)),'Unexpected non-outfit mannequin items; paste cancelled')
  end
  c:clear();obj:checkClothing(nil)
 end
 I.restoreObject(obj,entries)
 if mannequin then
  -- Legacy captured profiles contain inventory but no worn-slot metadata.
  -- Use native dressing; nil prevents displaced clothing going to the player.
  for _,item in ipairs(entries[1].items)do obj:wearItem(item,nil)end
 end
end
return I
