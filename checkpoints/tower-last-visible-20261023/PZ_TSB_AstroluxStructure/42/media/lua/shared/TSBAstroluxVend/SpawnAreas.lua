-- New two-corner area model. No tower offsets, parking slots or painted bays.
local diagonal=math.sqrt(0.5)
local A={directions={'N','NE','E','SE','S','SW','W','NW'},
 labels={'North (N)','Northeast (NE)','East (E)','Southeast (SE)','South (S)','Southwest (SW)','West (W)','Northwest (NW)'},
 vectors={N={0,-1},NE={diagonal,-diagonal},E={1,0},SE={diagonal,diagonal},S={0,1},SW={-diagonal,diagonal},W={-1,0},NW={-diagonal,-diagonal}}}
local function coordinate(n)
    return type(n)=='number' and n==n and n==math.floor(n) and n>=-2147483646 and n<=2147483646
end
function A.spacing(value)
    if value==nil then return 0 end
    if type(value)~='number' or value~=value or value<0 or value==math.huge then return nil,'Use a finite non-negative car gap in tiles (decimals allowed).' end
    return value
end
function A.rectangle(ax,ay,bx,by,heading,gap)
    if not coordinate(ax) or not coordinate(ay) or not coordinate(bx) or not coordinate(by) then return nil,'Use whole native map coordinates.' end
    if not A.vectors[heading]then return nil,'Choose N, NE, E, SE, S, SW, W or NW.'end
    local spacing,why=A.spacing(gap);if spacing==nil then return nil,why end
    return {gap=spacing,x1=math.min(ax,bx),y1=math.min(ay,by),x2=math.max(ax,bx),y2=math.max(ay,by),heading=heading}
end
function A.dimensions(script,heading)
    if not script or not script:getModel() then error('Vehicle model unavailable.',0) end
    local e,o=script:getExtents(),script:getCenterOfMassOffset()
    local x,z,ox,oz=e:x(),e:z(),o:x(),o:z()
    for _,n in ipairs({x,z,ox,oz}) do
        if type(n)~='number' or n~=n or math.abs(n)==math.huge then error('Vehicle dimensions are invalid.',0) end
    end
    if x<=0 or z<=0 then error('Vehicle dimensions are invalid.',0) end
    -- Quarter-tile clearance on each side; no whole extra tile per vehicle.
    local rx,ry=x/2+math.abs(ox)+0.25,z/2+math.abs(oz)+0.25
    if not A.vectors[heading]then error('Invalid delivery direction.',0)end
    if heading=='E' or heading=='W' then return ry,rx end
    if #heading==2 then
        -- Axis-aligned envelope of the same padded footprint at 45 degrees.
        -- Reserve the full diagonal footprint, not the unrotated rectangle.
        local radius=(rx+ry)*diagonal
        return radius,radius
    end
    return rx,ry
end
function A.measure(script,heading)
    local rx,ry=A.dimensions(script,heading)
    -- Native debug creation centers the car in its selected tile. Include the
    -- center tile's half width before adding surrounding footprint tiles.
    return math.max(1,math.ceil(rx-0.5)),math.max(1,math.ceil(ry-0.5))
end
function A.contains(area,p)
    return p and p.heading==area.heading and p.x-p.rx>=area.x1 and p.x+p.rx<=area.x2
        and p.y-p.ry>=area.y1 and p.y+p.ry<=area.y2
