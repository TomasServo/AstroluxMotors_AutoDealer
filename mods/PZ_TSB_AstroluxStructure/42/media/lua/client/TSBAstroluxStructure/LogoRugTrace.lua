-- Temporary, debug-only tracing. Does not alter placement decisions or artwork.
local function rug(name)
 return type(name)=='string' and name:match('^TSBAstroluxLogoRug_%d+$')~=nil
end
local function log(message)
 if getDebug() then print('[Astrolux Rug Trace v1] '..message) end
end
local function desc(p)
 if not p then return 'nil' end
 return tostring(p.spriteName)..' facing='..tostring(p.facing)..' index='..tostring(p:getFaceIndex())
end
local function location(x,y,z)return tostring(x)..','..tostring(y)..','..tostring(z)end
local function install()
 local C,A,P=ISMoveableCursor,ISMoveablesAction,ISMoveableSpriteProps
 if not C or not A or not P then return false end
 if not C.TSBAstroluxRugTrace then
  local render=C.renderSpriteGrid
  C.renderSpriteGrid=function(self,x,y,z,...)
   local p=self.currentMoveProps
   if p and rug(p.spriteName) then
    local state=location(x,y,z)..' preview='..desc(p)..' cursor='..tostring(self.cursorFacing)..' original='..tostring(self.origSpriteName)
    if self.TSBAstroluxLastRugTrace~=state then
     log(state);self.TSBAstroluxLastRugTrace=state
    end
   end
   return render(self,x,y,z,...)
  end
  local create=C.create
  C.create=function(self,x,y,z,...)
   if self.currentMoveProps and rug(self.currentMoveProps.spriteName) then
    log('CREATE '..location(x,y,z)..' '..desc(self.currentMoveProps)..' cursor='..tostring(self.cursorFacing)..' latch='..tostring(self.TSBAstroluxRugPreview and self.TSBAstroluxRugPreview.face))
   end
   return create(self,x,y,z,...)
  end
  C.TSBAstroluxRugTrace=true
 end
 if not A.TSBAstroluxRugTrace then
  local new=A.new
  A.new=function(self,character,square,mode,orig,object,direction,item,cursor)
   local action=new(self,character,square,mode,orig,object,direction,item,cursor)
   if rug(orig) then log('ACTION '..tostring(mode)..' requested='..tostring(direction)..' item='..tostring(item and item:getWorldSprite())..' resolved='..desc(action and action.moveProps)) end
   return action
  end
  local complete=A.complete
  A.complete=function(self,...)
   if rug(self.origSpriteName) then log('COMPLETE '..tostring(self.mode)..' '..desc(self.moveProps)) end
   return complete(self,...)
  end
  A.TSBAstroluxRugTrace=true
 end
 if not P.TSBAstroluxRugTrace then
  local place=P.placeMoveableInternal
  P.placeMoveableInternal=function(self,character,square,item,sprite,...)
   local obj=place(self,character,square,item,sprite,...)
   if rug(sprite) then
    local actual=obj and obj:getSprite()
    log('TILE '..location(square:getX(),square:getY(),square:getZ())..' requested='..sprite..' actual='..tostring(actual and actual:getName()))
   end
   return obj
  end
  P.TSBAstroluxRugTrace=true
 end
 log('installed; preview latch='..tostring(C.TSBAstroluxRugPreviewLatch))
 return true
end
local done=false
Events.OnGameStart.Add(function()if getDebug() then done=install() end end)
local ticks=0
Events.OnTick.Add(function()
 if done or not getDebug() then return end
 ticks=ticks+1;if ticks<60 then return end;ticks=0;done=install()
end)
