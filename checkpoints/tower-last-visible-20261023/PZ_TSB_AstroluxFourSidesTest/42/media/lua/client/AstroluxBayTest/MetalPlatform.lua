local girderClip=require 'AstroluxBayTest/GirderClip'
-- Decorative upper-bay style sample; no world objects, collision or shadow casters.
local M={}
function M.draw(panel,point,light)
 local function quad(a,b,c,d,color)
  local ax,ay=point(a[1],a[2],a[3]);local bx,by=point(b[1],b[2],b[3])
  local cx,cy=point(c[1],c[2],c[3]);local dx,dy=point(d[1],d[2],d[3])
  panel:drawPolygon(nil,ax,ay,bx,by,cx,cy,dx,dy,color[1]*light,color[2]*light,color[3]*light,1)
 end
 local function plate(x1,y1,x2,y2,z,color)
  quad({x1,y1,z},{x2,y1,z},{x2,y2,z},{x1,y2,z},color)
 end
 -- Large panels, avoiding a small showroom-tile pattern.
 plate(0,0,6,3,1,{0.28,0.30,0.32})
 for x=0,2 do for y=0,1 do
  local value=((x+y)%2)*0.012
  plate(x*2+0.015,y*1.5+0.015,(x+1)*2-0.015,(y+1)*1.5-0.015,1,{0.35+value,0.37+value,0.39+value})
 end end
 -- Thin fascia on camera-facing platform edges.
 quad({0,3,1},{6,3,1},{6,3,0.965},{0,3,0.965},{0.23,0.26,0.28})
 quad({6,0,1},{6,3,1},{6,3,0.965},{6,0,0.965},{0.29,0.32,0.34})
 local edge={0.53,0.56,0.58}
 plate(0,0,6,0.035,1,edge);plate(0,2.965,6,3,1,edge)
 plate(0,0,0.035,3,1,edge);plate(5.965,0,6,3,1,edge)
 -- Two low-profile wheel channels; neutral metal, no hazard-striping clutter.
 for _,y in ipairs({0.72,2.28}) do
  plate(0.45,y-0.19,5.7,y+0.19,1,{0.23,0.25,0.27})
  plate(0.45,y-0.19,5.7,y-0.17,1,{0.48,0.51,0.53})
  plate(0.45,y+0.17,5.7,y+0.19,1,{0.48,0.51,0.53})
  -- Low steel wheel stops near the front end of each channel.
  plate(5.52,y-0.23,5.68,y+0.23,1.025,{0.52,0.55,0.57})
  quad({5.68,y-0.23,1.025},{5.68,y+0.23,1.025},{5.68,y+0.23,1},{5.68,y-0.23,1},{0.28,0.31,0.33})
  quad({5.52,y+0.23,1.025},{5.68,y+0.23,1.025},{5.68,y+0.23,1},{5.52,y+0.23,1},{0.22,0.25,0.27})
 end
