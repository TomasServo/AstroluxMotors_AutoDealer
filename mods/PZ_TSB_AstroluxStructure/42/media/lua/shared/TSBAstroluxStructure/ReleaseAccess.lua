local M={}
function M.allowed(p)
 if not p or p:isDead()then return false end
 if not isClient()and not isServer()then return true end
 return tostring(p:getAccessLevel()):lower()=='admin'
end
return M
