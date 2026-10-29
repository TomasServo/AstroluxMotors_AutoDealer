local P={size=12,levels=1,maxZ=4,revision=3}
function P.openRoof(dx,dy)
 return (dx>=3 and dx<=8 and dy>=3 and dy<=8) or ((dx<3 or dx>=9) and (dy<3 or dy>=9))
end
function P.plan(x,y)
    local p={x=x,y=y,size=P.size,levels=P.levels,objects={}}
    local function add(kind,dx,dy,z,sprite,north)
        p.objects[#p.objects+1]={kind=kind,x=x+dx,y=y+dy,z=z,sprite=sprite,north=north}
    end
    -- Keep the existing ground floor. Keep a roof rim and native support floors beneath both display bays.
    for z=1,P.levels do for dx=0,11 do for dy=0,11 do
        if not P.openRoof(dx,dy) then add('floor',dx,dy,z,'floors_interior_tilesandwood_01_28') end
    end end end
    for z=0,P.levels-1 do
        for n=0,11 do
            for _,edge in ipairs({{n,0,true},{n,12,true},{0,n,false},{12,n,false}}) do
                local dx,dy,north=edge[1],edge[2],edge[3]
                -- Two centered tiles remain open for future sliding doors.
                if n~=5 and n~=6 then
                    add('window',dx,dy,z,'TSBAstroluxClearGlass_'..(north and 1 or 0),north)
                end
            end
        end
        add('corner',12,12,z,'TSBAstroluxClearGlass_3')
    end
    return p
end
return P



