-- Native stepped window edges follow the octagon; never clear furniture.
if isClient() or isServer()then return end
local Preview=require 'AstroluxDiagonalLab/ShowroomPreview'
local M={key='TSBAstroluxCornerCollisionV1'};local ticks=0;local failed=false;local last
function M.plan()
 local out={}
 for _,flip in ipairs({{false,false},{true,false},{true,true},{false,true}})do
  for n=0,2 do for _,north in ipairs({true,false})do
   local x,y=north and n or 0,north and 0 or n
   local tx,ty=north and n or 2-n,north and 2-n or n
   if flip[1]then x=(north and 11 or 12)-x;tx=(north and 11 or 12)-tx end
   if flip[2]then y=(north and 12 or 11)-y;ty=(north and 12 or 11)-ty end
   out[#out+1]={x=x,y=y,tx=tx,ty=ty,north=north}
  end end
 end
 return out
end
local function refresh(sq)
 sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
end
local function move(o,to)
 local from=o:getSquare()
 if from==to and o:getObjectIndex()>=0 then return end
 if from and o:getObjectIndex()>=0 then from:RemoveTileObject(o);refresh(from)end
 o:setSquare(to);to:AddSpecialObject(o);refresh(to)
 assert(o:getSquare()==to and o:getObjectIndex()>=0,'Window relocation failed')
end
function M.apply(s,active)
 local cell=getCell();local lookup={};local corner
 for x=0,12 do for y=0,12 do
  local sq=cell:getGridSquare(s.x+x,s.y+y,0)
  if not sq then return false,'Waiting for all corner squares' end
  local list=sq:getObjects()
  for i=0,list:size()-1 do
   local o=list:get(i);local md=o:getModData()
   if md.TSBAstroluxStructure==s.recordId then
    if md.TSBAstroluxStructureKind=='window' and instanceof(o,'IsoWindow')then
     local saved=md[M.key];local ox,oy=x,y
     if saved then
      if saved.owner~=s.recordId then return false,'Foreign corner migration marker' end
      ox,oy=saved.x,saved.y
     end
     local k=ox..':'..oy..':'..tostring(o:getNorth())
     if lookup[k]then return false,'Duplicate owned window edge' end
     lookup[k]=o
    elseif md.TSBAstroluxStructureKind=='corner' and x==12 and y==12 then
     if corner then return false,'Duplicate corner trim' end
     corner=o
    end
   end
  end
 end end
 local pending={}
 for _,p in ipairs(M.plan())do
  local o=lookup[p.x..':'..p.y..':'..tostring(p.north)]
  if not o then return false,'Missing original corner window' end
  local from=o:getSquare();local md=o:getModData();local saved=md[M.key]
  local cx,cy=from:getX()-s.x,from:getY()-s.y
  if (saved and (cx~=p.tx or cy~=p.ty))or(not saved and(cx~=p.x or cy~=p.y))then
   return false,'Corner window was moved outside this migration'
  end
  local to=cell:getGridSquare(s.x+(active and p.tx or p.x),s.y+(active and p.ty or p.y),0)
  if to~=from and(to:getMovingObjects():size()>0 or to:getStaticMovingObjects():size()>0)then
   return false,'Waiting for clear corner edge'
  end
  local objects=to:getObjects()
  for i=0,objects:size()-1 do
   local other=objects:get(i)
   if other~=o and (instanceof(other,'IsoDoor')or(instanceof(other,'IsoWindow')and other:getNorth()==p.north))then
    return false,'Another door/window occupies the destination'
   end
  end
  pending[#pending+1]={o=o,from=from,to=to,old=saved,p=p}
 end
 if not corner then return false,'Missing original corner trim' end
 local trimName=corner:getSprite():getName()
 if trimName~='TSBAstroluxClearGlass_3'and trimName~='TSBAstroluxClearGlass_15'then return false,'Unexpected corner trim sprite'end
 local sprite=assert(getSprite(active and 'TSBAstroluxClearGlass_15'or'TSBAstroluxClearGlass_3'))
 local done={};local changed=false
 local ok,err=pcall(function()
  for _,v in ipairs(pending)do
   done[#done+1]=v
   if v.from~=v.to then move(v.o,v.to);changed=true end
   v.o:getModData()[M.key]=active and {owner=s.recordId,x=v.p.x,y=v.p.y}or nil
  end
  if corner:getSprite():getName()~=sprite:getName()then corner:setSprite(sprite);refresh(corner:getSquare());changed=true end
 end)
 if not ok then
  local restored=true
  for i=#done,1,-1 do local v=done[i]
   local worked=pcall(function()move(v.o,v.from);v.o:getModData()[M.key]=v.old end)
   restored=restored and worked
  end
  local worked=pcall(function()corner:setSprite(getSprite(trimName));refresh(corner:getSquare())end)
  error(tostring(err)..((restored and worked)and ' Rolled back.'or' Recovery required; stop testing.'))
 end
 return true,changed and(active and '24 corner window edges now follow the octagon.'or'Square window edges restored.')or nil
end
function M.update()
 if failed then return end
 local s=Preview.site();if not s then return end
 local ok,success,message=pcall(M.apply,s,Preview.enabled==true)
 if not ok then failed=true;message=success end
 if message and message~=last then print('[Astrolux corner collision] '..tostring(message));last=message end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%60==0 then M.update()end end)
return M
