-- Retire only the separate two-cube scale study in the named single-player lab.
if isClient() then return end
local plans={require 'AstroluxBayTest/Plan',require 'AstroluxBayTest/SurfacePlan',require 'AstroluxBayTest/LayerPlan',require 'AstroluxBayTest/StackFramePlan'}
local done=false
local function run()
 if done or isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 if not s then return end
 if s.testCubesRetired then done=true;return end
 if not s.ready or s.stackRevision~=1 or not s.siteX or not s.siteY then return end
 local cell=getCell();if not cell then return end
 local positions={}
 local function add(x,y,z) positions[x..':'..y..':'..z]={x=x,y=y,z=z} end
 for _,plan in ipairs(plans) do for _,p in ipairs(plan) do
  add(s.siteX+p.x,s.siteY+p.y,p.z)
  add(s.siteX+p.x,s.siteY+p.y,p.z+1)
 end end
 for x=0,6 do for y=0,3 do for z=0,1 do add(s.siteX+x,s.siteY+y,z) end end end
 local pending={};local seen={}
 for _,p in pairs(positions) do
  if not cell:getGridSquare(p.x,p.y,0) then return end
  local sq=cell:getGridSquare(p.x,p.y,p.z)
  if sq then
   local objects=sq:getObjects()
   for i=0,objects:size()-1 do
    local obj=objects:get(i);local md=obj:getModData()
    if not seen[obj] and (md.TSBAstroluxBayTest or md.TSBAstroluxStack or md.TSBAstroluxBoundary) then
     -- Ground terrain, real vehicles and untagged/player objects are retained.
     if obj~=sq:getFloor() or (p.z==1 and md.TSBAstroluxStack=='Platform') then
      pending[#pending+1]={sq=sq,obj=obj};seen[obj]=true
     end
    end
   end
  end
 end
 for _,v in ipairs(pending) do
  v.obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
  v.sq:RemoveTileObject(v.obj);v.sq:RecalcAllWithNeighbours(true)
 end
 s.retiredTestCubeSite={x=s.siteX,y=s.siteY,removed=#pending}
 s.testCubesRetired=true;s.siteX=nil;s.siteY=nil
 -- Missing site disables old builders, cutaway and transient test lights.
 -- ready remains true so Setup never creates another study or comparison car.
 done=true
 print('[Astrolux Test Cubes] Retired '..#pending..' tagged pieces; main tower and real vehicles preserved.')
end
Events.OnTick.Add(run)
return {run=run}
