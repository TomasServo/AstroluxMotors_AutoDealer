-- Menu-only grouping; every variation retains its exact native script identity.
local Families=require 'TSBAstroluxVend/VehicleFamilies'
local Config=require 'TSBAstroluxVend/Config'
local G={}
local function name(script,labels)
 local label=labels[script] or script
 local marker=label:find(' [',1,true)
 return marker and label:sub(1,marker-1) or label
end
function G.build(scripts,labels)
 labels=labels or {};local groups,byKey={},{}
 local names={};for _,script in ipairs(scripts or {})do local n=name(script,labels);names[n:lower()]=n end
 for _,script in ipairs(scripts or {})do
  local base=Families.canonical(script)
  local family=(Config.demandFamilies or {})[base]
  local display=name(base,labels)
  -- Native service labels retain the base model name after their role prefix.
  for _,prefix in ipairs({'Police ','Ranger ','Fire ','Ambulance ','Taxi '})do
   if display:sub(1,#prefix):lower()==prefix:lower()then
    local core=display:sub(#prefix+1);if names[core:lower()]then display=names[core:lower()]end
   end
  end
  if family=='ToyotaHilux88' then display='Toyota Hilux (1988)'end
  local key=family and ('family:'..family) or display:lower()
  local group=byKey[key]
  if not group then group={label=display,variants={}};byKey[key]=group;groups[#groups+1]=group end
  group.variants[#group.variants+1]={script=script,label=labels[script] or script}
 end
 for _,group in ipairs(groups)do
  table.sort(group.variants,function(a,b)
   if a.label:lower()==b.label:lower()then return a.script<b.script end
   return a.label:lower()<b.label:lower()
  end)
 end
 table.sort(groups,function(a,b)return a.label:lower()<b.label:lower()end)
 return groups
end
function G.select(groups,selector,variants,wanted)
 if wanted then for i,group in ipairs(groups)do for _,row in ipairs(group.variants)do
  if row.script==wanted then selector.selected=i end
 end end end
 local group=groups[selector.selected];variants:clear();local ids={}
 for i,row in ipairs(group and group.variants or {})do
  ids[i]=row.script;variants:addOption(row.label)
  if row.script==wanted then variants.selected=i end
 end
 return ids
end
return G
