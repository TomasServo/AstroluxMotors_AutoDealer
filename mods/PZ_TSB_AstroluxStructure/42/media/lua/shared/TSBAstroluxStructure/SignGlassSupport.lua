-- Extend native support lookup only; all tool, occupancy and placement checks remain native.
require 'Moveables/ISMoveableSpriteProps'
local P=ISMoveableSpriteProps
if not P.TSBAstroluxSignGlassSupport then
 local original=P.getWallForFacing
 P.getWallForFacing=function(self,square,dir,mode)
  local support=original(self,square,dir,mode)
  if support then return support end
  if self.type~='WallObject' or type(self.spriteName)~='string'
   or not self.spriteName:match('^TSBAstroluxMotorsSign_%d+$')
   or (mode and mode~='Wall' and mode~='WallAndDoor') then return end
  if dir=='N' then square=square and square:getTileInDirection(IsoDirections.S)
  elseif dir=='W' then square=square and square:getTileInDirection(IsoDirections.E)
  elseif dir~='S' and dir~='E' then return end
  if not square then return end
  local north=dir=='N' or dir=='S';local objects=square:getObjects()
  for i=0,objects:size()-1 do
   local o=objects:get(i);local sprite=o:getSprite();local name=sprite and sprite:getName()
   if instanceof(o,'IsoWindow') and o:getNorth()==north and name=='TSBAstroluxClearGlass_'..(north and 1 or 0)
    and not o:isDestroyed() and not o:isSmashed() and not o:isGlassRemoved() and not o:IsOpen() then
    local md=o:getModData()
    if md.TSBAstroluxStructure and (md.TSBAstroluxStructureKind=='window' or md.TSBAstroluxStructureKind=='entranceWindow') then return o end
   end
  end
 end
 P.TSBAstroluxSignGlassSupport=true
end
