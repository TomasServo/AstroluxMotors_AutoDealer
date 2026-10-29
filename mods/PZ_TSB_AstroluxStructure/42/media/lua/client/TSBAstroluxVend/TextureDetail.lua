-- Keep full source resolution in the texture while retaining native world size,
-- original floor anchor and the established low-resolution click masks.
local M={}
function M.apply()
 local ready=true
 for i=0,3 do
  local t=getTexture('TSBAstroluxKiosk_'..i)
  local donor=getTexture('TSBAstroluxKioskClickMask_'..i)
  if t and donor and donor:getMask() then
   t:setWidth(128);t:setHeight(256);t:setMask(donor:getMask())
  else ready=false end
 end
 for i=0,1 do
  local t=getTexture('TSBAstroluxKioskScreenOff_'..i)
  if t then t:setWidth(128);t:setHeight(256) else ready=false end
  local glow=getTexture('TSBAstroluxKioskGlow_'..i)
  if glow then glow:setWidth(128);glow:setHeight(256) else ready=false end
 end
 return ready
end
Events.OnGameBoot.Add(M.apply)
Events.OnGameStart.Add(M.apply)
return M
