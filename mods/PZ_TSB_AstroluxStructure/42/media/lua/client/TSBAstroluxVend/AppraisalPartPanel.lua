require 'ISUI/ISLabel'
local Groups=require 'TSBAstroluxVend/AdminVehicleGroups'
local Roles=require 'TSBAstroluxVend/AppraisalPartRoles'
local M={}
function M.create(panel,button)
 panel.groups.partRoles={}
 button('buybacks',10,450,900,'Vehicle Part Appraisal Values',function(p)p:showPage('partRoles')end)
 local function label(x,y,text)panel:addControl('partRoles',ISLabel:new(x,y,24,text,1,1,1,1,UIFont.Small,true))end
 label(10,42,'Vehicle Model');label(450,42,'Variation');label(10,103,'Part');label(450,103,'Apply Rule To')
 label(10,165,'Appraisal Role');label(450,165,'Full Retail Value ($)')
 local function choice(x,y,w)return panel:addControl('partRoles',ISComboBox:new(x,y,w,28,panel,nil))end
 local models,variants=choice(10,70,420),choice(450,70,440)
 local parts,scope=choice(10,130,420),choice(450,130,440)
 scope:addOption('This Variation');scope:addOption('All Vehicles with This Part')
 local role=choice(10,195,420)
 role:addOption('Automatic / Inherited Rule');role:addOption('Base Component');role:addOption('Accessory')
 local price=panel:addControl('partRoles',ISTextEntryBox:new('',450,195,220,28))
 local status=panel:addControl('partRoles',ISLabel:new(10,245,24,'',1,1,1,1,UIFont.Small,true))
 local labels={}
 for id,value in pairs(panel.settings.scriptLabels or {})do labels[id]=value:gsub(' %[[^%]]+%]$','')end
 local groups=Groups.build(panel.settings.scripts,labels)
 local Families=require 'TSBAstroluxVend/VehicleFamilies'
 for _,g in ipairs(groups)do for _,row in ipairs(g.variants)do
  local member=Families.members[row.script]
  if member and member.label then row.label=row.label..' - '..member.label
  else for _,other in ipairs(g.variants)do
   if other.script~=row.script and Families.canonical(other.script)==row.script then row.label=row.label..' - Standard';break end
  end end
 end end
 for _,g in ipairs(groups)do models:addOption(g.label)end
 local saved=panel.partAppraisalSelection or {};panel.partAppraisalSelection=saved
 scope.selected=saved.scope=='all'and 2 or 1
 local scriptIDs,partIDs={},{}
 local function remember()
  saved.script=scriptIDs[variants.selected];saved.part=partIDs[parts.selected];saved.scope=scope.selected==2 and'all'or'variation'
 end
 local function selected()
  remember();local id,name=saved.part,saved.script;local own
  if saved.scope=='all'then own=(panel.settings.partRoleDefaults or {})[id]
  else own=((panel.settings.partRoles or {})[name]or {})[id]end
  local effective=Roles.get(panel.settings,name,id)
  local shown=own or effective
  role.selected=shown and(shown.role=='accessory'and 3 or 2)or 2
  price:setText(tostring(own and own.price or effective and effective.price or ''))
  if id=='Battery'or id=='Engine'or id=='Heater'then
   role.selected=2
   status:setName('Base component: retail value uses the buyback percentage and condition.')
  elseif effective then status:setName('Effective rule: '..(effective.role=='base'and'Base Component'or'Accessory')..(effective.price~=nil and(' | Retail $'..effective.price)or' | Weighted value'))
  else status:setName('No override: native/provider appraisal applies.')end
  if saved.scope=='all'and((panel.settings.partRoles or {})[name]or {})[id]then
   status:setName('This variation has its own override. Clear it under This Variation to inherit the global rule.')
  end
 end
 local function rebuildParts(wanted)
  parts:clear();partIDs={};local name=scriptIDs[variants.selected];local script=name and getScriptManager():getVehicle(name)
  if script then for i=0,script:getPartCount()-1 do local id=script:getPart(i):getId();if Roles.editable(id)then partIDs[#partIDs+1]=id end end end
  table.sort(partIDs)
  for i,id in ipairs(partIDs)do
   local translated=getTextOrNull and getTextOrNull('IGUI_VehiclePart'..id)
   parts:addOption(translated or id:gsub('(%l)(%u)','%1 %2'))
   if id==wanted then parts.selected=i end
  end
  selected()
 end
 local function rebuildModel(wanted)
  scriptIDs=Groups.select(groups,models,variants,wanted);rebuildParts(saved.part)
 end
 models.onChange=function()rebuildModel(nil)end
 variants.onChange=function()rebuildParts(saved.part)end
 parts.onChange=selected;scope.onChange=selected
 label(10,295,'Example: $600 retail pays $300 at 50% buyback and full condition.')
 label(10,325,'Base-part prices reserve value from the car total; other base parts share the remainder.')
 label(10,355,'All Vehicles matches this part across vehicles. Variation overrides take precedence.')
 label(10,385,'Automatic removes the selected rule. Light bars and sirens keep their existing policy.')
 button('partRoles',10,440,900,'Save Part Appraisal Value',function(p)
  remember();if not saved.script or not saved.part then return end
  local value=price:getText();local numeric=value~=''and tonumber(value)or nil
  if value~=''and not numeric then status:setName('Enter a whole-dollar retail value.');return end
  local args={action='partRole',revision=p.settings.revision,script=saved.script,part=saved.part,scope=saved.scope,role=({'automatic','base','accessory'})[role.selected],price=numeric}
  local ok,why=Roles.validateEdit(args,getScriptManager())
  if not ok then status:setName(why);return end
  p.send(args)
 end)
 rebuildModel(saved.script or(panel.offer and panel.offer.script))
end
return M
