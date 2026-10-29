require 'ISUI/ISWorldObjectContextMenu'
local Power=require 'TSBAstroluxStructure/FixturePower'
local original=ISWorldObjectContextMenu.doLightSwitchOption
function ISWorldObjectContextMenu.doLightSwitchOption(test,context,player)
 local o=ISWorldObjectContextMenu.fetchVars.lightSwitch
 local result=original(test,context,player)
 if Power.available(o)and not o:canSwitchLight()and not ISWorldObjectContextMenu.isSomethingTo(o,player)then
  if test then return true end
  local verb=getText(o:isActivated()and 'ContextMenu_Turn_Off'or 'ContextMenu_Turn_On')
  context:addGetUpOption(verb..': '..o:getTileName(),nil,ISWorldObjectContextMenu.onToggleLight,o,player)
 end
 return result
end