end
local function hull(points)
 table.sort(points,function(a,b)return a.x<b.x or (a.x==b.x and a.y<b.y)end)
 local function cross(a,b,c)return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)end
 local lo,hi={},{}
 for _,p in ipairs(points)do while #lo>=2 and cross(lo[#lo-1],lo[#lo],p)<=0 do table.remove(lo)end;lo[#lo+1]=p end
 for i=#points,1,-1 do local p=points[i];while #hi>=2 and cross(hi[#hi-1],hi[#hi],p)<=0 do table.remove(hi)end;hi[#hi+1]=p end
 table.remove(lo);table.remove(hi);for _,p in ipairs(hi)do lo[#lo+1]=p end;return lo
end
function A.footprint(script,heading,x,y)
 local rx,ry=A.dimensions(script,'N');rx,ry=rx-.25,ry-.25
 local d=A.vectors[heading];local points={}
 for _,v in ipairs({{-1,-1},{1,-1},{1,1},{-1,1}})do
  points[#points+1]={x=x+v[1]*rx*(-d[2])+v[2]*ry*d[1],y=y+v[1]*rx*d[1]+v[2]*ry*d[2]}
 end
 return points
end
local function polygonOverlap(a,b,gap)
 local separated=false
 for _,poly in ipairs({a,b})do for i,p in ipairs(poly)do
  local q=poly[i%#poly+1];local nx,ny=q.y-p.y,p.x-q.x
  local amin,amax,bmin,bmax=math.huge,-math.huge,math.huge,-math.huge
  for _,v in ipairs(a)do local n=v.x*nx+v.y*ny;amin,amax=math.min(amin,n),math.max(amax,n)end
  for _,v in ipairs(b)do local n=v.x*nx+v.y*ny;bmin,bmax=math.min(bmin,n),math.max(bmax,n)end
  if amax<=bmin or bmax<=amin then separated=true end
 end end
 if not separated then return true end
 if gap<=0 then return false end
 local distance=math.huge
 for _,pair in ipairs({{a,b},{b,a}})do for _,p in ipairs(pair[1])do for i,v in ipairs(pair[2])do
  local w=pair[2][i%#pair[2]+1];local dx,dy=w.x-v.x,w.y-v.y
  local len=dx*dx+dy*dy
  local t=len>0 and math.max(0,math.min(1,((p.x-v.x)*dx+(p.y-v.y)*dy)/len)) or 0
  local ex,ey=p.x-v.x-t*dx,p.y-v.y-t*dy;distance=math.min(distance,ex*ex+ey*ey)
 end end end
 return distance+1e-8<gap*gap
end

function A.overlap(a,b)
    if a.footprint and b.footprint then return polygonOverlap(a.footprint,b.footprint,math.max(a.gap or 0,b.gap or 0))end
    -- Placement reservations contain inclusive tile indices; parked bounds are
    -- native world coordinates. Compare both in the same continuous space.
    local ax,ay,arx,ary=a.x,a.y,a.rx,a.ry
    local bx,by,brx,bry=b.x,b.y,b.rx,b.ry
    if not a.world then ax,ay,arx,ary=ax+0.5,ay+0.5,arx+0.5,ary+0.5 end
    if not b.world then bx,by,brx,bry=bx+0.5,by+0.5,brx+0.5,bry+0.5 end
    local gap=math.max(a.gap or 0,b.gap or 0)
    return ax-arx<bx+brx+gap and ax+arx+gap>bx-brx and ay-ary<by+bry+gap and ay+ary+gap>by-bry
end
function A.vehicleBounds(vehicle)
    local rx,ry=A.dimensions(vehicle:getScript(),'N')
    -- Use the same native local-to-world transform as vanilla vehicle entry.
    -- This avoids guessing the physics/world coordinate convention for yaw.
    if vehicle.getWorldPos and Vector3f then
        local point,out=Vector3f.new(),Vector3f.new()
        local e,o=vehicle:getScript():getExtents(),vehicle:getScript():getCenterOfMassOffset()
        local height,offset=e.y and e:y() or 0,o.y and o:y() or 0
        if type(height)~='number' or type(offset)~='number' or height~=height or offset~=offset or math.abs(height)==math.huge or math.abs(offset)==math.huge then
            error('Parked vehicle height is invalid.',0)
        end
        local hy=math.abs(height)/2+math.abs(offset)+0.25
        local points={}
        local x1,y1,x2,y2=math.huge,math.huge,-math.huge,-math.huge
        for _,x in ipairs({-rx,rx})do for _,y in ipairs({-hy,hy})do for _,z in ipairs({-ry,ry})do
            point:set(x,y,z);vehicle:getWorldPos(point,out)
            local wx,wy=out:x(),out:y()
            if type(wx)~='number' or type(wy)~='number' or wx~=wx or wy~=wy or math.abs(wx)==math.huge or math.abs(wy)==math.huge then
                error('Parked vehicle bounds are invalid.',0)
            end
            local point2,out2=Vector3f.new(),Vector3f.new()
            point2:set(x<0 and x+.25 or x-.25,y,z<0 and z+.25 or z-.25);vehicle:getWorldPos(point2,out2)
            local px,py=out2:x(),out2:y();if px~=px or py~=py or math.abs(px)==math.huge or math.abs(py)==math.huge then error('Invalid parked footprint.',0)end
            points[#points+1]={x=px,y=py}
            x1,y1,x2,y2=math.min(x1,wx),math.min(y1,wy),math.max(x2,wx),math.max(y2,wy)
        end end end
        return {x=(x1+x2)/2,y=(y1+y2)/2,rx=(x2-x1)/2,ry=(y2-y1)/2,world=true,footprint=hull(points)}
    end
    -- Older/missing transform API retains the previous conservative envelope.
    local radius=math.sqrt(rx*rx+ry*ry)
    return {x=vehicle:getX(),y=vehicle:getY(),rx=radius,ry=radius,world=true}
end
-- Iterate only streamed map intersections. Work never scales with the size of
-- an unloaded rectangle, even if its opposite corners span an entire map.
function A.find(area,rx,ry,regions,clear,shape)
    if area.x2-area.x1+1<rx*2+1 or area.y2-area.y1+1<ry*2+1 then
        return nil,'Selected vehicle does not fit this area. Enlarge it or choose a smaller vehicle.'
    end
    local seen={}
    local sx,sy=rx*2+1+math.ceil(area.gap or 0),ry*2+1+math.ceil(area.gap or 0)
    local originX,originY=area.x1+rx,area.y1+ry
    -- Prefer compact rows, then inspect every remaining integer center. A car
    -- moved half a bay must not hide a usable gap between the original grid.
    for pass=1,2 do for _,r in ipairs(regions) do
        local x1=math.max(area.x1+rx,r.x1+rx);local y1=math.max(area.y1+ry,r.y1+ry)
        local x2=math.min(area.x2-rx,r.x2-rx);local y2=math.min(area.y2-ry,r.y2-ry)
        local stepX,stepY=1,1
        if pass==1 then
            x1=originX+math.ceil((x1-originX)/sx)*sx
            y1=originY+math.ceil((y1-originY)/sy)*sy
            stepX,stepY=sx,sy
        end
        for y=y1,y2,stepY do for x=x1,x2,stepX do
            local key=x..':'..y
            if not seen[key] then
                seen[key]=true
                local p={x=x,y=y,rx=rx,ry=ry,heading=area.heading,areaRevision=area.revision,gap=area.gap or 0}
                if shape then p.footprint=shape(p)end
                if clear(p) then return p end
            end
        end end
    end end
    return nil,'No clear, loaded space fits this vehicle. Visit/load the spawn area and clear obstructions; no payment was taken.'
end
function A.reserve(area,rx,ry,blockers,shape)
    if area.x2-area.x1+1<rx*2+1 or area.y2-area.y1+1<ry*2+1 then return nil end
    local ox,oy=area.x1+rx,area.y1+ry
    local xs,ys={[ox]=true,[area.x2-rx]=true},{[oy]=true,[area.y2-ry]=true}
    -- Candidate edges depend on reservations/loaded regions, not map size.
    for _,b in ipairs(blockers) do
        xs[math.floor(b.x+b.rx+rx+math.max(area.gap or 0,b.gap or 0))+1]=true
        xs[math.ceil(b.x-b.rx-rx-math.max(area.gap or 0,b.gap or 0))-1]=true
        ys[math.floor(b.y+b.ry+ry+math.max(area.gap or 0,b.gap or 0))+1]=true
        ys[math.ceil(b.y-b.ry-ry-math.max(area.gap or 0,b.gap or 0))-1]=true
    end
    local xx,yy={},{};for x in pairs(xs) do xx[#xx+1]=x end;for y in pairs(ys) do yy[#yy+1]=y end
    table.sort(xx);table.sort(yy)
    for _,y in ipairs(yy) do for _,x in ipairs(xx) do
        local p={x=x,y=y,rx=rx,ry=ry,heading=area.heading,areaRevision=area.revision,gap=area.gap or 0,deferred=true}
        if shape then p.footprint=shape(p)end
        if A.contains(area,p) then
            local blocked=false
            for _,b in ipairs(blockers) do if A.overlap(p,b) then blocked=true;break end end
            if not blocked then return p end
        end
    end end
end
return A
