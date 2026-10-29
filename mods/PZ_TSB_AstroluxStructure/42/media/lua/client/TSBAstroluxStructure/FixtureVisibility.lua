local Cutaway=require 'AstroluxBayTest/ExteriorCutaway'
local Sites=require 'TSBAstroluxStructure/ReleaseSites'
local M={}
function M.visible(sq,p)
 if not sq or not p or p:getZ()~=sq:getZ()or not sq:isCouldSee(0)then return false end
 local origin=IsoUtils.YToScreen(0,0,0,0)
 local diagonal=IsoUtils.YToScreen(1,1,0,0)-origin
 local rise=origin-IsoUtils.YToScreen(0,0,1,0)
 if diagonal<=0 or rise<=0 then return false end
 local function uncovered(r)
  if not r or not r.x or not r.y then return true end
  if sq:getX()<r.x or sq:getX()>=r.x+12 or sq:getY()<r.y or sq:getY()>=r.y+12 then return true end
  -- The decorative tower is UI-rendered and absent from native line of sight.
  -- Its interior artwork may emit only while that tower is cut away.
  return Cutaway.hidesPlayer(p:getX(),p:getY(),p:getZ(),r.x,r.y,12,rise/diagonal)
 end
 for _,r in ipairs(Sites.all())do if r.status=='ready'and not uncovered(r)then return false end end
 local demo=ModData.get('TSBAstroluxCombined12.v1')
 if demo and demo.ready and not uncovered(demo)then return false end
 return true
end
return M
