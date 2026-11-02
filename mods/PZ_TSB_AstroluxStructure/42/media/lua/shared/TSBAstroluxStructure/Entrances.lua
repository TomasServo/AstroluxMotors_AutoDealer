local E={}
function E.plan(r)
    local result={}
    for _,edge in ipairs({'north','south','west','east'}) do
        local north=edge=='north' or edge=='south'
        local pair={edge=edge,north=north,leaves={}}
        for n=3,4 do
            pair.leaves[#pair.leaves+1]={x=r.x+(north and n or (edge=='east' and 8 or 0)),
                y=r.y+(north and (edge=='south' and 8 or 0) or n),base=(n==4 and 4 or 0)+(north and 1 or 0)}
        end
        result[#result+1]=pair
    end
    return result
end
function E.hit(r,x,y)
    for _,pair in ipairs(E.plan(r)) do
        local a=pair.leaves[1]
        local along=pair.north and x-a.x or y-a.y
        local across=pair.north and y-a.y or x-a.x
        if along>=0 and along<=2 and math.abs(across)<=0.45 then return pair end
    end
end
function E.screenHit(r,x,y,project)
    for _,pair in ipairs(E.plan(r)) do
        local a=pair.leaves[1]
        local ax,ay=project(a.x,a.y,0)
        local bx,by=project(a.x+(pair.north and 2 or 0),a.y+(pair.north and 0 or 2),0)
        local tx,ty=project(a.x,a.y,0.95)
        local ux,uy,vx,vy=bx-ax,by-ay,tx-ax,ty-ay
        local det=ux*vy-uy*vx
        if math.abs(det)>0.001 then
            local dx,dy=x-ax,y-ay
            local along=(dx*vy-dy*vx)/det
            local height=(ux*dy-uy*dx)/det
            if along>=0 and along<=1 and height>=0 and height<=1 then return pair end
        end
    end
end
return E
