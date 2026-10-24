-- Keep an explicit drag direction across invalid previews and square changes.
-- Native sprite selection, placement checks and timed actions remain in charge.
local names={}
for i=4,11 do names['furniture_seating_indoor_02_'..i]=true end
for i=32,35 do names['lighting_indoor_02_'..i]=true end
local function install()
 local C=ISMoveableCursor
 if not C then return false end
 if C.TSBAstroluxFurnitureFacing then return true end
 local rotate=C.rotateMouse
 C.rotateMouse=function(self,...)
  local p=self.currentMoveProps
  local original=self.origSpriteName
  local mode=C.mode[self.player]
  local target=(mode=='place' or mode=='rotate') and p and (names[p.spriteName] or (p.isMoveable and p.isoType=="IsoMannequin"))
  local previous=target and self.cursorFacing
  local result=rotate(self,...)
  if target then
   local face=self.cursorFacing or previous
   if face and face>0 and original then
    self.cursorFacing=face
    self.TSBAstroluxFurnitureFacingChoice={original=original,face=face,mode=mode,
     object=mode=='rotate' and self.objectListCache and self.objectListCache.object}
   end
  end
  return result
 end
 local validate=C.isValid
 C.isValid=function(self,square,...)
  local mode=C.mode[self.player]
  if self.TSBAstroluxFurnitureFacingChoice and self.TSBAstroluxFurnitureFacingChoice.mode~=mode then
   self.TSBAstroluxFurnitureFacingChoice=nil
  end
  local choice=self.TSBAstroluxFurnitureFacingChoice
  -- Validate first to discover the selected inventory object. Never apply a
  -- previous object's facing to a different selection or bypass validity.
  local result=validate(self,square,...)
  if choice and square and self.origSpriteName then
   local sameObject=mode~='rotate' or (choice.object and self.objectListCache and self.objectListCache.object==choice.object)
   if self.origSpriteName~=choice.original or not sameObject then
    self.TSBAstroluxFurnitureFacingChoice=nil
   elseif self.cursorFacing~=choice.face then
    self.cursorFacing=choice.face
    result=validate(self,square,...)
   end
  end
  return result
 end
 local create=C.create
 C.create=function(self,...)
  local result=create(self,...)
  self.TSBAstroluxFurnitureFacingChoice=nil
  return result
 end
 local deactivate=C.deactivate
 C.deactivate=function(self,...)
  self.TSBAstroluxFurnitureFacingChoice=nil
  return deactivate(self,...)
 end
 C.TSBAstroluxFurnitureFacing=true
 return true
end
local done=false
Events.OnGameStart.Add(function()done=install()end)
Events.OnTick.Add(function()if not done then done=install()end end)
