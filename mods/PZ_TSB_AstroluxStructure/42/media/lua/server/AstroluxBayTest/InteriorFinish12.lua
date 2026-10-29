local M={};local ticks=0
local white='floors_interior_tilesandwood_01_11'
function M.apply(r)
 if r.combinedSize~=12 or r.status~='ready' or r.interiorFinishRevision then return end
 local cell=getCell();local pending={};local ceilings={}
 local art=getSprite(white);if not art or art:getName()~=white then return end
 for dx=1,10 do for dy=1,10 do
  local sq=cell:getGridSquare(r.x+dx,r.y+dy,0);local obj=sq and sq:getFloor()
  if not obj or obj:getModData().TSBAstroluxFlooring~=r.id then return end
  local name=obj:getSprite():getName()
  if name~='floors_interior_tilesandwood_01_28' and name~=white then return end
  pending[#pending+1]={sq=sq,obj=obj,old=obj:getSprite(),x=r.x+dx,y=r.y+dy}
 end end
 for _,c in ipairs({{0,0},{9,0},{0,9},{9,9}})do for dx=0,2 do for dy=0,2 do
  local x,y=r.x+c[1]+dx,r.y+c[2]+dy
  if not cell:getGridSquare(x,y,0) then return end
  local sq=cell:getGridSquare(x,y,1)
  if sq then
   if sq:getMovingObjects():size()>0 or sq:getWorldObjects():size()>0 then return end
   local obj=sq:getFloor()
   if obj then
    local md=obj:getModData()
    if md.TSBAstroluxStructure~=r.id or md.TSBAstroluxStructureKind~='floor' then return end
    if sq:getObjects():size()>1 then return end
    ceilings[#ceilings+1]={sq=sq,obj=obj,x=x,y=y,sprite=obj:getSprite():getName()}
   end
  end
 end end end
 local painted,removed={},{}
 local ok,err=pcall(function()
  for _,e in ipairs(pending)do
   painted[#painted+1]=e;e.obj:setSprite(art);e.sq:RecalcAllWithNeighbours(true)
   e.obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
  end
  for _,e in ipairs(ceilings)do
   removed[#removed+1]=e;e.sq:RemoveTileObject(e.obj)
   assert(e.obj:getObjectIndex()<0,'Corner ceiling removal failed');e.sq:RecalcAllWithNeighbours(true)
  end
 end)
 if not ok then
  local restored=pcall(function()
   for _,e in ipairs(painted)do e.obj:setSprite(e.old);e.sq:RecalcAllWithNeighbours(true);e.obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)end
   for _,e in ipairs(removed)do if e.obj:getObjectIndex()<0 then e.sq:AddTileObject(e.obj)end;e.sq:RecalcAllWithNeighbours(true)end
  end)
  if not restored then r.status='hold' end
  print('[Astrolux Interior Finish] Failed; rollback='..tostring(restored)..': '..tostring(err));return
 end
 -- Keep original restoration history, but mark our new target as the owned finish.
 if r.flooring and r.flooring.tiles then
  for _,t in ipairs(r.flooring.tiles)do
   if t.x>r.x and t.x<r.x+11 and t.y>r.y and t.y<r.y+11 then t.to=white end
  end
 end
 r.cornerCeilingBackup={}
 for _,e in ipairs(ceilings)do r.cornerCeilingBackup[#r.cornerCeilingBackup+1]={x=e.x,y=e.y,z=1,sprite=e.sprite}end
 r.interiorFinishRevision=1
 print('[Astrolux Interior Finish] White interior floor, original dark border, open ceiling corners ready.')
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or isClient() or isServer() or not getDebug() or not getWorld()
 or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do M.apply(r)end
end)
return M
