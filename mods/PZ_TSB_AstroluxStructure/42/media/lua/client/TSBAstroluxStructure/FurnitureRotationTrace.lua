local names={}
for i=4,11 do names['furniture_seating_indoor_02_'..i]=true end
for i=32,35 do names['lighting_indoor_02_'..i]=true end
local function describe(self,phase)
 local p=self.currentMoveProps
 if not p or not (names[p.spriteName] or p.isoType=="IsoMannequin") then return end
 local faces=p:getIndexedFaces()
 local state=phase..' mode='..tostring(ISMoveableCursor.mode[self.player])..' sprite='..p.spriteName..' facing='..tostring(p.facing)..' hasFaces='..tostring(p:hasFaces())..' cursor='..tostring(self.cursorFacing)..' canCreate='..tostring(self.canCreate)..' faces='..table.concat(faces,',')
 self.TSBAstroluxFurnitureTrace=self.TSBAstroluxFurnitureTrace or {}
 if self.TSBAstroluxFurnitureTrace[phase]~=state then
  self.TSBAstroluxFurnitureTrace[phase]=state
  print('[Astrolux Furniture Rotation] '..state)
 end
end
local function install()
 local C=ISMoveableCursor
 if not C then return false end
 if C.TSBAstroluxFurnitureRotationTrace then return true end
 local render=C.render
 C.render=function(self,...)
  describe(self,'preview');return render(self,...)
 end
 local rotate=C.rotateMouse
 C.rotateMouse=function(self,...)
  describe(self,'drag-before')
  local result=rotate(self,...)
  describe(self,'drag-after');return result
 end
 local create=C.create
 C.create=function(self,...)
  describe(self,'create-before')
  local result=create(self,...)
  describe(self,'create-after')
  return result
 end
 local P=ISMoveableSpriteProps
 if P then
  local apply=P.rotateMoveable
  P.rotateMoveable=function(self,character,square,original,...)
   local target=names[original] or self.isoType=="IsoMannequin"
   if target then print('[Astrolux Furniture Rotation] APPLY original='..original..' requested='..tostring(self.spriteName)) end
   local result=apply(self,character,square,original,...)
   if target then
    local objects=square:getObjects()
    for i=0,objects:size()-1 do
     local obj=objects:get(i)
     local sprite=obj:getSprite()
     local name=sprite and sprite:getName()
     if name and (names[name] or instanceof(obj,"IsoMannequin")) then print('[Astrolux Furniture Rotation] RESULT sprite='..name..' direction='..tostring(obj:getDir())) end
    end
   end
   return result
  end
 end
 C.TSBAstroluxFurnitureRotationTrace=true
 print('[Astrolux Furniture Rotation] trace installed')
 return true
end
local done=false
Events.OnGameStart.Add(function()if getDebug() then done=install() end end)
Events.OnTick.Add(function()if not done and getDebug() then done=install() end end)
