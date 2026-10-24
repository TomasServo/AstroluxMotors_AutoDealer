local M={}
-- Convex polygon clipping; accepts either clockwise or counterclockwise boundaries.
function M.clip(poly,wall)
 local area=0
 for i,a in ipairs(wall) do local b=wall[i%#wall+1];area=area+a[1]*b[2]-b[1]*a[2] end
 local sign=area>=0 and 1 or -1
 for i,a in ipairs(wall) do
  local b=wall[i%#wall+1];local out={}
  local function side(p)return sign*((b[1]-a[1])*(p[2]-a[2])-(b[2]-a[2])*(p[1]-a[1]))end
  for j,p in ipairs(poly) do
   local q=poly[j%#poly+1];local sp,sq=side(p),side(q)
   if sp>=0 then out[#out+1]=p end
   if (sp>=0)~=(sq>=0) then
    local t=sp/(sp-sq);out[#out+1]={p[1]+(q[1]-p[1])*t,p[2]+(q[2]-p[2])*t}
   end
  end
  poly=out;if #poly==0 then break end
 end
 return poly
end
return M
