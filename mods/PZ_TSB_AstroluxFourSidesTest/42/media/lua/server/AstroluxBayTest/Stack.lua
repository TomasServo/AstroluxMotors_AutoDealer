if isClient() then return end
local layers=require 'AstroluxBayTest/LayerPlan'
local frames=require 'AstroluxBayTest/StackFramePlan'
local ticks=0
local function run()
 if isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 if not s or s.layerRevision~=1 or s.nativeFloorRevision~=1 or s.stackRevision or s.stackBuildHold or not s.siteX or not s.siteY then return end
 local cell=getCell();local pending={};local old={};local scanned={};local upperFloors={};local lowerCars=0
 local function prepare(p,z,layer)
  local x,y=s.siteX+p.x,s.siteY+p.y
  if not cell:getGridSquare(x,y,0) then return false end
  local sp=getSprite(p.sprite)
  assert(sp and sp:getProperties():get('CustomName')=='Astrolux Test Layer','Missing stack tile definition: '..p.sprite)
  pending[#pending+1]={x=x,y=y,z=z,sprite=sp,layer=layer}
  return true
 end
 for _,p in ipairs(layers) do
  local x,y=s.siteX+p.x,s.siteY+p.y
  if not cell:getGridSquare(x,y,0) then return end
  local sq=cell:getGridSquare(x,y,p.z)
  if sq and not scanned[sq] then
   scanned[sq]=true;local list=sq:getObjects()
   for i=0,list:size()-1 do
    local obj=list:get(i);local md=obj:getModData()
    if md.TSBAstroluxBayTest and not md.TSBAstroluxStack then
     if md.TSBAstroluxBayLayer=='Frame' or md.TSBAstroluxBayLayer=='Glass' then old[#old+1]={sq=sq,obj=obj} end
     if md.TSBAstroluxBayLayer=='Vehicle' then lowerCars=lowerCars+1 end
    end
   end
  end
  if p.layer=='Vehicle' and not prepare(p,p.z+1,'UpperVehicle') then return end
 end
 -- Wait for the baseline car to be restored; never remove or respawn it.
 if lowerCars~=76 then return end
 for level=0,1 do for _,p in ipairs(frames) do if not prepare(p,p.z+level,'StackFrame') then return end end end
 for x=0,5 do for y=0,2 do
  local sq=cell:getGridSquare(s.siteX+x,s.siteY+y,1)
  assert(not sq or not sq:getFloor(),'Existing upper floor; stack build paused')
  upperFloors[#upperFloors+1]={x=s.siteX+x,y=s.siteY+y}
 end end
 assert(getSprite('floors_interior_tilesandwood_01_28'),'Native platform sprite unavailable')
 s.stackBuildHold='Stack placement interrupted; restore backup before retrying.'
 for _,p in ipairs(pending) do
  local sq=cell:getGridSquare(p.x,p.y,p.z) or cell:createNewGridSquare(p.x,p.y,p.z,true)
  assert(sq,'Stack square unavailable')
  local obj=IsoObject.new(cell,sq,p.sprite)
  obj:getModData().TSBAstroluxBayTest=true;obj:getModData().TSBAstroluxStack=p.layer
  sq:AddTileObject(obj);obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
 end
 for _,p in ipairs(upperFloors) do
  local sq=cell:getGridSquare(p.x,p.y,1) or cell:createNewGridSquare(p.x,p.y,1,true)
  local floor=sq:addFloor('floors_interior_tilesandwood_01_28')
  assert(floor,'Platform placement failed')
  floor:getModData().TSBAstroluxStack='Platform'
  floor:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW);sq:RecalcAllWithNeighbours(true)
 end
 for _,v in ipairs(old) do v.sq:RemoveTileObject(v.obj);v.sq:RecalcAllWithNeighbours(true) end
 s.stackRevision=1;s.stackBuildHold=nil;s.glassOverlay=true
 s.layerVisible={Floor=true,Vehicle=true,Frame=true,Glass=false}
 print('[Astrolux Stack Test] Two bays ready: original lower car preserved, upper car same scale, one native 18-tile platform, no world glass.')
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 then return end
 local ok,why=pcall(run)
 if not ok then local s=ModData.get('TSBAstroluxBayTest.v1');if s then s.stackBuildHold=tostring(why) end;print('[Astrolux Stack Test] Held: '..tostring(why)) end
end)
