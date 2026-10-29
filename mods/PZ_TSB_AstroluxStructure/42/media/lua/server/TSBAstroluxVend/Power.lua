local Electricity=require 'TSBAstroluxStructure/Electricity'
-- Native square electricity only: no test batteries or visual glow as a proxy.
local P={}
P.message='Kiosk has no power. Purchase rejected; no order placed or payment taken.'
function P.available(t)
 if not t or t.packed then return false end
 local cell=getCell();local sq=cell and cell:getGridSquare(t.x,t.y,t.z or 0)
 if not sq then return false end
 return Electricity.square(sq)
end
function P.require(t)
 if not P.available(t) then error(P.message,0) end
end
return P
