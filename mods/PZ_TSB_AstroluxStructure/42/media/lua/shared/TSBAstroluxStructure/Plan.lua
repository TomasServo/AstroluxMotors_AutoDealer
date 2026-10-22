local P={size=8,levels=5,revision=1}
function P.plan(x,y)
    local p={x=x,y=y,size=P.size,levels=P.levels,objects={}}
    local function add(kind,dx,dy,z,sprite,north)
        p.objects[#p.objects+1]={kind=kind,x=x+dx,y=y+dy,z=z,sprite=sprite,north=north}
    end
    -- Keep the existing ground floor. Every upper deck and roof is a real floor.
    for z=1,P.levels do for dx=0,7 do for dy=0,7 do
        add('floor',dx,dy,z,'floors_interior_tilesandwood_01_0')
    end end end
    for z=0,P.levels-1 do
        for n=0,7 do
            for _,edge in ipairs({{n,0,true},{n,8,true},{0,n,false},{8,n,false}}) do
                local dx,dy,north=edge[1],edge[2],edge[3]
                if z==0 and n==3 then
                    add('frame',dx,dy,z,'walls_commercial_01_'..(north and 9 or 8),north)
                    add('door',dx,dy,z,'fixtures_doors_01_'..(north and 41 or 40),north)
                else
                    add('window',dx,dy,z,'walls_commercial_01_'..(north and 1 or 0),north)
                end
            end
        end
        add('corner',8,8,z,'walls_commercial_01_2')
    end
    return p
end
return P
