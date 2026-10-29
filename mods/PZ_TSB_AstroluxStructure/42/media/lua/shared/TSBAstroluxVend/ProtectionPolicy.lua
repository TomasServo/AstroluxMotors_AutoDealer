-- Explicit overrides of provider behavior. Native behavior is the default.
local P={}
function P.percent(n,default)
 if n==nil then return default end
 if type(n)~='number' or n~=n or n<0 or n>100 or n~=math.floor(n)then error('Protection settings require whole percentages from 0 to 100.',0)end
 return n
end
function P.read(p)
 p=p or {}
 if p.protectionOverride~=nil and type(p.protectionOverride)~='boolean'then error('Choose native protection or an admin override.',0)end
 if p.protectionOverride==true and (p.durabilityPercent==nil or p.protectionPercent==nil)then error('Enter both override percentages.',0)end
 return {protectionOverride=p.protectionOverride==true,durabilityPercent=P.percent(p.durabilityPercent,0),protectionPercent=P.percent(p.protectionPercent,100)}
end
return P
