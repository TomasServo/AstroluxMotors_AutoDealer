-- Read loaded native definitions only. Never execute provider install callbacks
-- or infer an item/model pairing from similar names.
local Stock=require 'TSBAstroluxVend/Stock'
local D={}
function D.field(object,name)
 if type(object)=='table' then return object[name] end
 if not object or not getNumClassFields then return nil end
 for i=0,getNumClassFields(object)-1 do
  local field=getClassField(object,i)
  if field:getName()==name then return getClassFieldVal(object,field) end
 end
end
local function at(map,key)
 if not map then return nil end
 if type(map)=='table'then return map[key]end
 -- Reflected Java maps are opaque in the native Lua bridge.
 return nil
end
local function values(list)
 if not list then return {}end
 if type(list)=='table' and not list.size then return list end
 local out={};for i=0,list:size()-1 do out[#out+1]=list:get(i)end;return out
end
local function words(text)
 local out={};for id in tostring(text or ''):gmatch('[^;%s]+')do out[#out+1]=id end;return out
end
function D.optional(id)
 local name=id:lower()
 return Stock.optional(id) or name:find('steprail',1,true)~=nil or name:find('generator',1,true)~=nil
end
function D.scan(script,covered)
 local out,issues={},{}
 if not script.getPartCount then return out,issues end
 local probe
 local function definitions(part,id)
  if type(part)=='table' then
   local tables=D.field(part,'tables');return at(tables,'install'),at(tables,'uninstall')
  end
  -- Native VehiclePart exposes getTable; VehicleScript.Part.tables is an opaque
  -- HashMap. Build a detached probe only; never add, spawn or transmit it.
  if not probe then probe=BaseVehicle.new(getCell());probe:setScript(script:getFullName())end
  local native=probe:getPartById(id)
  if native then return native:getTable('install'),native:getTable('uninstall')end
 end
 local parts={};for i=0,script:getPartCount()-1 do parts[#parts+1]=script:getPart(i)end
 table.sort(parts,function(a,b)return a:getId()<b:getId()end)
 for _,part in ipairs(parts)do
  local id=part:getId()
  if D.optional(id) and not covered[id] then
   local install,uninstall=definitions(part,id)
   local items=values(D.field(part,'itemType'))
   if not install or not uninstall then
    issues[#issues+1]=id..': no removable native install definition'
   elseif #items~=1 or D.field(part,'specificItem')==true or (part:getModelCount()>1 and D.field(part,'setAllModelsVisible')~=true) then
    issues[#issues+1]=id..': multiple/unknown item mappings; compatibility mapping needed'
   else
    local item=items[1];local manager=getScriptManager()
    if type(item)=='string' and manager:FindItem(item) then
     local models={};for i=0,part:getModelCount()-1 do models[#models+1]=part:getModel(i):getId()end
     local label=getTextOrNull and getTextOrNull('IGUI_VehiclePart'..id)
     local itemScript=manager:FindItem(item)
     label=label or (itemScript.getDisplayName and itemScript:getDisplayName()) or id
     out[#out+1]={id='native:'..script:getFullName()..':'..id..':'..item,
      vehicle=script:getFullName(),label=label,price=0,discovered=true,
      effect='Native removable equipment: '..label..'. Uses the provider item and model unchanged; compatibility depends on its declared install rules.',
      requiredParts=words(at(install,'requireInstalled')),
      excludedParts=words(at(install,'requireUninstalled')),
      slots={{part=id,item=item,model=models[1] or false,models=models}}}
    else issues[#issues+1]=id..': required item is not loaded' end
   end
  end
 end
 return out,issues
end
return D
