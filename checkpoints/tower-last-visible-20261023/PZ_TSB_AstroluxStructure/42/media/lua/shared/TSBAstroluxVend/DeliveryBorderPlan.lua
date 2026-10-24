-- Same native yellow line/corner sprites as the original Astrolux perimeter.
local P={}
function P.sprite(area,x,y)
 if not area or x<area.x1 or x>area.x2 or y<area.y1 or y>area.y2 then return nil end
 local n
 if x==area.x1 and y==area.y1 then n=25
 elseif x==area.x2 and y==area.y1 then n=27
 elseif x==area.x2 and y==area.y2 then n=29
 elseif x==area.x1 and y==area.y2 then n=31
 elseif x==area.x1 then n=24 elseif x==area.x2 then n=28
 elseif y==area.y1 then n=26 elseif y==area.y2 then n=30 end
 return n and ('street_trafficlines_01_'..n)or nil
end
function P.owner(obj)
 local md=obj:getModData();local id=md.TSBAstroluxDeliveryBorder
 if (type(id)~='string' and type(id)~='number')or md.TSBAstroluxDeliveryBorderKind~='perimeter'then return nil end
 local sprite=obj:getSprite();local name=sprite and sprite:getName()
 local n=name and tonumber(name:match('^street_trafficlines_01_(%d+)$'))
 if n and n>=24 and n<=31 then return id end
end
function P.isMarker(obj)return P.owner(obj)~=nil end
function P.loaded(area,regions,visit)
 -- Work scales with streamed edge intersections, never total map rectangle size.
 local seen={}
 local function add(x,y)
  local key=x..':'..y;if seen[key]then return end;seen[key]=true;visit(x,y)
 end
 for _,r in ipairs(regions)do
  local x1,x2=math.max(area.x1,r.x1),math.min(area.x2,r.x2)
  local y1,y2=math.max(area.y1,r.y1),math.min(area.y2,r.y2)
  if area.y1>=r.y1 and area.y1<=r.y2 then for x=x1,x2 do add(x,area.y1)end end
  if area.y2>=r.y1 and area.y2<=r.y2 then for x=x1,x2 do add(x,area.y2)end end
  if area.x1>=r.x1 and area.x1<=r.x2 then for y=y1,y2 do add(area.x1,y)end end
  if area.x2>=r.x1 and area.x2<=r.x2 then for y=y1,y2 do add(area.x2,y)end end
 end
end
return P
