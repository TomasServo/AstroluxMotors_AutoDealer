-- Enable native rotation only for the four-facing Astrolux rug.
require 'Moveables/ISMoveableSpriteProps'
local P=ISMoveableSpriteProps
local function rug(self)
 local name=self.sprite and self.sprite:getName()
 return self.isMoveable and self.type=='FloorRug' and type(name)=='string'
  and name:match('^TSBAstroluxLogoRug_%d+$') and self:hasFaces()
end
if not P.TSBAstroluxRugRotation then
 local manual=P.canManuallyRotate
 P.canManuallyRotate=function(self,...)
  if rug(self)then return true end
  return manual(self,...)
 end
 local internal=P.canRotateMoveableInternal
 P.canRotateMoveableInternal=function(self,square,object,...)
  if rug(self)then
   self.yOffsetCursor=object and object:getRenderYOffset() or 0
   if object and (object:isSatChair() or not object:isObjectNoContainerOrEmpty())then return false end
   return true
  end
  return internal(self,square,object,...)
 end
 P.TSBAstroluxRugRotation=true
end
