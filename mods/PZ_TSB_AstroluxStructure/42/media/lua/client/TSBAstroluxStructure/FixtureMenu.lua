require 'ISUI/ISWorldObjectContextMenu'
local Power=require 'TSBAstroluxStructure/FixturePower'
local original=ISWorldObjectContextMenu.doLightSwitchOption
function ISWorldObjectContextMenu.doLightSwitchOption(test,context,player)
 local o=ISWorldObjectContextMenu.fetchVars.lightSwitch
 local firstOption=context.numOptions
 local result=original(test,context,player)
 if Power.available(o)and not o:canSwitchLight()and not ISWorldObjectContextMenu.isSomethingTo(o,player)then
  if test then return true end
  local verb=getText(o:isActivated()and 'ContextMenu_Turn_Off'or 'ContextMenu_Turn_On')
  -- Put movable-lamp controls beside the native bulb controls. Pasted rooms
  -- use showroom power, so vanilla omits this entry from the lamp submenu.
  if Power.isTowerLamp(o)then
   for i=firstOption,context.numOptions-1 do
    local parent=context.options[i]
    if parent.name==o:getTileName()and parent.subOption then
     local submenu=context:getSubMenu(parent.subOption)
     if submenu then
      local option=submenu:addGetUpOption(verb,nil,ISWorldObjectContextMenu.onToggleLight,o,player)
      option.iconTexture=getTexture('Item_LightBulb')
      return result
     end
    end
   end
  end
  context:addGetUpOption(verb..': '..o:getTileName(),nil,ISWorldObjectContextMenu.onToggleLight,o,player)
 end
 return result
end
