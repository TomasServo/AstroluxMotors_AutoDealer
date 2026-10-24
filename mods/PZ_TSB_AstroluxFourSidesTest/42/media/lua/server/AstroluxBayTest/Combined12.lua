-- Guarded replacement of the exact prior combined test showroom only.
local M={};local ticks=0;local last
local function allowed()
 return not isClient() and not isServer() and getDebug() and getWorld()
  and tostring(getWorld():getWorld())=='AstroluxStructureLab_12x12_FourSides'
end
local function owned(obj,id)
 local md=obj:getModData();local f=md.movableData and md.movableData.TSBAstroluxFurnishingV1
 return md.TSBAstroluxStructure==id or (f and f.tower==id)
end
local function wait(reason)
 if last~=reason then print('[Astrolux Replacement] Waiting: '..tostring(reason));last=reason end
end
function M.run()
 if not allowed()then return end
 local s=ModData.getOrCreate('TSBAstroluxCombined12.v1')
 if s.ready or s.hold then return end
 local previous=ModData.get('TSBAstroluxCombined11.v1');local player=getSpecificPlayer(0)
 if not previous or not previous.ready or not player or player:isDead()then return end
 local records=require 'TSBAstroluxStructure/Records';local old
 for _,r in ipairs(records.all())do if r.id==previous.recordId and r.x==previous.x and r.y==previous.y then old=r end end
 if not old or old.combinedSize~=11 or old.status~='ready' then wait('Prior 11x11 test-showroom record unavailable; nothing removed.');return end
 local builder=require 'AstroluxBayTest/ShowroomBuilder12'
 local target;local reason='No clear expansion around prior showroom.'
 -- Each 12x12 candidate contains the complete old 11x11 footprint.
 for _,d in ipairs({{0,0},{-1,0},{0,-1},{-1,-1}})do
  local x,y=old.x+d[1],old.y+d[2]
  local paved=true
  for dx=0,11 do for dy=0,11 do
   local wx,wy=x+dx,y+dy
   if not(wx>=old.x and wx<old.x+11 and wy>=old.y and wy<old.y+11)then
    local sq=getCell():getGridSquare(wx,wy,0);local floor=sq and sq:getFloor();local sp=floor and floor:getSprite();local name=sp and sp:getName()
    if not name or not(name:find('street',1,true) or name:find('floors_exterior',1,true))then paved=false;reason='Expansion needs loaded pavement at '..wx..','..wy end
   end
  end end
  if paved then
   local plan;plan,reason=builder.preview(player,x,y,true,old)
   if plan then target={x=x,y=y};break end
  end
 end
 if not target then wait(reason);return end
 local capture=require 'AstroluxBayTest/DecorCapture11'
 local ok,profile,why=pcall(capture.survey,old,getCell())
 if not ok or not profile then wait('Furniture/inventory capture failed: '..tostring(ok and why or profile));return end
 -- Prepare every native furnishing and captured inventory before deletion.
 local prepared,why=require('AstroluxBayTest/ShowroomFurnishings12').prepare({x=target.x,y=target.y,replacementProfile=profile})
 if not prepared then wait(why);return end
 local removals={}
 for z=1,0,-1 do for dx=0,11 do for dy=0,11 do
  local sq=getCell():getGridSquare(old.x+dx,old.y+dy,z)
  -- Empty upper squares are normal above the open showroom ceiling.
  -- Ground presence, also checked by preview, establishes that this column is loaded.
  if not getCell():getGridSquare(old.x+dx,old.y+dy,0) then wait('Load the entire old showroom before replacement.');return end
  local list=sq and sq:getObjects()
  for i=(list and list:size() or 0)-1,0,-1 do
   local obj=list:get(i)
   if owned(obj,old.id) and (z~=0 or obj~=sq:getFloor()) then
    local kind=obj:getModData().TSBAstroluxStructureKind
    removals[#removals+1]={obj=obj,sq=sq,special=kind=='window' or kind=='door' or kind=='slidingDoor'}
   end
  end
 end end end
 local db=records.state();local originalTower=db.tower;local originalEntry=db.showrooms and db.showrooms[old.id]
 s.hold='Replacement started; inspect before retry.'
 s.replacementBackup={record=old,profile=profile,target=target}
 local oldFlooring=require 'AstroluxBayTest/ShowroomFlooring11'
 local detached=false
 local success,err=pcall(function()
  for _,e in ipairs(removals)do e.sq:RemoveTileObject(e.obj);assert(e.obj:getObjectIndex()<0,'Removal not confirmed');e.sq:RecalcAllWithNeighbours(true)end
  local restored,why=oldFlooring.restore(old);assert(restored,why)
  if db.tower==old then db.tower=nil end
  if db.showrooms then db.showrooms[old.id]=nil end
  detached=true
  local record,why=builder.place(player,target.x,target.y,{multiple=true,furnished=true,profile=profile})
  assert(record,why)
  s.x=target.x;s.y=target.y;s.recordId=record.id;s.ready=true;s.hold=nil
  previous.replacedBy=record.id;previous.ready=false
  print('[Astrolux Replacement] 11x11 test copy replaced by 12x12 at '..s.x..','..s.y..'; '..#profile.objects..' furnishings captured.')
  player:Say('12x12 four-side layout replaced the old test showroom here. Furniture and container contents transferred.')
 end)
 if not success then
  local partial=old.status=='hold'
  for _,r in ipairs(records.all())do if r~=old and r.status=='hold' then partial=true end end
  local restored=false
  if not partial then
   restored=pcall(function()
    for i=#removals,1,-1 do local e=removals[i]
     if e.obj:getObjectIndex()<0 then if e.special then e.sq:AddSpecialObject(e.obj)else e.sq:AddTileObject(e.obj)end end
     e.sq:RecalcAllWithNeighbours(true)
    end
    if detached then db.tower=originalTower;db.showrooms=db.showrooms or {};db.showrooms[old.id]=originalEntry end
    local painted,why=oldFlooring.paint(old);assert(painted,why)
   end)
  end
  s.hold=tostring(err)..(restored and ' Old showroom restored; no automatic retry.' or ' Partial replacement held; restore verified save backup before retry.')
  print('[Astrolux Replacement] Held: '..s.hold)
 end
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 then return end
 local ok,why=pcall(M.run)
 if not ok then print('[Astrolux Replacement] Preflight error: '..tostring(why))end
end)
return M

