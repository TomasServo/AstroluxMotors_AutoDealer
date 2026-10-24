-- Open glazed corners replace the former opaque ceiling covers.
local M={corners={{0,0},{9,0},{0,9},{9,9}}}
function M.isRim()return false end
function M.draw(panel,sx,sy)
 local zoom=getCore():getZoom(0)
 local sq=getCell():getGridSquare(sx+5,sy+5,0)
 local light=sq and math.max(.10,math.min(1,sq:getLightLevel(0))) or 1
 local function p(x,y,z)
  return (IsoUtils.XToScreen(sx+x,sy+y,z,0)-IsoCamera.getOffX(0))/zoom,
   (IsoUtils.YToScreen(sx+x,sy+y,z,0)-IsoCamera.getOffY(0))/zoom
 end
 local function quad(a,b,c,d,r,g,blue,alpha)
  local ax,ay=p(a[1],a[2],a[3]);local bx,by=p(b[1],b[2],b[3]);local cx,cy=p(c[1],c[2],c[3]);local dx,dy=p(d[1],d[2],d[3])
  panel:drawPolygon(nil,ax,ay,bx,by,cx,cy,dx,dy,r*light,g*light,blue*light,alpha or 1)
 end
 local function member(a,b)
  local ax,ay=p(a[1],a[2],a[3]);local bx,by=p(b[1],b[2],b[3]);local dx,dy=bx-ax,by-ay
  local len=math.sqrt(dx*dx+dy*dy);if len<.001 then return end
  local nx,ny=-dy/len/zoom,dx/len/zoom
  for _,s in ipairs({{-7,7,.15,.18,.20},{-5,5,.30,.34,.37},{-7,-5,.46,.49,.51},{5,7,.24,.28,.31}})do
   panel:drawPolygon(nil,ax+nx*s[1],ay+ny*s[1],bx+nx*s[1],by+ny*s[1],bx+nx*s[2],by+ny*s[2],ax+nx*s[2],ay+ny*s[2],s[3]*light,s[4]*light,s[5]*light,1)
  end
 end
 for _,v in ipairs({{0,0,3,0,0,3},{12,0,9,0,12,3},{0,12,3,12,0,9},{12,12,9,12,12,9}})do
  local x,y=v[1],v[2]
  for level=1,3 do
   for _,e in ipairs({{v[3],v[4]},{v[5],v[6]}})do
    quad({x,y,level},{e[1],e[2],level},{e[1],e[2],level+1},{x,y,level+1},.42,.53,.58,.055)
    member({x,y,level},{e[1],e[2],level})
   end
  end
  member({x,y,1},{x,y,4})
  member({x,y,4},{v[3],v[4],4});member({x,y,4},{v[5],v[6],4})
 end
end
return M
