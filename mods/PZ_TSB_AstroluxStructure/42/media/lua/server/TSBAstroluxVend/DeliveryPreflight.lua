-- Read definitions only: no vehicle creation, item creation, payment or save edits.
local Stock=require 'TSBAstroluxVend/Stock'
local Accessories=require 'TSBAstroluxVend/Accessories'
local Equipment=require 'TSBAstroluxVend/Equipment'
local Paint=require 'TSBAstroluxVend/Paint'
local Adapters=require 'TSBAstroluxVend/VehicleAdapters'
local M={}
function M.verify(order,manager)
 local script=manager:getVehicle(order.script)
 if not script then error('Vehicle definition unavailable: '..tostring(order.script),0)end
 Accessories.verify(order.camperTop,script)
 local selected=Equipment.selection(order.equipment,script,order.camperTop)
 local choices=Equipment.parts(script,selected)
 Paint.verify(order.paint,script)
 local parts={}
 for i=0,script:getPartCount()-1 do local p=script:getPart(i);parts[p:getId()]=p end
 local function verify(id,item,model,models)
  local part=parts[id]
  if not part then error('Delivery configuration needs missing part: '..id,0)end
  if not item or not manager:FindItem(item)then error('Delivery equipment item unavailable: '..tostring(item),0)end
  if model and not part:getModelById(model)then error('Delivery equipment model unavailable: '..id..' / '..model,0)end
  for _,name in ipairs(models or {})do
   if not part:getModelById(name)then error('Delivery equipment model unavailable: '..id..' / '..name,0)end
  end
 end
 -- Explicit adapter stock declarations must still exist after vehicle-mod updates.
 local adapter=Adapters.get(script:getFullName())
 for id in pairs(adapter and adapter.stock or {})do
  if not parts[id]then error('Stock delivery part unavailable: '..id,0)end
 end
 for id,part in pairs(parts)do
  local choice=choices[id]
  local item,model=Stock.choice(script:getFullName(),id)
  if choice then verify(id,choice.item,choice.model,choice.models)
  elseif order.camperTop and id==Accessories.part then verify(id,Accessories.item,Accessories.model)
  elseif item then verify(id,item,model)end
 end
 for id,choice in pairs(choices)do
  if not parts[id]then error('Selected delivery part unavailable: '..id,0)end
 end
 return true
end
return M
