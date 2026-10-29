local M={}
function M.apply()
 TSBAstroluxDiagonalGirderReady=false
 local manager=TileDepthTextureManager.getInstance()
 for i=0,3 do
  local name='TSBAstroluxDiagonalPillar_'..i
  local art=getTexture(name)
  local depth=manager:getTextureFromTileName('PZ_TSB_AstroluxStructure',name)
  assert(art and depth and not depth:isEmpty(),'Missing diagonal girder art/depth: '..name)
  local texture=depth:getTexture()
  texture:setOffsetX(art:getOffsetX());texture:setOffsetY(art:getOffsetY())
 end
 TSBAstroluxDiagonalGirderReady=true
 print('[Astrolux diagonal girders] Four art/depth registrations ready')
end
Events.OnGameStart.Add(M.apply)
return M
