-- One-way sweep against the existing visual pane segments.
-- No square flags, objects, sprites, or map geometry are modified here.
local M = {maxStep=1.25, tolerance=0.01}
M.corners = {
    {name='NW', ax=0, ay=3, bx=3, by=0, flipX=false, flipY=false},
    {name='NE', ax=9, ay=0, bx=12, by=3, flipX=true, flipY=false},
    {name='SE', ax=12, ay=9, bx=9, by=12, flipX=true, flipY=true},
    {name='SW', ax=3, ay=12, bx=0, by=9, flipX=false, flipY=true},
}
for _, c in ipairs(M.corners) do
    local dx,dy=c.bx-c.ax,c.by-c.ay
    c.length=math.sqrt(dx*dx+dy*dy)
    c.ux,c.uy=dx/c.length,dy/c.length
    c.nx,c.ny=-c.uy,c.ux -- All normals point toward showroom center.
    c.windows={}
    -- Matches the accepted ReleaseCollision.plan; validation compares all 24.
    for n=0,2 do for _,north in ipairs({true,false}) do
        local x,y=north and n or 0,north and 0 or n
        local tx,ty=north and n or 2-n,north and 2-n or n
        if c.flipX then x=(north and 11 or 12)-x;tx=(north and 11 or 12)-tx end
        if c.flipY then y=(north and 12 or 11)-y;ty=(north and 12 or 11)-ty end
        c.windows[#c.windows+1]={x=x,y=y,tx=tx,ty=ty,north=north}
    end end
end

function M.distance(c,x,y)
    return (x-c.ax)*c.nx+(y-c.ay)*c.ny
end

-- Return the first safe point ON THE ALREADY-TRAVERSED movement segment.
-- Do not project sideways: that could put a player inside nearby furniture.
-- Starting in the exterior gap never ejects the player or prevents re-entry.
function M.clip(x0,y0,x1,y1,radius,active)
    local dx,dy=x1-x0,y1-y0
    if dx*dx+dy*dy > M.maxStep*M.maxStep then return x1,y1,nil end
    local first,which=1,nil
    for i,c in ipairs(M.corners) do if not active or active[i] then
        local d0,d1=M.distance(c,x0,y0),M.distance(c,x1,y1)
        if d0>=radius-M.tolerance and d1<radius and d1<d0-0.000001 then
            local t=math.max(0,math.min(1,(d0-radius)/(d0-d1)))
            local x,y=x0+dx*t,y0+dy*t
            local along=(x-c.ax)*c.ux+(y-c.ay)*c.uy
            -- The native straight walls handle the endpoints; no extended line.
            if along>=0 and along<=c.length and t<first then first,which=t,i end
        end
    end end
    return x0+dx*first,y0+dy*first,which
end
return M
