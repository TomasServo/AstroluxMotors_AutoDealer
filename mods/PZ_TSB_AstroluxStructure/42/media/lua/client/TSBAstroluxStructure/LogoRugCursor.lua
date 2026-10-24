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
    -- Match native renderSpriteGrid's origin, including rotated dimensions.
    local x=self.currentSquare:getX()-originalGrid:getSpriteGridPosX(self.origMoveProps.sprite)
    local y=self.currentSquare:getY()-originalGrid:getSpriteGridPosY(self.origMoveProps.sprite)
    return x+currentGrid:getWidth()/2,y+currentGrid:getHeight()/2
   end
  end
  return original(self,...)
 end
 ISMoveableCursor.TSBAstroluxLogoRugCenter=true
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
