-- Keep the current object's chosen direction through native click validation.
-- Native furniture validation, sprite grids and timed actions remain in charge.
local function target(p)
 return p and p.isMoveable and ((p:hasFaces() and (p.type=='Object' or p.type=='Vegitation'))
  or p:canRotateDirection())
end
local function selected(self,mode)
 local entries=self.objectListCache
 if not entries then return nil end
 if mode=='rotate' then return entries.object end
 local entry=entries[self.objectIndex];return entry and entry.object
end
local function remember(self,mode,face)
 local object=selected(self,mode)
 if object and self.origSpriteName and face and face>=1 and face<=4 then
  self.TSBAstroluxFurnitureFacingChoice={original=self.origSpriteName,face=face,mode=mode,object=object}
 end
end
local function clear(self)
 if self.TSBAstroluxFurnitureFacingChoice then self.cursorFacing=nil end
 self.TSBAstroluxFurnitureFacingChoice=nil
end
local function install()
 local C=ISMoveableCursor
 if not C then return false end
 if C.TSBAstroluxFurnitureFacing then return true end
 local rotate=C.rotateMouse
 C.rotateMouse=function(self,...)
  local mode=C.mode[self.player]
  local supported=(mode=='place' or mode=='rotate') and target(self.currentMoveProps)
  local previous=supported and self.cursorFacing
  local result=rotate(self,...)
  if supported then
   local face=self.cursorFacing or previous
   if face then self.cursorFacing=face;remember(self,mode,face)end
  end
  return result
 end
 local validate=C.isValid
 C.isValid=function(self,square,...)
  local mode=C.mode[self.player]
  local choice=self.TSBAstroluxFurnitureFacingChoice
  if choice and choice.mode~=mode then clear(self);choice=nil end
  -- Native validation discovers the actual selected inventory item/world object.
  local result=validate(self,square,...)
  if choice and square and self.origSpriteName then
   if self.origSpriteName~=choice.original or selected(self,mode)~=choice.object then
    clear(self);result=validate(self,square,...)
   elseif self.cursorFacing then
    -- A new drag or gamepad choice wins over the remembered direction.
    remember(self,mode,self.cursorFacing)
   else
    self.cursorFacing=choice.face;result=validate(self,square,...)
   end
  end
  return result
 end
 local key=C.rotateKey
 C.rotateKey=function(self,keyCode,joypad,...)
  local mode=C.mode[self.player]
  local supported=(mode=='place' or mode=='rotate') and target(self.currentMoveProps)
  local turning=supported and not self.isLeftDown and (joypad or getCore():isKey(KeybindId.ROTATE_BUILDING,keyCode))
  if turning then
   -- Native rotateKey refuses keyboard input while cursorFacing is set. A saved
   -- drag choice is not an active drag; let the next key start from the preview.
   if mode=='rotate' and self.currentMoveProps:hasFaces()then self.objectIndex=self.currentMoveProps:getFaceIndex()end
   clear(self);self.cursorFacing=nil
  end
  local result=key(self,keyCode,joypad,...)
  if turning and mode=='rotate' and self.currentSquare then
   self:isValid(self.currentSquare)
   if target(self.currentMoveProps) and self.currentMoveProps:hasFaces()then
    self.cursorFacing=self.currentMoveProps:getFaceIndex();remember(self,mode,self.cursorFacing)
   end
  end
  return result
 end
 local create=C.create
 C.create=function(self,x,y,z,...)
  local p=self.currentMoveProps;local sq=self.currentSquare;local mode=C.mode[self.player]
  if (mode=='place' or mode=='rotate') and target(p) and sq
   and sq:getX()==x and sq:getY()==y and sq:getZ()==z and selected(self,mode)then
   local face=p:canRotateDirection() and (self.cursorFacing or self.joypadFacing) or p:getFaceIndex()
   if face and face>0 then self.cursorFacing=face;remember(self,mode,face)end
  end
  local result=create(self,x,y,z,...)
  self.TSBAstroluxFurnitureFacingChoice=nil
  return result
 end
 local deactivate=C.deactivate
 C.deactivate=function(self,...)
  clear(self);return deactivate(self,...)
 end
 C.TSBAstroluxFurnitureFacing=true
 return true
end
local done=false
Events.OnGameStart.Add(function()done=install()end)
Events.OnTick.Add(function()if not done then done=install()end end)
