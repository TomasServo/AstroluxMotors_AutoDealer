-- Private SP trial: one tile, the owned Dark Corner counter at local (0,8).
local M={maxStep=1.25,tolerance=0.01}
function M.clip(x0,y0,x1,y1,radius)
    local dx,dy=x1-x0,y1-y0
    if dx*dx+dy*dy>M.maxStep*M.maxStep then return x1,y1,false end
    local left,right,bottom,top=-radius,1+radius,8-radius,9+radius
    -- A load/toggle while overlapping must never trap or eject the player.
    if x0>left+M.tolerance and x0<right-M.tolerance
        and y0>bottom+M.tolerance and y0<top-M.tolerance then return x1,y1,false end
    local first,hit=1,false
    local function face(d0,d1)
        if d0< -M.tolerance or d1>=0 or d1>=d0-0.000001 then return end
        local t=math.max(0,math.min(1,d0/(d0-d1)))
        if t>=first then return end
        -- A point immediately after contact must enter both rectangle axes.
        -- This keeps tangential motion and corner-grazing paths unobstructed.
        local probe=math.min(1,t+0.00001)
        local x,y=x0+dx*probe,y0+dy*probe
        if x>left and x<right and y>bottom and y<top then first,hit=t,true end
    end
    face(left-x0,left-x1);face(x0-right,x1-right)
    face(bottom-y0,bottom-y1);face(y0-top,y1-top)
    return x0+dx*first,y0+dy*first,hit
end
return M
