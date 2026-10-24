-- Open glazed corners replace the former opaque ceiling covers.
local M={corners={{0,0},{9,0},{0,9},{9,9}}}
function M.isRim()return false end
function M.draw(panel,sx,sy,levelOffset,pass)
 local zoom=getCore():getZoom(0)
 local sq=getCell():getGridSquare(sx+5,sy+5,1)
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
  local ax,ay=p(a[1],a[2],a[3]);local bx,by=p(b[1],b[2],b[3])
  local dx,dy=bx-ax,by-ay;local len=math.sqrt(dx*dx+dy*dy)
  if len<0.01 then return end
  local ux,uy=dx/len,dy/len;local nx,ny=-uy,ux
  local scale=1/zoom
  local function strip(t0,t1,n0,n1,c)
   n0=n0*scale;n1=n1*scale
   panel:drawPolygon(nil,ax+ux*t0+nx*n0,ay+uy*t0+ny*n0,
    ax+ux*t1+nx*n0,ay+uy*t1+ny*n0,ax+ux*t1+nx*n1,ay+uy*t1+ny*n1,
    ax+ux*t0+nx*n1,ay+uy*t0+ny*n1,c[1]*light,c[2]*light,c[3]*light,1)
  end
  strip(0,len,-12,12,{0.25,0.29,0.32})
  strip(0,len,-7,7,{0.36,0.40,0.43})
  strip(0,len,-12,-7,{0.60,0.64,0.67})
  strip(0,len,7,12,{0.52,0.56,0.59})
  strip(0,len,-12,-10,{0.75,0.78,0.80})
  strip(0,len,7,9,{0.67,0.71,0.74})
  strip(0,len,-7,-5,{0.21,0.25,0.28})
  for _,t in ipairs({10*scale,len-34*scale}) do
   strip(t,t+24*scale,-4.5,4.5,{0.24,0.28,0.31})
   strip(t+scale,t+23*scale,-3.5,3.5,{0.43,0.47,0.50})
   strip(t+scale,t+23*scale,-3.5,-2.5,{0.56,0.60,0.63})
   for _,offset in ipairs({7,17}) do
    strip(t+(offset-2)*scale,t+(offset+2)*scale,-2,2,{0.21,0.25,0.28})
    strip(t+(offset-1)*scale,t+(offset+1)*scale,-1,1,{0.68,0.72,0.75})
   end
  end
 end
 -- Rear corners precede the bays; the southeast corner follows them.
 local level=(levelOffset or 0)+1
 for i,v in ipairs({{0,0,3,0,0,3},{12,0,9,0,12,3},{0,12,3,12,0,9},{12,12,9,12,12,9}})do
  if (pass=='front' and i==4) or (pass=='rear' and i~=4) then
   local x,y=v[1],v[2]
   for _,e in ipairs({{v[3],v[4]},{v[5],v[6]}})do
    quad({x,y,level},{e[1],e[2],level},{e[1],e[2],level+1},{x,y,level+1},.42,.53,.58,.055)
    member({x,y,level},{e[1],e[2],level})
    if level==3 then member({x,y,4},{e[1],e[2],4}) end
   end
   member({x,y,level},{x,y,level+1})
  end
 end
end
return M
