-- Folded corner canopies: decorative covers only, no native floors or collision.
local combinedLights=require 'AstroluxBayTest/CombinedLights'
local M={corners={{0,0},{9,0},{0,9},{9,9}}}
function M.isRim()return false end
-- Fixed local polygons; lighting is applied separately during replay.
local cached={};local cachedBasis=nil
local function build(levelOffset,pass,xx,xy,yx,yy,zx,zy)
 local polygons={}
 local panel={drawPolygon=function(_,texture,...)polygons[#polygons+1]={...}end}
 local zoom=1
 local function p(v)
  return v[1]*xx+v[2]*yx+v[3]*zx,v[1]*xy+v[2]*yy+v[3]*zy
 end
 local function quad(a,b,c,d,color,emission,alpha)
  local ax,ay=p(a);local bx,by=p(b);local cx,cy=p(c);local dx,dy=p(d)
  local shade=1
  panel:drawPolygon(nil,ax,ay,bx,by,cx,cy,dx,dy,color[1]*shade,color[2]*shade,color[3]*shade,alpha or 1,emission and 'emission' or 'surface')
 end
 local function post(x,y,z0,z1)
  local light=1
  local ax,ay=p({x,y,z0});local bx,by=p({x,y,z1})
  local dx,dy=bx-ax,by-ay;local len=math.sqrt(dx*dx+dy*dy)
  if len<0.01 then return end
  local ux,uy=dx/len,dy/len;local nx,ny=-uy,ux
  local scale=1/zoom
  local function strip(t0,t1,n0,n1,c)
   n0=n0*scale;n1=n1*scale
   panel:drawPolygon(nil,ax+ux*t0+nx*n0,ay+uy*t0+ny*n0,
    ax+ux*t1+nx*n0,ay+uy*t1+ny*n0,ax+ux*t1+nx*n1,ay+uy*t1+ny*n1,
    ax+ux*t0+nx*n1,ay+uy*t0+ny*n1,c[1]*light,c[2]*light,c[3]*light,1,'post')
  end
  strip(0,len,-12,12,{0.25,0.29,0.32})
  strip(0,len,-7,7,{0.36,0.40,0.43})
  strip(0,len,-12,-7,{0.24,0.28,0.31})
  strip(0,len,7,12,{0.22,0.26,0.29})
  strip(0,len,-12,-10,{0.16,0.20,0.23})
  strip(0,len,7,9,{0.18,0.22,0.25})
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
 local function footing(x,y)
  -- Steel base plate seated on the floor, with thickness and four anchor bolts.
  local r=.23;local z=.05
  quad({x-r,y-r,z},{x+r,y-r,z},{x+r,y+r,z},{x-r,y+r,z},{.34,.38,.41})
  quad({x-r,y+r,0},{x+r,y+r,0},{x+r,y+r,z},{x-r,y+r,z},{.18,.22,.25})
  quad({x+r,y-r,0},{x+r,y+r,0},{x+r,y+r,z},{x+r,y-r,z},{.14,.18,.21})
  for _,dx in ipairs({-.16,.16})do for _,dy in ipairs({-.16,.16})do
   local a,b=x+dx,y+dy;local n=.035
   quad({a-n,b-n,z+.008},{a+n,b-n,z+.008},{a+n,b+n,z+.008},{a-n,b+n,z+.008},{.60,.64,.67})
  end end
 end
 local function canopy(x,y)
  -- Full 3x3 ceiling coverage; an inset raised panel creates a shallow folded rim.
  local z=.98;local bottom=.88;local inset=.16
  local a={x,y,z};local b={x+3,y,z};local c={x+3,y+3,z};local d={x,y+3,z}
  local ai={x+inset,y+inset,1.015};local bi={x+3-inset,y+inset,1.015}
  local ci={x+3-inset,y+3-inset,1.015};local di={x+inset,y+3-inset,1.015}
  quad(a,b,bi,ai,{.29,.32,.34});quad(b,c,ci,bi,{.25,.28,.30})
  quad(ai,bi,ci,di,{.24,.27,.29})
  quad(d,di,ci,c,{.33,.36,.38});quad(a,ai,di,d,{.30,.33,.35})
  -- Visible folded edges and recessed shadow underneath.
  quad(d,c,{x+3,y+3,bottom},{x,y+3,bottom},{.15,.18,.20})
  quad(c,b,{x+3,y,bottom},{x+3,y+3,bottom},{.11,.14,.16})
  quad({x,y+3,bottom},{x+3,y+3,bottom},{x+3,y+3,bottom-.018},{x,y+3,bottom-.018},{.07,.09,.10})
  quad({x+3,y,bottom},{x+3,y+3,bottom},{x+3,y+3,bottom-.018},{x+3,y,bottom-.018},{.07,.09,.10})
  -- Three-times-thicker cyan tube with graduated translucent bloom.
  local function neon(ax,ay,bx,by)
   for _,layer in ipairs({
    {.055,.10,{.04,.52,.90}},
    {.035,.22,{.05,.65,1}},
    {.023,.40,{.08,.76,1}},
    {.015,1,{.12,.82,1}},
    {.005,1,{.58,.95,1}},
   })do
    local h,alpha,color=layer[1],layer[2],layer[3]
    quad({ax,ay,.905+h},{bx,by,.905+h},{bx,by,.905-h},{ax,ay,.905-h},color,true,alpha)
   end
  end
  neon(x+.25,y+3,x+2.75,y+3)
  neon(x+3,y+.25,x+3,y+2.75)
 end
 local function joint(x,y)
  -- Two folded L-angle plates follow the canopy edges, with upright post legs.
  local ix=x==0 and 1 or -1;local iy=y==0 and 1 or -1
  local function face(axis,u,z)
   if axis==1 then return {x+ix*u,y+.08,z}end
   return {x+.08,y+iy*u,z}
  end
  for axis=1,2 do
   local color=axis==1 and {.32,.36,.39} or {.24,.28,.31}
   local function plate(u0,u1,z0,z1,c)
    quad(face(axis,u0,z0),face(axis,u1,z0),face(axis,u1,z1),face(axis,u0,z1),c)
   end
   -- Upright leg grips the girder; horizontal arm seats beneath the ceiling.
   plate(-.08,.08,.76,.98,color)
   plate(.08,.42,.85,.96,color)
   plate(.08,.42,.85,.875,{.08,.16,.19})
   -- Return flange on the upper edge makes the angle's thickness visible.
   local a=face(axis,-.08,.98);local b=face(axis,.42,.98)
   local c={b[1],b[2],b[3]};local d={a[1],a[2],a[3]}
   c[axis==1 and 2 or 1]=c[axis==1 and 2 or 1]-.06
   d[axis==1 and 2 or 1]=d[axis==1 and 2 or 1]-.06
   quad(a,b,c,d,{.42,.46,.49})
   for _,bolt in ipairs({{0,.80},{0,.89},{.24,.90},{.35,.90}})do
    local u,z=bolt[1],bolt[2]
    plate(u-.025,u+.025,z-.022,z+.022,{.13,.17,.20})
    plate(u-.014,u+.014,z-.012,z+.012,{.56,.60,.63})
   end
  end
 end
 local level=(levelOffset or 0)+1
 for i,corner in ipairs(M.corners)do
  if (pass=='front' and i==4) or (pass=='rear' and i~=4) then
   local x,y=corner[1],corner[2]
   local outerX=x==0 and 0 or 12;local outerY=y==0 and 0 or 12
   if level==1 then
    footing(outerX,outerY)
    post(outerX,outerY,.05,.88)
    canopy(x,y)
    joint(outerX,outerY)
   end
   -- Keep upper corners open: no horizontal rails crossing the vehicle noses.
   -- Upper posts align with the cube junctions, three tiles inward on each axis.
   local innerX=x==0 and 3 or 9;local innerY=y==0 and 3 or 9
   post(innerX,innerY,level==1 and 1.015 or level,level+1)
  end
 end
 return polygons
end
function M.draw(panel,sx,sy,levelOffset,pass)
 local xx=IsoUtils.XToScreen(1,0,0,0);local xy=IsoUtils.YToScreen(1,0,0,0)
 local yx=IsoUtils.XToScreen(0,1,0,0);local yy=IsoUtils.YToScreen(0,1,0,0)
 local zx=IsoUtils.XToScreen(0,0,1,0);local zy=IsoUtils.YToScreen(0,0,1,0)
 if not cachedBasis or cachedBasis[1]~=xx or cachedBasis[2]~=xy or cachedBasis[3]~=yx
  or cachedBasis[4]~=yy or cachedBasis[5]~=zx or cachedBasis[6]~=zy then
  cached={};cachedBasis={xx,xy,yx,yy,zx,zy}
 end
 local level=levelOffset or 0
 if level<0 or level>2 or level%1~=0 or (pass~='front' and pass~='rear') then return end
 local key=level*2+(pass=='front' and 1 or 0)
 if not cached[key] then cached[key]=build(level,pass,xx,xy,yx,yy,zx,zy) end
 local polygons=cached[key]
 local scale=1/getCore():getZoom(0)
 local ox=(IsoUtils.XToScreen(sx,sy,0,0)-IsoCamera.getOffX(0))*scale
 local oy=(IsoUtils.YToScreen(sx,sy,0,0)-IsoCamera.getOffY(0))*scale
 local sq=getCell():getGridSquare(sx+5,sy+5,0)
 local light=sq and math.max(.10,math.min(1,sq:getLightLevel(0))) or 1
 local sample=getCell():getGridSquare(sx+5,sy+5,1)
 local postLight=sample and math.max(.10,math.min(1,sample:getLightLevel(0))) or 1
 postLight=math.max(postLight,.88*math.max(0,math.min(1,combinedLights.brightness or 0)))
 local emission=.35+.65*(1-light)
 local draw=panel.drawPolygon
 for i=1,#polygons do
  local q=polygons[i]
  local shade=q[13]=='post' and postLight or (q[13]=='emission' and emission or light)
  draw(panel,nil,ox+q[1]*scale,oy+q[2]*scale,ox+q[3]*scale,oy+q[4]*scale,
   ox+q[5]*scale,oy+q[6]*scale,ox+q[7]*scale,oy+q[8]*scale,
   q[9]*shade,q[10]*shade,q[11]*shade,q[12])
 end
end
return M