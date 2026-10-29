-- UI frame strokes render after native art. Clip their centerlines around the
-- actual rendered posts; absent/occupied joints keep their original glass frame.
local L=require 'AstroluxDiagonalLab/GirderLayout'
local C={}
function C.boxes(posts,project)
 local boxes={}
 for _,p in pairs(posts)do
  -- Footing follows world X/Y; shaft and top cap retain the glass-joint angle.
  for index,section in ipairs({{.34,0,.055},{.158,.055,L.height-.016},{.18,L.height-.016,L.height}})do
   local angle=index==1 and 0 or math.rad(22.5+45*p[3]);local cs,sn=math.cos(angle),math.sin(angle)
   local b={math.huge,math.huge,-math.huge,-math.huge}
   for _,z in ipairs({section[2],section[3]})do for _,x in ipairs({-section[1]/2,section[1]/2})do for _,y in ipairs({-section[1]/2,section[1]/2})do
    local sx,sy=project({p[1]+x*cs-y*sn,p[2]+x*sn+y*cs,z})
    b[1]=math.min(b[1],sx);b[2]=math.min(b[2],sy);b[3]=math.max(b[3],sx);b[4]=math.max(b[4],sy)
   end end end
   boxes[#boxes+1]=b
  end
 end
 return boxes
end
function C.parts(ax,ay,bx,by,boxes,padding)
 local dx,dy=bx-ax,by-ay;local parts={{0,1}}
 for _,b in ipairs(boxes)do
  local lo,hi=0,1
  for axis=1,2 do
   local origin=axis==1 and ax or ay;local delta=axis==1 and dx or dy
   local mn,mx=b[axis]-padding,b[axis+2]+padding
   if math.abs(delta)<1e-9 then
    if origin<mn or origin>mx then hi=-1;break end
   else
    local a,c=(mn-origin)/delta,(mx-origin)/delta
    if a>c then a,c=c,a end
    lo=math.max(lo,a);hi=math.min(hi,c)
   end
  end
  if hi>lo then
   local nextParts={}
   for _,range in ipairs(parts)do
    if hi<=range[1] or lo>=range[2]then nextParts[#nextParts+1]=range
    else
     if lo>range[1]then nextParts[#nextParts+1]={range[1],lo}end
     if hi<range[2]then nextParts[#nextParts+1]={hi,range[2]}end
    end
   end
   parts=nextParts
  end
 end
 return parts
end
return C
