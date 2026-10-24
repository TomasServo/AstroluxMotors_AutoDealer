local M={}
function M.rim(x,y)return x<2 or x>8 or y<2 or y>8 end
function M.apply(r)
 if r.combinedSize~=11 or r.status~='ready' or not r.openRoofRevision or r.roofRim2Revision then return end
 local cell=getCell();local pending={}
 for x=0,10 do for y=0,10 do if M.rim(x,y)then
  local sq=cell:getGridSquare(r.x+x,r.y+y,1);if not sq then return end
  -- Only fill missing floors. Existing floors and their contents stay untouched.
  if not sq:getFloor()then pending[#pending+1]={sq=sq}end
 end end end
 local made={}
 local ok,why=pcall(function()
  for _,e in ipairs(pending)do
   local obj=e.sq:addFloor('floors_interior_tilesandwood_01_28');assert(obj,'Floor creation failed')
   made[#made+1]={sq=e.sq,obj=obj}
   local md=obj:getModData();md.TSBAstroluxStructure=r.id;md.TSBAstroluxStructureKind='floor'
   e.sq:RecalcAllWithNeighbours(true)
  end
 end)
 if not ok then
  for _,e in ipairs(made)do e.sq:RemoveTileObject(e.obj);e.sq:RecalcAllWithNeighbours(true)end
  print('[Astrolux Roof Rim] Rolled back: '..tostring(why));return
 end
 r.roofRim2Revision=1
 print('[Astrolux Roof Rim] Two-tile perimeter ready; '..#made..' gray floor tiles restored.')
end
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 or isClient() or isServer() or not getWorld()
 or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do M.apply(r)end
end)
return M
