if isClient() then return end
-- Explicit, bounded clearing for the private placement cursor. Never automatic.
local W=require 'AstroluxBayTest/TestWorld'
local B=require 'AstroluxBayTest/ShowroomBuilder12'
local C={extent=12,maxZ=4};local held=false
local function allowed(player)
 return (W.corner() or W.city()) and player and not player:isDead() and player:getZ()==0
end
local function integer(v)return type(v)=='number' and v==v and math.abs(v)<1000000 and v==math.floor(v)end
local function protected(o)
 local md=o:getModData()
 return md.TSBAstroluxStructure or md.TSBAstroluxFlooring or md.TSBAstroluxDiagonalCornerLab
  or md.TSBAstroluxVend or (md.movableData and md.movableData.TSBAstroluxFurnishingV1)
end
local function inventory(container,out,seen,depth)
 if depth>8 then error('Container nesting is too deep to review.')end
 local list=container:getItems()
 for i=0,list:size()-1 do
  local item=list:get(i);if seen[item] then error('Container contents changed during review.')end
  seen[item]=true;out[#out+1]=item
  if #out>2000 then error('More than 2000 contents in one object; empty it before placement.')end
  if item.getInventory and item:getInventory() then inventory(item:getInventory(),out,seen,depth+1)end
 end
end
local function contents(o)
 local items={};local count=o:getContainerCount()
 for i=0,count-1 do inventory(o:getContainerByIndex(i),items,{},0)end
 if instanceof(o,'IsoWorldInventoryObject')then
  local item=o:getItem();items[#items+1]=item
  if item.getInventory and item:getInventory()then inventory(item:getInventory(),items,{[item]=true},0)end
 end
 return items,count
end
function C.inspect(player,x,y,clear)
 if not allowed(player)then return nil,'Private single-player admin test only.'end
 if not integer(x) or not integer(y) or (player:getX()-x)^2+(player:getY()-y)^2>900 then return nil,'Choose loaded ground within 30 tiles.'end
 local hold=ModData.get('TSBAstroluxPlacementHold.v1')
 if held or (hold and hold.reason)then return nil,'Previous placement needs inspection; restore its checkpoint before another attempt.'end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
  local size=r.combinedSize or 8
  if x<=r.x+size+1 and x+13>=r.x and y<=r.y+size+1 and y+13>=r.y then
   return nil,'Existing Astrolux showroom overlaps this zone. Its furniture and pillars are protected.'
  end
 end
 local review={x=x,y=y,clear=clear==true,objects={},ignored={},containers=0,items=0,created=getTimestampMs()}
 local seen={}
 for z=4,0,-1 do for dx=0,12 do for dy=0,12 do
  local sq=getCell():getGridSquare(x+dx,y+dy,z)
  if sq then
   for _,list in ipairs({sq:getObjects(),sq:getWorldObjects()})do for i=list:size()-1,0,-1 do
    local o=list:get(i)
    if not seen[o] and not(z==0 and o==sq:getFloor())then
     seen[o]=true
     if protected(o)then return nil,'Protected Astrolux object in the zone; choose another location.'end
     if clear then
      local ok,items,count=pcall(contents,o);if not ok then return nil,tostring(items)end
      review.objects[#review.objects+1]={obj=o,sq=sq,index=o:getObjectIndex(),special=sq:getSpecialObjects():contains(o),
       world=instanceof(o,'IsoWorldInventoryObject'),items=items,containers=count,renderYOffset=o:getRenderYOffset()}
      review.ignored[o]=true;review.containers=review.containers+count;review.items=review.items+#items
      if #review.objects>3000 then return nil,'More than 3000 objects in the zone; use a smaller demolition pass first.'end
     end
    end
   end end
  end
 end end end
 -- B42's native remover also removes other pieces of multi-tile furniture.
 -- Require every linked piece inside the reviewed zone before allowing it.
 for _,e in ipairs(review.objects)do
  local sp=e.obj:getSprite();local grid=sp and sp:getSpriteGrid()
  if grid then
   local ax=e.sq:getX()-grid:getSpriteGridPosX(sp);local ay=e.sq:getY()-grid:getSpriteGridPosY(sp)
   if ax<x or ay<y or ax+grid:getWidth()-1>x+12 or ay+grid:getHeight()-1>y+12 then
    return nil,'Multi-tile furniture crosses the highlighted boundary. Move the zone to include the whole object.'
   end
   for gx=0,grid:getWidth()-1 do for gy=0,grid:getHeight()-1 do
    local expected=grid:getSprite(gx,gy);local sq=getCell():getGridSquare(ax+gx,ay+gy,e.sq:getZ())
    local found=false;local list=sq and sq:getObjects()
    if list then for i=0,list:size()-1 do local o=list:get(i)
     if o:getSprite()==expected and review.ignored[o]then found=true end
    end end
    if expected and not found then return nil,'Incomplete multi-tile object; clear or repair it before placement.'end
   end end
  end
 end
 local plan,reason=B.preview(player,x,y,true,nil,review.ignored)
 if not plan then return nil,reason end
 review.plan=plan
 return review
end
function C.same(a,b)
 if a.x~=b.x or a.y~=b.y or a.clear~=b.clear or #a.objects~=#b.objects then return false end
 local previous={};for _,e in ipairs(a.objects)do previous[e.obj]=e end
 for _,e in ipairs(b.objects)do
  local old=previous[e.obj]
  if not old or old.sq~=e.sq or old.index~=e.index or old.containers~=e.containers or #old.items~=#e.items then return false end
  for i,item in ipairs(e.items)do if old.items[i]~=item then return false end end
 end
 return true
end
local function restore(removed)
 for i=#removed,1,-1 do
  local e=removed[i];local o,sq=e.obj,e.sq
  if o:getObjectIndex()<0 then
   if e.special then sq:AddSpecialObject(o,e.index)else sq:AddTileObject(o,e.index)end
   if e.world then
    if not sq:getWorldObjects():contains(o)then sq:getWorldObjects():add(o)end
    o:getItem():setWorldItem(o)
   end
   assert(o:getObjectIndex()>=0,'Object restoration not confirmed')
  end
  o:setRenderYOffset(e.renderYOffset)
  sq:RecalcAllWithNeighbours(true)
 end
end
function C.execute(player,approved,build)
 if type(approved)~='table' or type(approved.created)~='number' or getTimestampMs()-approved.created>120000 then return nil,'Placement review expired; select the location again.'end
 local current,why=C.inspect(player,approved.x,approved.y,approved.clear)
 if not current then return nil,why end
 if not C.same(approved,current)then return nil,'Objects or contents changed since confirmation. Review the site again; nothing removed.'end
 -- Snapshot all members before the first removal, including native cascades.
 local removed=current.objects;local result,reason
 local ok,err=pcall(function()
  for _,e in ipairs(current.objects)do
   if e.obj:getObjectIndex()>=0 then e.sq:RemoveTileObject(e.obj)end
   assert(e.obj:getObjectIndex()<0,'Removal not confirmed')
   if e.world then
    if e.sq:getWorldObjects():contains(e.obj)then e.sq:getWorldObjects():remove(e.obj)end
    e.obj:getItem():setWorldItem(nil)
   end
   e.sq:RecalcAllWithNeighbours(true)
  end
  result,reason=build()
  if not result then error(reason or 'Builder returned no record',0)end
 end)
 if ok then
  print('[Astrolux Placement] Cleared '..#removed..' objects and '..current.items..' contents at '..approved.x..','..approved.y..'; building '..result.id)
  return result
 end
 local partial=false
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
  if r.x==approved.x and r.y==approved.y and r.status=='hold'then partial=true end
 end
 local restored,restoreError=false,nil
 if not partial then restored,restoreError=pcall(restore,removed)end
 if not restored then
  held=true
  ModData.getOrCreate('TSBAstroluxPlacementHold.v1').reason=tostring(err)..'; '..tostring(restoreError or 'Partial new structure remains')
 end
 return nil,tostring(err)..(restored and ' Cleared objects restored.' or ' Placement held; restore the pre-launch checkpoint before retrying.')
end
return C
