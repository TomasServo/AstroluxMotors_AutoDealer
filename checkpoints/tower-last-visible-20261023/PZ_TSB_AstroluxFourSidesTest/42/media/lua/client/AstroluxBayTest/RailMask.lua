-- Clip a screen-space segment around an approximate standing-character silhouette.
-- The caller pads radii by half the rail width so its edges cannot cross the mask.
local M={}
function M.outside(ax,ay,bx,by,cx,cy,rx,ry)
 local x,y=(ax-cx)/rx,(ay-cy)/ry
 local dx,dy=(bx-ax)/rx,(by-ay)/ry
 local a=dx*dx+dy*dy
 if a<1e-12 then return {} end
 local b=2*(x*dx+y*dy);local c=x*x+y*y-1
 local disc=b*b-4*a*c
 if disc<=0 then return {{0,1}} end
 local root=math.sqrt(disc)
 local enter=math.max(0,(-b-root)/(2*a));local leave=math.min(1,(-b+root)/(2*a))
 if enter>=leave then return {{0,1}} end
 local result={}
 if enter>0 then result[#result+1]={0,enter} end
 if leave<1 then result[#result+1]={leave,1} end
 return result
end
-- Restore portions of a rail that are in front of the player. At a shared
-- projected pixel, world x+y orders a vertical character against a rail;
-- using foot-screen distance would incorrectly hide the foreground posts.
function M.visible(ax,ay,bx,by,cx,cy,rx,ry,depthA,depthB,playerDepth)
 local epsilon=1e-6
 if math.min(depthA,depthB)>=playerDepth-epsilon then return {{0,1}} end
 local ranges=M.outside(ax,ay,bx,by,cx,cy,rx,ry)
 if math.max(depthA,depthB)>=playerDepth-epsilon then
  local t=math.max(0,math.min(1,(playerDepth-epsilon-depthA)/(depthB-depthA)))
  ranges[#ranges+1]=depthB>depthA and {t,1} or {0,t}
 end
 table.sort(ranges,function(a,b)return a[1]<b[1]end)
 local result={}
 for _,range in ipairs(ranges)do
  local last=result[#result]
  if last and range[1]<=last[2]+epsilon then last[2]=math.max(last[2],range[2])
  else result[#result+1]={range[1],range[2]} end
 end
 return result
end
return M
