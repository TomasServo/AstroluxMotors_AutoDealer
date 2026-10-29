-- Vector numerals without changing furniture, textures or collision.
local Areas=require 'TSBAstroluxVend/SpawnAreas'
local M={}
local segments={{.12,.08,.88,.08},{.9,.12,.9,.75},{.9,.85,.9,1.48},{.12,1.52,.88,1.52},{.1,.85,.1,1.48},{.1,.12,.1,.75},{.12,.8,.88,.8}}
local digits={['0']={1,2,3,4,5,6},['2']={1,2,7,5,4},['3']={1,2,7,3,4},['4']={6,7,2,3},['5']={1,6,7,3,4},['6']={1,6,7,5,3,4},['7']={1,2,3},['8']={1,2,3,4,5,6,7},['9']={1,2,3,4,6,7}}
function M.quads(number)
 local text=tostring(number);local out={};local width=#text*1.2-.2
 local function stroke(s,offset)
  local dx,dy=s[3]-s[1],s[4]-s[2];local len=math.sqrt(dx*dx+dy*dy)
  local nx,ny=-dy/len*.065,dx/len*.065
  out[#out+1]={{(s[1]+nx+offset)/width,(s[2]+ny)/1.6},{(s[3]+nx+offset)/width,(s[4]+ny)/1.6},{(s[3]-nx+offset)/width,(s[4]-ny)/1.6},{(s[1]-nx+offset)/width,(s[2]-ny)/1.6}}
 end
 for i=1,#text do local c=text:sub(i,i);local offset=(i-1)*1.2
  if c=='1'then for _,s in ipairs({{.25,.3,.52,.08},{.52,.08,.52,1.52},{.25,1.52,.8,1.52}})do stroke(s,offset)end
  else for _,j in ipairs(digits[c]or {})do stroke(segments[j],offset)end end
 end
 return out
end
function M.zone(area,u,v)
 local f=Areas.vectors[area.heading]or Areas.vectors.N
 local height=math.min(3,math.min(area.x2-area.x1+1,area.y2-area.y1+1)*.65)
 local width=height*.625
 local x,y=(area.x1+area.x2+1)/2,(area.y1+area.y2+1)/2
 return x-f[2]*(u-.5)*width-f[1]*(v-.5)*height,y+f[1]*(u-.5)*width-f[2]*(v-.5)*height
end
function M.kiosk(index,u,v)
 -- Native 128x256 artwork: inside the access door, above the front vent.
 if index==0 then return 44+14*u,119+7*u+16*v end
 if index==1 then return 68+14*u,124-7*u+16*v end
end
return M
