-- Manual sink placement/rotation must commit the selected preview direction.
-- Native default placement otherwise silently turns it to match the counter.
local function install()
 local P=ISMoveableSpriteProps
 if not P then return false end
 if P.TSBAstroluxSinkFacing then return true end
 for _,name in ipairs({'placeMoveableViaCursor','rotateMoveableViaCursor'})do
  local apply=P[name]
  P[name]=function(self,character,square,original,cursor)
   if not cursor or not self.spriteName or not self.spriteName:match('^fixtures_sinks_') or not self:hasFaces()then
    return apply(self,character,square,original,cursor)
   end
   local previous=self.ignoreSurfaceSnap
   self.ignoreSurfaceSnap=true
   local ok,result=pcall(apply,self,character,square,original,cursor)
   self.ignoreSurfaceSnap=previous
   if not ok then error(result,0)end
   return result
  end
 end
 P.TSBAstroluxSinkFacing=true
 return true
end
local done=false
Events.OnGameStart.Add(function()done=install()end)
Events.OnTick.Add(function()if not done then done=install()end end)
