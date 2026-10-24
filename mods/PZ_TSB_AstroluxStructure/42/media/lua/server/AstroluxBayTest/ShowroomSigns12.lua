local S=require 'TSBAstroluxStructure/EntranceSigns'
local original=S.plan
S.plan=function(r)
 if r.combinedSize~=12 then return original(r)end
 return {{x=r.x+5,y=r.y+12,z=0,sprite='TSBAstroluxEntranceSign_0'},
 {x=r.x+12,y=r.y+5,z=0,sprite='TSBAstroluxEntranceSign_1'}}
end
return S
