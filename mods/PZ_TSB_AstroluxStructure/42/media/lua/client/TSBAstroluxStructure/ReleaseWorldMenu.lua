-- Use the native world-menu extension point, including empty-ground clicks.
local Placement=require 'TSBAstroluxStructure/ReleaseClient'
ISWorldMenuElements=ISWorldMenuElements or {}
function ISWorldMenuElements.AstroluxTowerPlacement()
 local self=ISMenuElement.new()
 self.zIndex=100
 function self.init()print('[Astrolux placement] Native world-menu element initialized.')end
 function self.createMenu(data)
  if getCore():getGameMode()=='Tutorial'then return end
  return Placement.addMenu(data.playerNum,data.context,data.test)
 end
 return self
end
return true
