-- Recessed roof with parapet and broad branded fascia; decorative only.
local M={}
function M.draw(panel,x,y)
 local zoom=getCore():getZoom(0)
 local sq=getCell():getGridSquare(x+10,y+10,1)
 local light=sq and math.max(.12,math.min(1,sq:getLightLevel(0))) or 1
 local function p(v)
  return (IsoUtils.XToScreen(x+v[1],y+v[2],v[3],0)-IsoCamera.getOffX(0))/zoom,
   (IsoUtils.YToScreen(x+v[1],y+v[2],v[3],0)-IsoCamera.getOffY(0))/zoom
 end
 local function quad(a,b,c,d,color,texture,emission)
  local ax,ay=p(a);local bx,by=p(b);local cx,cy=p(c);local dx,dy=p(d)
  local l=emission or light
  panel:drawPolygon(texture,ax,ay,bx,by,cx,cy,dx,dy,color[1]*l,color[2]*l,color[3]*l,1)
 end
 local deck,top=4.76,4.95
 local dark={.10,.12,.14};local coping={.40,.43,.46}
 -- Clean gray membrane and understated panel seams.
 quad({0,0,deck},{12,0,deck},{12,12,deck},{0,12,deck},{.39,.40,.43})
 for i=2,10,2 do
  quad({i,.22,deck+.001},{i+.018,.22,deck+.001},{i+.018,11.78,deck+.001},{i,11.78,deck+.001},{.35,.36,.39})
 end
 -- Soft ambient occlusion inside the parapet and beneath the rooftop cabinet.
 for i=0,3 do
  local inset=.20+i*.10;local c=.27+i*.025
  quad({inset,inset,deck+.002},{12-inset,inset,deck+.002},{12-inset,inset+.10,deck+.002},{inset,inset+.10,deck+.002},{c,c+.01,c+.04})
  quad({inset,inset+.10,deck+.002},{inset+.10,inset+.10,deck+.002},{inset+.10,12-inset,deck+.002},{inset,12-inset,deck+.002},{c,c+.01,c+.04})
 end
 quad({3.05,6.1,deck+.003},{4.65,6.1,deck+.003},{4.95,8.05,deck+.003},{3.35,8.05,deck+.003},{.27,.28,.31})
 -- Far parapet interior faces, drawn before equipment.
 quad({.20,.20,top},{11.80,.20,top},{11.80,.20,deck},{.20,.20,deck},dark)
 quad({.20,11.80,top},{.20,.20,top},{.20,.20,deck},{.20,11.80,deck},{.15,.17,.19})
 -- A compact rooftop condenser, with curb, cabinet depth, louvered face and grille.
 local function box(x0,y0,x1,y1,z0,z1,topColor,frontColor,sideColor)
  quad({x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1},topColor)
  quad({x0,y1,z1},{x1,y1,z1},{x1,y1,z0},{x0,y1,z0},frontColor)
  quad({x1,y1,z1},{x1,y0,z1},{x1,y0,z0},{x1,y1,z0},sideColor)
 end
 box(3.1,6.1,4.6,7.6,deck,deck+.07,{.26,.28,.30},{.20,.22,.24},{.16,.18,.20})
 box(3.23,6.23,4.47,7.47,deck+.07,deck+.46,{.52,.54,.56},{.36,.38,.40},{.27,.29,.31})
 for i=0,5 do
  local z=deck+.13+i*.045
  quad({3.35,7.475,z+.016},{4.35,7.475,z+.016},{4.35,7.475,z},{3.35,7.475,z},{.12,.14,.16})
 end
 for i=0,6 do
  local gx=3.36+i*.14
  quad({gx,6.36,deck+.461},{gx+.055,6.36,deck+.461},{gx+.055,7.34,deck+.461},{gx,7.34,deck+.461},{.19,.21,.23})
 end
 -- Near fascia and inside parapet. All corners terminate on the same footprint.
 quad({0,12,top},{12,12,top},{12,12,4},{0,12,4},{.075,.095,.115})
 quad({12,12,top},{12,0,top},{12,0,4},{12,12,4},{.055,.075,.095})
 quad({.20,11.80,top},{11.80,11.80,top},{11.80,11.80,deck},{.20,11.80,deck},{.19,.21,.23})
 quad({11.80,11.80,top},{11.80,.20,top},{11.80,.20,deck},{11.80,11.80,deck},{.15,.17,.19})
 local w=.20
 quad({0,0,top},{12,0,top},{12,w,top},{0,w,top},coping)
 quad({0,12-w,top},{12,12-w,top},{12,12,top},{0,12,top},coping)
 quad({0,w,top},{w,w,top},{w,12-w,top},{0,12-w,top},coping)
 quad({12-w,w,top},{12,w,top},{12,12-w,top},{12-w,12-w,top},coping)
 local logo=getTexture('media/textures/AstroluxRoofWordmark.png')
 if logo then
  local glow=.75+.25*light
  -- Reuse the approved cyan ASTROLUX / gold MOTORS wordmark, without the car emblem.
  quad({1.4,12.005,4.88},{10.6,12.005,4.88},{10.6,12.005,4.11},{1.4,12.005,4.11},{1,1,1},logo,glow)
  quad({12.005,10.6,4.88},{12.005,1.4,4.88},{12.005,1.4,4.11},{12.005,10.6,4.11},{1,1,1},logo,glow)
 end
end
return M
