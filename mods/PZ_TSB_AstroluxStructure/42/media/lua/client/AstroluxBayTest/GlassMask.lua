local M={}
local function half(poly,a,b,inside)
 local result={}
 local function side(p)return (b[1]-a[1])*(p[2]-a[2])-(b[2]-a[2])*(p[1]-a[1])end
 for i,p in ipairs(poly) do
  local q=poly[i%#poly+1];local sp,sq=side(p),side(q)
  local pin=inside and sp>=0 or not inside and sp<=0
  if pin then result[#result+1]=p end
  if (sp>0 and sq<0) or (sp<0 and sq>0) then
   local t=sp/(sp-sq);result[#result+1]={p[1]+t*(q[1]-p[1]),p[2]+t*(q[2]-p[2])}
  end
 end
 return result
end
function M.outside(poly,cx,cy,rx,ry)
 local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
 for _,p in ipairs(poly) do minx=math.min(minx,p[1]);maxx=math.max(maxx,p[1]);miny=math.min(miny,p[2]);maxy=math.max(maxy,p[2])end
 if maxx<cx-rx*1.02 or minx>cx+rx*1.02 or maxy<cy-ry*1.02 or miny>cy+ry*1.02 then return {poly}end
 -- Circumscribed 16-sided ellipse: fully covers the standing-character mask.
 local wall={};local expand=1/math.cos(math.pi/16)
 for i=0,15 do local t=i*math.pi/8;wall[#wall+1]={cx+rx*expand*math.cos(t),cy+ry*expand*math.sin(t)}end
 local remaining=poly;local pieces={}
 for i,a in ipairs(wall) do
  local b=wall[i%#wall+1];local exterior=half(remaining,a,b,false)
  if #exterior>=3 then pieces[#pieces+1]=exterior end
  remaining=half(remaining,a,b,true)
  if #remaining<3 then break end
 end
 return pieces
end
return M
