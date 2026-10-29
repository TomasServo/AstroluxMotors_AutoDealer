-- Adapt the provider callback without copying or editing Workshop code.
-- Conditions still travel through DAMN's normal update buffer/network path.
local Equipment=require 'TSBAstroluxVend/Equipment'
local Buffs=require 'TSBAstroluxVend/BuffSettings'
local Registry=require 'TSBAstroluxVend/VehicleAdapters'
local M={}
local installed={}
local fractions=setmetatable({},{__mode='k'})
local function rules(vehicle)
 local wear,protection={},{}
 if not Buffs.enabled()then return wear,protection end
 local script=vehicle:getScript();local settings=Buffs.settings()
 for _,d in ipairs(Equipment.list(script))do
  if d.protectionParts then
   local policy=Equipment.policy(settings,script:getFullName(),d.id)
   if policy.protectionOverride then
    for _,slot in ipairs(Equipment.compatible(script,d) or {})do
     local part=vehicle:getPartById(slot.part);local item=part and part:getInventoryItem()
     if item and item:getFullType()==slot.item and part:getCondition()>0 then
      wear[part]={percent=policy.durabilityPercent,item=item}
      for _,id in ipairs(d.protectionParts[slot.part] or {})do
       local target=vehicle:getPartById(id)
       if target then protection[target]=policy.protectionPercent end
      end
     end
    end
   end
  end
 end
 return wear,protection
end
function M.wrap(original,armor)
 return function(player,vehicle)
  local wear,protection=rules(vehicle)
  if not next(wear) and not next(protection)then return original(player,vehicle)end
  local setter=armor.setPartCondition
  if type(setter)~='function'then return original(player,vehicle)end
  local baselines={}
  armor.setPartCondition=function(self,part,requested)
   local current=part:getCondition();local rule=wear[part]
   if rule and requested<current and rule.percent>0 then
    local old=fractions[part]
    if not old or old.item~=rule.item or old.percent~=rule.percent or old.last~=current then
     old={item=rule.item,percent=rule.percent,remainder=0};fractions[part]=old
    end
    local loss=(current-requested)*(100-rule.percent)/100+old.remainder
    local whole=math.floor(loss+0.000000001)
    old.remainder=loss-whole;requested=math.max(0,current-whole);old.last=requested
   elseif rule then fractions[part]=nil end
   local strength=protection[part]
   if strength and strength<100 and requested>current then
    requested=current+math.floor((requested-current)*strength/100)
    baselines[part]=requested
   end
   return setter(self,part,requested)
  end
  local ok,result=pcall(original,player,vehicle)
  armor.setPartCondition=setter
  -- A partial restore becomes the next baseline, preventing repeated healing
  -- of the same hit on every player update. The provider owns entry/exit resets.
  for part,value in pairs(baselines)do
   local md=part:getModData();md.saveCond=value;md['damn:savedCondition']=value
  end
  if not ok then error(result,0)end
  return result
 end
end
function M.install()
 local armor=DAMN and DAMN.Armor
 if not armor or type(armor.byVehicleScript)~='table' or type(armor.setPartCondition)~='function'then return end
 for script,adapter in pairs(Registry.byScript)do
  local supported=false
  for _,d in ipairs(adapter.definitions or {})do if d.protectionParts then supported=true;break end end
  local handler=armor.byVehicleScript[script]
  if supported and type(handler)=='function' and handler~=installed[script]then
   local wrapper=M.wrap(handler,armor);installed[script]=wrapper;armor.byVehicleScript[script]=wrapper
  end
 end
end
if Events then
 Events.OnGameStart.Add(M.install)
 -- Accommodate providers registering after this file or changing handlers.
 local last=0
 Events.OnTick.Add(function()local now=getTimestampMs();if now<last or now-last>=1000 then last=now;M.install()end end)
end
return M
