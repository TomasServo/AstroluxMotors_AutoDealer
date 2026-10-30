-- solidtrans is deliberately traversable beside windows in native collision.
-- Bound owned furniture with collision-only edges; never introduce solid shadows.
if isClient() then return end
local M={tag='TSBAstroluxNativeHelperV1',kind='furnitureEdge'}
local offsets={{0,0,0},{0,0,1},{0,1,0},{1,0,1}}
local function refresh(sq)
 sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
end
local function blocking(o,owner)
 local md=o:getModData();local f=md.movableData and md.movableData.TSBAstroluxFurnishingV1
 if not f or f.tower~=owner then return false end
 local sp=o:getSprite();local name=sp and sp:getName()
 if not name or name:find('furniture_tables_low_',1,true) then return false end
 -- canReachTo treats collision edges as walls. Keep native loot access to
 -- mannequins/counters; kiosk UI uses its own authorized interaction path.
 if instanceof(o,'IsoMannequin') then return false end
 if o.getContainerCount and o:getContainerCount()>0 and not name:match('^TSBAstroluxKiosk_') then return false end
 local chair=tonumber(name:match('^furniture_seating_indoor_02_(%d+)$'))
 return instanceof(o,'IsoThumpable')
  or name=='vegetation_indoor_01_9' or name=='vegetation_indoor_01_11'
  or (chair and chair>=4 and chair<=11)
end
function M.sync(s)
 local cell=getCell();local desired={};local squares={}
 -- Deletion already scans this margin and recognizes the existing owner tag.
 for dx=0,13 do for dy=0,13 do
  local sq=cell:getGridSquare(s.x+dx,s.y+dy,0)
  if not sq then return false end -- Do not prune against a partially loaded site.
  squares[dx..':'..dy]=sq
 end end
 for dx=0,12 do for dy=0,12 do
  local sq=squares[dx..':'..dy];local list=sq:getObjects();local blocks,door=false,false
  for i=0,list:size()-1 do
   local o=list:get(i)
   blocks=blocks or blocking(o,s.recordId)
   door=door or instanceof(o,'IsoDoor')
  end
  if blocks and not door then
   local clear=sq:getMovingObjects():size()==0 and sq:getStaticMovingObjects():size()==0
   for _,v in ipairs(offsets) do
    local key=dx..':'..dy..':'..v[1]..':'..v[2]..':'..v[3]
    desired[key]={sq=squares[(dx+v[1])..':'..(dy+v[2])],axis=v[3],clear=clear}
   end
  end
 end end
 for _,sq in pairs(squares) do
  local list=sq:getObjects()
  for i=list:size()-1,0,-1 do
   local o=list:get(i);local h=o:getModData()[M.tag]
   if h and h.owner==s.recordId and h.kind==M.kind then
    local d=desired[h.edge]
    if not d or d.sq~=sq or d.object then
     sq:transmitRemoveItemFromSquare(o,false);refresh(sq)
    else d.object=o;o:setDoRender(false) end
   end
  end
 end
 for key,d in pairs(desired) do
  if not d.object and d.clear then
   local sprite=assert(getSprite('TSBAstroluxBayCollision_'..d.axis))
   local flag=d.axis==0 and IsoFlagType.collideN or IsoFlagType.collideW
   assert(sprite:getProperties():has(flag),'Furniture boundary tile is missing collision')
   local o=IsoObject.new(cell,d.sq,sprite)
   o:getModData()[M.tag]={owner=s.recordId,kind=M.kind,edge=key}
   o:setDoRender(false);d.sq:AddTileObject(o);refresh(d.sq)
   if isServer() then o:transmitCompleteItemToClients() end
  end
 end
 return true
end
return M
