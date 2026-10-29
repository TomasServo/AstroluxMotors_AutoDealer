local M={}
function M.all()
 if isClient()then return TSBAstroluxReleaseSites or {}end
 local out={}
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do if r.releaseTower then out[#out+1]=r end end
 return out
end
function M.near(p)
 if not p then return end
 for _,r in ipairs(M.all())do
  if r.status=='ready'and p:getZ()==0 and p:getX()>=r.x-3 and p:getX()<=r.x+15 and p:getY()>=r.y-3 and p:getY()<=r.y+15 then return r end
 end
end
return M
