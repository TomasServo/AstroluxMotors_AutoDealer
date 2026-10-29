-- Conservative projected bounds of the decorative upper tower only.
-- Native isometric screen rays advance equally along X/Y while rising in Z.
-- Camera offset and zoom cancel, so this check needs no per-frame projections.
local M={}
function M.hidesPlayer(px,py,pz,x,y,size,runPerLevel)
 if pz~=0 then return false end
 if px>=x and px<x+size and py>=y and py<y+size then return true end
 -- Intersect a ray toward the camera with the tower's horizontal footprint.
 local enter=math.max(0,x-px,y-py)
 local leave=math.min(x+size-px,y+size-py)
 if leave<=enter then return false end
 -- Upper structure begins at level 1. Include the player's torso/head up to
 -- .75 levels and the rooftop condenser up to 5.23. Front-side players have
 -- a negative leave distance and cannot trigger this exterior cutaway.
 return leave>runPerLevel*.25 and enter<runPerLevel*5.23
end
return M
