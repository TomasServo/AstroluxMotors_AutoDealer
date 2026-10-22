-- New two-corner area model. No tower offsets, parking slots or painted bays.
local A={directions={'N','E','S','W'}}
local function coordinate(n)
    return type(n)=='number' and n==n and n==math.floor(n) and n>=-2147483646 and n<=2147483646
end
function A.rectangle(ax,ay,bx,by,heading)
    if not coordinate(ax) or not coordinate(ay) or not coordinate(bx) or not coordinate(by) then return nil,'Use whole native map coordinates.' end
    if heading~='N' and heading~='E' and heading~='S' and heading~='W' then return nil,'Choose North, East, South or West.' end
    return {x1=math.min(ax,bx),y1=math.min(ay,by),x2=math.max(ax,bx),y2=math.max(ay,by),heading=heading}
end
function A.measure(script,heading)
    if not script or not script:getModel() then error('Vehicle model unavailable.',0) end
    local e,o=script:getExtents(),script:getCenterOfMassOffset()
    local x,z,ox,oz=e:x(),e:z(),o:x(),o:z()
    for _,n in ipairs({x,z,ox,oz}) do
        if type(n)~='number' or n~=n or math.abs(n)==math.huge then error('Vehicle dimensions are invalid.',0) end
    end
    if x<=0 or z<=0 then error('Vehicle dimensions are invalid.',0) end
    local rx,ry=math.max(1,math.ceil(x/2+math.abs(ox)+0.5)),math.max(1,math.ceil(z/2+math.abs(oz)+0.5))
    if heading=='E' or heading=='W' then return ry,rx end
    return rx,ry
end
function A.contains(area,p)
    return p and p.heading==area.heading and p.x-p.rx>=area.x1 and p.x+p.rx<=area.x2
        and p.y-p.ry>=area.y1 and p.y+p.ry<=area.y2
end
function A.overlap(a,b)
    return a.x-a.rx<=b.x+b.rx and a.x+a.rx>=b.x-b.rx and a.y-a.ry<=b.y+b.ry and a.y+a.ry>=b.y-b.ry
end
-- Iterate only streamed map intersections. Work never scales with the size of
-- an unloaded rectangle, even if its opposite corners span an entire map.
function A.find(area,rx,ry,regions,clear)
    if area.x2-area.x1+1<rx*2+1 or area.y2-area.y1+1<ry*2+1 then
        return nil,'Selected vehicle does not fit this area. Enlarge it or choose a smaller vehicle.'
    end
    local seen={}
    local sx,sy=rx*2+1,ry*2+1
    local originX,originY=area.x1+rx,area.y1+ry
    for _,r in ipairs(regions) do
        local x1=math.max(area.x1+rx,r.x1+rx);local y1=math.max(area.y1+ry,r.y1+ry)
        local x2=math.min(area.x2-rx,r.x2-rx);local y2=math.min(area.y2-ry,r.y2-ry)
        x1=originX+math.ceil((x1-originX)/sx)*sx
        y1=originY+math.ceil((y1-originY)/sy)*sy
        for y=y1,y2,sy do for x=x1,x2,sx do
            local key=x..':'..y
            if not seen[key] then
                seen[key]=true
                local p={x=x,y=y,rx=rx,ry=ry,heading=area.heading,areaRevision=area.revision}
                if clear(p) then return p end
            end
        end end
    end
    return nil,'No clear, loaded space fits this vehicle. Visit/load the spawn area and clear obstructions; no payment was taken.'
end
function A.reserve(area,rx,ry,blockers)
    if area.x2-area.x1+1<rx*2+1 or area.y2-area.y1+1<ry*2+1 then return nil end
    local sx,sy=rx*2+1,ry*2+1
    local ox,oy=area.x1+rx,area.y1+ry
    local xs,ys={[ox]=true},{[oy]=true}
    -- Candidate edges depend on reservations/loaded regions, not map size.
    for _,b in ipairs(blockers) do
        xs[ox+math.ceil((b.x+b.rx+rx+1-ox)/sx)*sx]=true
        ys[oy+math.ceil((b.y+b.ry+ry+1-oy)/sy)*sy]=true
    end
    local xx,yy={},{};for x in pairs(xs) do xx[#xx+1]=x end;for y in pairs(ys) do yy[#yy+1]=y end
    table.sort(xx);table.sort(yy)
    for _,y in ipairs(yy) do for _,x in ipairs(xx) do
        local p={x=x,y=y,rx=rx,ry=ry,heading=area.heading,areaRevision=area.revision,deferred=true}
        if A.contains(area,p) then
            local blocked=false
            for _,b in ipairs(blockers) do if A.overlap(p,b) then blocked=true;break end end
            if not blocked then return p end
        end
    end end
end
return A
