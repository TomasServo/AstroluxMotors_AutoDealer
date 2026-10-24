local E=require 'TSBAstroluxStructure/Entrances'
local original=E.plan
local function expanded(r)
    local result={}
    for _,edge in ipairs({'north','south','west','east'}) do
        local north=edge=='north' or edge=='south'
        local pair={edge=edge,north=north,leaves={}}
        for n=5,6 do
            pair.leaves[#pair.leaves+1]={x=r.x+(north and n or (edge=='east' and 12 or 0)),
                y=r.y+(north and (edge=='south' and 12 or 0) or n),base=(n==6 and 4 or 0)+(north and 1 or 0)}
        end
        result[#result+1]=pair
    end
    return result
end

E.plan=function(r) if r.combinedSize==12 then return expanded(r) end return original(r) end
return E