end
-- Draw behind the upper car, before its platform, to avoid rails across the car.
function M.drawDetails(panel,point,light,lightsOn,fixtureStrength,upperOnly,descending)
 local ax,ay=point(0,0,0);local bx,by=point(1,0,0)
 local scale=math.abs(bx-ax)/64
 local function beam(a,b,width,color,brightness)
  local x1,y1=point(a[1],a[2],a[3]);local x2,y2=point(b[1],b[2],b[3])
  local dx,dy=x2-x1,y2-y1;local len=math.sqrt(dx*dx+dy*dy)
  if len==0 then return end
  local nx,ny=-dy/len*width*scale/2,dx/len*width*scale/2
  local l=brightness or light
  panel:drawPolygon(nil,x1+nx,y1+ny,x2+nx,y2+ny,x2-nx,y2-ny,x1-nx,y1-ny,color[1]*l,color[2]*l,color[3]*l,1)
 end
 local steel={0.36,0.40,0.43};local trim={0.49,0.53,0.55}
 -- H-section rear girders with compact connections inside the recessed web.
 local function girder(a,b)
  local x1,y1=point(a[1],a[2],a[3]);local x2,y2=point(b[1],b[2],b[3])
  local dx,dy=x2-x1,y2-y1;local length=math.sqrt(dx*dx+dy*dy)
  if length==0 then return end
  local ux,uy=dx/length,dy/length;local nx,ny=-uy,ux
  local function p(x,y,z)local u,v=point(x,y,z);return {u,v}end
  local wall
  if a[2]==b[2] then wall={p(0,0,1),p(6,0,1),p(6,0,2),p(0,0,2)}
  else wall={p(0,0,1),p(0,3,1),p(0,3,2),p(0,0,2)} end
  local function strip(t1,t2,n1,n2,color)
   local function vertex(t,n)return x1+ux*t+nx*n*scale,y1+uy*t+ny*n*scale end
   local ax,ay=vertex(t1,n1);local bx,by=vertex(t2,n1)
   local cx,cy=vertex(t2,n2);local dx,dy=vertex(t1,n2)
   local shape=girderClip.clip({{ax,ay},{bx,by},{cx,cy},{dx,dy}},wall)
   -- A clipped joint can have more than four corners. Triangulate without overlaps.
   for i=2,#shape-1 do
    local p,q,r=shape[1],shape[i],shape[i+1]
    panel:drawPolygon(nil,p[1],p[2],q[1],q[2],r[1],r[2],r[1],r[2],color[1]*light,color[2]*light,color[3]*light,1)
   end
  end
  -- H-section appearance: recessed web between two raised longitudinal flanges.
  strip(0,length,-12,12,{0.25,0.29,0.32})
  strip(0,length,-7,7,{0.36,0.40,0.43})
  strip(0,length,-12,-7,{0.60,0.64,0.67})
  strip(0,length,7,12,{0.52,0.56,0.59})
  strip(0,length,-12,-10,{0.75,0.78,0.80})
  strip(0,length,7,9,{0.67,0.71,0.74})
  strip(0,length,-7,-5,{0.21,0.25,0.28})
  -- Narrow web connections follow the member axis and never cover either flange.
  -- Carry the full H contour into the frame; all faces still clip to the wall.
  for _,t in ipairs({10*scale,length-34*scale}) do
   strip(t,t+24*scale,-4.5,4.5,{0.24,0.28,0.31})
   strip(t+scale,t+23*scale,-3.5,3.5,{0.43,0.47,0.50})
   strip(t+scale,t+23*scale,-3.5,-2.5,{0.56,0.60,0.63})
   -- Two modest fastener heads in the recessed web, with dark washer rims.
   for _,offset in ipairs({7,17}) do
    strip(t+(offset-2)*scale,t+(offset+2)*scale,-2,2,{0.21,0.25,0.28})
    strip(t+(offset-1)*scale,t+(offset+1)*scale,-1,1,{0.68,0.72,0.75})
   end
  end
 end
 -- One member on each rear wall; preserve open front views of the car.
 if descending then girder({0,0,2},{6,0,1}) else girder({0,0,1},{6,0,2}) end
 if descending then girder({0,0,2},{0,3,1}) else girder({0,0,1},{0,3,2}) end
 -- Thin support channels just below the accepted platform edge.
 beam({0,3,0.95},{6,3,0.95},6,steel)
 beam({6,0,0.95},{6,3,0.95},6,steel)
 beam({0,3,0.936},{6,3,0.936},1,trim)
 beam({6,0,0.936},{6,3,0.936},1,trim)
 -- Decorative luminous fixtures, not dynamic world lights or shadow casters.
 local function lamp(a,b)
  local function along(t,z)
   return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t+(z or 0)}
  end
  -- Short mounts and a solid casing distinguish a fixture from a glowing line.
  for _,t in ipairs({0.18,0.82}) do beam(along(t,0.03),along(t),3,{0.40,0.43,0.45}) end
  beam(a,b,10,{0.27,0.30,0.32})
  beam(a,b,8,{0.53,0.56,0.58})
  -- Broad, neutral cool-white diffuser: decorative emission, no world light yet.
  beam(along(0.025),along(0.975),5,{0.88,0.92,0.94},(lightsOn==false and 0.45*light or (0.30+0.70*(fixtureStrength or 1))))
  beam(a,along(0.025),8,{0.36,0.39,0.41})
  beam(along(0.975),b,8,{0.36,0.39,0.41})
 end
 lamp({0.55,0.12,1.94},{5.45,0.12,1.94})
 if not upperOnly then lamp({0.55,0.12,0.94},{5.45,0.12,0.94}) end
end
return M

