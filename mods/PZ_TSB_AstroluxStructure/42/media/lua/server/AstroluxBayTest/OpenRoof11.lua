local P=require 'AstroluxBayTest/ShowroomPlan11'
local M={}
function M.apply(r)
 if r.combinedSize~=11 or r.status~='ready' or r.openRoofRevision then return end
 local cell=getCell();local pending={}
 -- Preflight the whole opening before touching any owned floor.
 for x=1,9 do for y=1,9 do if P.openRoof(x,y) then
  local sq=cell:getGridSquare(r.x+x,r.y+y,1);if not sq then return end
  if sq:getMovingObjects():size()>0 then return end
  local obj=sq:getFloor()
  if obj then
   local md=obj:getModData()
   if md.TSBAstroluxStructure~=r.id or md.TSBAstroluxStructureKind~='floor' then return end
   pending[#pending+1]={sq=sq,obj=obj,sprite=obj:getSprite():getName(),x=x,y=y}
  end
 end end end
 r.openRoofBackup=r.openRoofBackup or {}
 local removed={}
 local ok,why=pcall(function()
  for _,e in ipairs(pending)do
   e.sq:RemoveTileObject(e.obj);removed[#removed+1]=e
   assert(e.obj:getObjectIndex()<0,'Ceiling removal failed')
   e.sq:RecalcAllWithNeighbours(true)
  end
 end)
 if not ok then
  for _,e in ipairs(removed)do if e.obj:getObjectIndex()<0 then e.sq:AddTileObject(e.obj)end;e.sq:RecalcAllWithNeighbours(true)end
  print('[Astrolux Open Roof] Rolled back: '..tostring(why));return
 end
 for _,e in ipairs(pending)do r.openRoofBackup[#r.openRoofBackup+1]={x=e.x,y=e.y,sprite=e.sprite}end
 r.openRoofRevision=1
 print('[Astrolux Open Roof] Interior opening ready; '..#pending..' owned ceiling tiles removed.')
end
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or isClient() or isServer() or not getWorld()
 or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do M.apply(r)end
end)
return M
