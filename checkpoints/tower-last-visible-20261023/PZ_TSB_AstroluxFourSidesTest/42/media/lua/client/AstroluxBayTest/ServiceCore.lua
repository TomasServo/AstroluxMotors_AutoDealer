-- Open steel skeleton in the recessed interior. Decorative, no world collision.
local M={members={}}
local function add(a,b,kind) M.members[#M.members+1]={a=a,b=b,kind=kind} end
-- Columns and beams terminate at common structural nodes; front links meet bays.
for _,xy in ipairs({{2,2},{5,2},{8,2},{2,5},{2,8},{8,8}}) do
 add({xy[1],xy[2],1},{xy[1],xy[2],2},'column')
end
for _,z in ipairs({1,2}) do
 for _,edge in ipairs({{2,2,5,2},{5,2,8,2},{2,2,2,5},{2,5,2,8},{8,2,8,8},{2,8,8,8}}) do
  add({edge[1],edge[2],z},{edge[3],edge[4],z},'beam')
 end
end
-- Alternating rear-wall braces create depth without filling the front windows.
add({2,2,1},{5,2,2},'brace')
add({5,2,2},{8,2,1},'brace')
add({2,2,2},{2,5,1},'brace')
add({2,5,1},{2,8,2},'brace')
-- Two overhead ties join the rear skeleton to the inner display supports.
add({5,2,2},{8,8,2},'tie')
add({2,5,2},{8,8,2},'tie')
function M.draw(panel,siteX,siteY,levelOffset)
 local zoom=getCore():getZoom(0)
 local sq=getCell():getGridSquare(siteX+5,siteY+5,1)
 local light=sq and math.max(0.10,math.min(1,sq:getLightLevel(0))) or 1
 local function p(v)
  return (IsoUtils.XToScreen(siteX+v[1]+1,siteY+v[2]+1,v[3]+(levelOffset or 0),0)-IsoCamera.getOffX(0))/zoom,
   (IsoUtils.YToScreen(siteX+v[1]+1,siteY+v[2]+1,v[3]+(levelOffset or 0),0)-IsoCamera.getOffY(0))/zoom
 end
 -- Recessed webs and two narrow flanges; no large flat equipment silhouettes.
 local function member(m)
  local ax,ay=p(m.a);local bx,by=p(m.b)
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
 -- Rear steel first; front connections last. Cars render after the entire core.
 for _,kind in ipairs({'brace','tie','beam','column'}) do
  for _,m in ipairs(M.members) do if m.kind==kind then member(m) end end
 end
end
return M


