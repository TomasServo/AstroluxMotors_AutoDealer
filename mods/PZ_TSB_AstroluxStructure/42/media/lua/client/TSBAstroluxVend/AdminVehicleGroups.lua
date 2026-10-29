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
 -- Resolve role/livery names against installed native base names, longest first.
 local roots={}
 for _,script in ipairs(scripts or {})do
  local base=Families.canonical(script);local display=name(base,labels)
  roots[display:lower()]=display
 end
 local candidates={};for _,display in pairs(roots)do candidates[#candidates+1]=display end
 table.sort(candidates,function(a,b)if #a==#b then return a<b end;return #a>#b end)
 for _,script in ipairs(scripts or {})do
  local base=Families.canonical(script)
  local family=(Config.demandFamilies or {})[base]
  local display=name(base,labels)
  -- KI5 body styles and all their native script variations share one model.
  if script:lower():match('^base%.88toyotahilux') then family='ToyotaHilux88' end
  local lowerScript=script:lower()
  if lowerScript:match('^base%.van') then
   display='Franklin Valuline';family='FranklinValuline'
  elseif lowerScript:match('^base%.stepvan') then
   display='Chevalier Step Van';family='ChevalierStepVan'
  elseif lowerScript:match('^base%.moderncar02') then
   display='Chevalier Primani';family='ChevalierPrimani'
  elseif lowerScript:match('^base%.moderncar') then
   display='Dash Elite';family='DashElite'
  else
   local lower=display:lower()
   for _,root in ipairs(candidates)do
    local core=root:lower()
    if lower~=core and #lower>#core and lower:sub(-#core)==core
      and lower:sub(-#core-1,-#core-1)==' ' then display=root;break end
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
 local group=groups[selector.selected];variants:clear();variants.selected=1;local ids={}
 for i,row in ipairs(group and group.variants or {})do
  ids[i]=row.script;variants:addOption(row.label)
  if row.script==wanted then variants.selected=i end
 end
 return ids
end
return G
