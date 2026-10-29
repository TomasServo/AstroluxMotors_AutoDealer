-- Eight-direction rotation for existing Astrolux showroom mannequins.
-- Keep direction separate from vanilla's four sprite-facing indexes.
local M=require 'TSBAstroluxStructure/MannequinDirections'
local names={'N','NW','W','SW','S','SE','E','NE'}
local function object(c)
 if ISMoveableCursor.mode[c.player]~='rotate' then return nil end
 local o=c.objectListCache and c.objectListCache.object
 return M.showroom(o) and o or nil
end
local function choice(c)
 local v=c.TSBAstroluxMannequinChoice
 if not v then return nil end
 local selected=c.objectListCache and c.objectListCache.object
 if ISMoveableCursor.mode[c.player]~='rotate' or not M.showroom(v.object)
  or (selected and selected~=v.object) then
  c.TSBAstroluxMannequinChoice=nil;return nil
 end
 -- Native click validation temporarily clears its selection cache.
 -- Keep the choice bound to its original object until selection is resolved.
 return v
end
local function set(c,o,name)
 c.TSBAstroluxMannequinChoice={object=o,name=name}
 -- A valid native facing keeps the timed-action path enabled. The actual
 -- direction is captured separately and never passed to a four-entry table.
 c.cursorFacing=1
end
local function install()
 local C,A=ISMoveableCursor,ISMoveablesAction
 if not C or not A then return false end
 if C.TSBAstroluxEightDirections then return true end
 local mouse=C.rotateMouse
 C.rotateMouse=function(c,...)
  local o=object(c)
  if not o or not c.currentSquare then return mouse(c,...)end
  local x=screenToIsoX(c.player,getMouseX(),getMouseY(),c.currentSquare:getZ())
  local y=screenToIsoY(c.player,getMouseX(),getMouseY(),c.currentSquare:getZ())
  local cx,cy=c:getCenterOfRotation();x=x-cx;y=y-cy
  if x*x+y*y<0.5 then return end
  local best,score
  for _,name in ipairs(names)do
   local d=IsoDirections[name];local dx,dy=d:dx(),d:dy()
   local dot=(x*dx+y*dy)/math.sqrt(dx*dx+dy*dy)
   if not score or dot>score then best=name;score=dot end
  end
  set(c,o,best)
 end
 local key=C.rotateKey
 C.rotateKey=function(c,k,joy,...)
  local o=object(c)
  if not o or c.isLeftDown or not (joy or getCore():isKey(KeybindId.ROTATE_BUILDING,k))then return key(c,k,joy,...)end
  local v=choice(c);local dir=v and IsoDirections[v.name] or o:getDir();local index=1
  for i,name in ipairs(names)do if IsoDirections[name]==dir then index=i;break end end
  set(c,o,names[index%8+1])
  getSoundManager():playUISound('UIObjectMenuObjectRotateOutline')
 end
 local render=C.renderObjectThatCanRotate
 C.renderObjectThatCanRotate=function(c,x,y,z,indicator,...)
  local v=choice(c)
  if not v then return render(c,x,y,z,indicator,...)end
  local dir=IsoDirections[v.name]
  IsoMannequin.renderMoveableObject(v.object,x,y,z,dir)
  if indicator then local cx,cy=c:getCenterOfRotation();c:renderRotateIndicator(cx,cy,z,dir)end
  return true
 end
 local same=C.isFacingOriginalDirection
 C.isFacingOriginalDirection=function(c,...)
  local v=choice(c)
  if v then return v.object:getDir()==IsoDirections[v.name]end
  return same(c,...)
 end
 -- Capture and commit before vanilla click validation rebuilds/clears its
 -- four-facing cursor state. Rotation changes no inventory and needs no timer.
 local create=C.create
 C.create=function(c,x,y,z,...)
  local v=choice(c)
  if v then
   local sq=v.object:getSquare()
   if sq and sq:getX()==x and sq:getY()==y and sq:getZ()==z then
    local ok=M.rotate(c.character,v.object,v.name)
    if ok then
     c.TSBAstroluxMannequinChoice=nil;c.cursorFacing=nil;c.joypadFacing=nil;c.objectListCache=nil
    else c.character:Say('Stand beside the showroom mannequin to rotate it.')end
    return
   end
  end
  return create(c,x,y,z,...)
 end
 local new=A.new
 A.new=function(class,character,square,mode,sprite,o,direction,item,c,...)
  local a=new(class,character,square,mode,sprite,o,direction,item,c,...)
  local v=c and choice(c)
  if mode=='rotate' and v and v.object==o then
   a.TSBAstroluxMannequinObject=o;a.TSBAstroluxMannequinDirection=v.name
  end
  return a
 end
 local complete=A.complete
 A.complete=function(a,...)
  if a.TSBAstroluxMannequinDirection then
   if not a:isValid()then return false end
   return M.rotate(a.character,a.TSBAstroluxMannequinObject,a.TSBAstroluxMannequinDirection)
  end
  return complete(a,...)
 end
 local deactivate=C.deactivate
 C.deactivate=function(c,...)
  c.TSBAstroluxMannequinChoice=nil
  return deactivate(c,...)
 end
 C.TSBAstroluxEightDirections=true
 return true
end
local done=false
Events.OnGameStart.Add(function()done=install()end)
Events.OnTick.Add(function()if not done then done=install()end end)
return {install=install}
