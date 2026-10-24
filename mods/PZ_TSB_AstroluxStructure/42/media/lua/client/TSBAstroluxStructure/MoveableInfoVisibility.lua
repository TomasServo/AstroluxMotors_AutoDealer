-- Native furniture tooltip: transparent/pass-through UI must not hide it.
require 'ISUI/ISMoveableInfoWindow'
local M={}
function M.blocks(ui,panel)
 return ui~=panel.javaObject and ui:isVisible() and ui:isConsumeMouseEvents() and ui:isMouseOver()
end
function M.isMouseOverUI(self)
 local uis=UIManager.getUI()
 for i=0,uis:size()-1 do
  if M.blocks(uis:get(i),self)then return true end
 end
 return false
end
ISMoveableInfoWindow.isMouseOverUI=M.isMouseOverUI
Events.OnGameStart.Add(function()
 print('[Astrolux Pickup Panel] visibility correction loaded')
end)
local ticks=0;local previous
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or not getDebug() then return end
 local panel=ISMoveableInfoWindow.infoPanels and ISMoveableInfoWindow.infoPanels[0]
 if not panel or not panel.drag or not getCell() or getCell():getDrag(0)~=panel.drag then previous=nil;return end
 local state='position='..tostring(ISMoveableInfoWindow.displayPosition)
  ..' visible='..tostring(panel:getIsVisible())..' blocked='..tostring(panel.mouseOverUI)
  ..' body='..tostring(panel.bodyText~=nil)..' header='..tostring(panel.header~=nil)
  ..' footer='..tostring(panel.footer~=nil)..' size='..tostring(panel.width)..'x'..tostring(panel.height)
 if state~=previous then print('[Astrolux Pickup Panel] '..state);previous=state end
end)
return M
