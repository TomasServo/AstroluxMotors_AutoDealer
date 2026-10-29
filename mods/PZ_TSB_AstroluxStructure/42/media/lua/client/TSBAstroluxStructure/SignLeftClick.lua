-- Reuse native wall-edge access for Astrolux sign clicks on glass walls.
local M={}
function M.isSign(o)
 if not o or not instanceof(o,'IsoLightSwitch') then return false end
 local s=o:getSprite();local n=s and s:getName()
 return type(n)=='string' and n:match('^TSBAstroluxMotorsSign_[0-3]$')~=nil
end
function M.click(o,index,p)
 if not p or p:isDead() or p:isAiming() or p:isIgnoreContextKey() or not p:getCurrentSquare() then return false end
 local speed=UIManager.getSpeedControls();if speed and speed:getCurrentGameSpeed()==0 then return false end
 local sq=o:getSquare()
 if not sq or o:getObjectIndex()<0 or p:getZ()~=sq:getZ() or sq:DistToProper(p)>=2 then return false end
 if not o:canSwitchLight() then return false end
 -- Native onToggleLight uses attachedN/S/W/E and FindEdge, then queues the
 -- ordinary walk/toggle actions. No direct activation or wall bypass.
 ISWorldObjectContextMenu.onToggleLight(nil,o,index)
 if getDebug() then print('[Astrolux Sign Click] Native wall-edge toggle requested for '..o:getSprite():getName()) end
 return true
end
function M.install()
 local C=ISObjectClickHandler
 if not C or not C.doClickLightSwitch or not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.onToggleLight then return false end
 if C.TSBAstroluxSignEdgeClick then return true end
 local original=C.doClickLightSwitch
 C.doClickLightSwitch=function(o,index,p)
  if M.isSign(o) then return M.click(o,index,p) end
  return original(o,index,p)
 end
 C.TSBAstroluxSignEdgeClick=true;return true
end
local installed=false
Events.OnGameStart.Add(function()installed=M.install()end)
Events.OnTick.Add(function()if not installed then installed=M.install()end end)
return M
