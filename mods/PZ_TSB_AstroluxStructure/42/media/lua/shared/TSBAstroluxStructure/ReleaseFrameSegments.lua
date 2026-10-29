-- Shared visual frame treatment for the private showroom's straight and diagonal glass.
local F={height=193/192,worldWidth=2.4,minScreenWidth=1.6}

local body={62/255,76/255,83/255,1}
local highlight={151/255,172/255,181/255,.72}
function F.width(zoom)return math.max(F.minScreenWidth,F.worldWidth/zoom)end
local function pointKey(p)return p[1]..':'..p[2]..':'..p[3]end
function F.segments(site,corners,straight,doors)
 local result,seen={},{}
 local function add(a,b)
  local ak,bk=pointKey(a),pointKey(b)
  if ak>bk then a,b=b,a;ak,bk=bk,ak end
  local key=ak..'/'..bk
  if not seen[key]then seen[key]=true;result[#result+1]={a=a,b=b}end
 end
 local function upright(p)add({p[1],p[2],0},{p[1],p[2],F.height})end
 local function rail(a,b,z)add({a[1],a[2],z},{b[1],b[2],z})end
 for _,corner in ipairs(corners)do
  rail(corner.a,corner.b,0);rail(corner.a,corner.b,F.height)
  for i=0,3 do upright({corner.a[1]+(corner.b[1]-corner.a[1])*i/3,corner.a[2]+(corner.b[2]-corner.a[2])*i/3})end
 end
 local function native(o,door)
  if not o or o:getObjectIndex()<0 or o:isDestroyed()then return end
  local sq=o:getSquare();if not sq or sq:getZ()~=0 then return end
  local md=o:getModData()
  if md.TSBAstroluxStructure~=site.recordId or md.TSBAstroluxStructureKind~=(door and 'slidingDoor' or 'window')then return end
  local x,y=sq:getX()-site.x,sq:getY()-site.y
  local north=o:getNorth();local along=north and x or y;local edge=north and y or x
  if (edge~=0 and edge~=12) or along<3 or along>=9 then return end
  if door and along~=5 and along~=6 then return end
  local a={x,y};local b={x+(north and 1 or 0),y+(north and 0 or 1)}
  rail(a,b,0);rail(a,b,F.height)
  -- Fixed door jambs/header/threshold, with no fixed center post obstructing
  -- the two-leaf opening. Native moving leaves, handles and animation remain.
  if not door or along~=6 then upright(a)end
  if not door or along+1~=6 then upright(b)end
 end
 for o in pairs(straight)do native(o,false)end
 for o in pairs(doors)do native(o,true)end
 return result
end

return F
