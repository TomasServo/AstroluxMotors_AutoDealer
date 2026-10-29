-- Native BuildingObjects classes may load after client modules.
-- Rug-specific placement presentation; native validation/placement/pickup stay intact.
local function install()
 if not ISMoveableCursor or type(ISMoveableCursor.getCenterOfRotation)~='function'then return false end
 if not ISMoveableCursor.TSBAstroluxLogoRugCenter then
 local original=ISMoveableCursor.getCenterOfRotation
 ISMoveableCursor.getCenterOfRotation=function(self,...)
  local props=self.currentMoveProps
  local sprite=props and props.sprite
  local name=sprite and sprite:getName()
  if ISMoveableCursor.mode[self.player]=='place' and type(name)=='string'
   and name:match('^TSBAstroluxLogoRug_%d+$') and self.currentSquare
   and self.origMoveProps and self.origMoveProps.sprite then
   local currentGrid=sprite:getSpriteGrid()
   local originalGrid=self.origMoveProps.sprite:getSpriteGrid()
   if currentGrid and originalGrid then
    -- Keep the mouse pivot fixed while the selected footprint rotates.
    local x=self.currentSquare:getX()-originalGrid:getSpriteGridPosX(self.origMoveProps.sprite)
    local y=self.currentSquare:getY()-originalGrid:getSpriteGridPosY(self.origMoveProps.sprite)
    return x+originalGrid:getWidth()/2,y+originalGrid:getHeight()/2
   end
  end
  return original(self,...)
 end
 ISMoveableCursor.TSBAstroluxLogoRugCenter=true
end

 if not ISMoveableCursor.TSBAstroluxRugPreviewLatch then
  local C=ISMoveableCursor
  local function placing(self)
   local p=self.currentMoveProps
   return C.mode[self.player]=='place' and p and type(p.spriteName)=='string'
    and p.spriteName:match('^TSBAstroluxLogoRug_%d+$')~=nil
  end
  local rotate=C.rotateMouse
  C.rotateMouse=function(self,...)
   local rug=placing(self)
   local previous=rug and (self.cursorFacing or self.currentMoveProps:getFaceIndex())
   local result=rotate(self,...)
   -- Native neutral-zone handling clears the direction. Keep the chosen rug facing.
   if rug and not self.cursorFacing and previous and previous>0 then self.cursorFacing=previous end
   return result
  end
  local render=C.renderSpriteGrid
  C.renderSpriteGrid=function(self,x,y,z,...)
   if placing(self) then
    self.TSBAstroluxRugPreview={x=x,y=y,z=z,face=self.currentMoveProps:getFaceIndex(),original=self.origSpriteName}
   else self.TSBAstroluxRugPreview=nil end
   return render(self,x,y,z,...)
  end
  local validate=C.isValid
  C.isValid=function(self,square,...)
   local preview=self.TSBAstroluxRugPreview
   local restore=C.mode[self.player]=='place' and not self.cursorFacing and square
    and preview and preview.face>0 and square:getX()==preview.x
    and square:getY()==preview.y and square:getZ()==preview.z
   if restore then self.cursorFacing=preview.face end
   local result=validate(self,square,...)
   if restore and self.origSpriteName~=preview.original then
    -- A different inventory item must not inherit the rug's facing.
    self.cursorFacing=nil;self.TSBAstroluxRugPreview=nil
    return validate(self,square,...)
   end
   if C.mode[self.player]~='place' then self.TSBAstroluxRugPreview=nil end
   return result
  end
  local create=C.create
  C.create=function(self,x,y,z,...)
   local preview=self.TSBAstroluxRugPreview
   if placing(self) and preview and preview.x==x and preview.y==y and preview.z==z
    and preview.original==self.origSpriteName and preview.face>0 then
    -- cannotCreate revalidates. Supply the displayed facing before that validation
    -- and before the native timed action copies its direction.
    self.cursorFacing=preview.face
   end
   self.TSBAstroluxRugPreview=nil
   return create(self,x,y,z,...)
  end
  C.TSBAstroluxRugPreviewLatch=true
 end
 return true
end
local installed=install()
Events.OnGameStart.Add(function()installed=install()end)
local ticks=0
Events.OnTick.Add(function()
 if installed then return end
 ticks=ticks+1;if ticks<60 then return end;ticks=0
 installed=install()
end)
