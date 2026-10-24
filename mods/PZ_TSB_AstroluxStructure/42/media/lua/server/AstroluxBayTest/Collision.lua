-- No visible geometry, roof, vehicle changes, or bank dependencies.
local ticks=0;local done=false;local waiting=false;local failed=false
local function run()
 if done or failed or isClient() or isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 if not s or s.stackRevision~=1 or not s.siteX or not s.siteY then return end
 local player=getSpecificPlayer(0);if not player then return end
 if player:getZ()<1 and player:getX()>s.siteX-0.4 and player:getX()<s.siteX+6.4 and player:getY()>s.siteY-0.4 and player:getY()<s.siteY+3.4 then
  if not waiting then print('[Astrolux Bay Collision] Waiting: walk outside the bay before boundaries are installed.');waiting=true end
  return
 end
 local positions={}
 for x=0,5 do for _,y in ipairs({0,3}) do positions[#positions+1]={x=x,y=y,index=0} end end
 for y=0,2 do for _,x in ipairs({0,6}) do positions[#positions+1]={x=x,y=y,index=1} end end
 local pending={};local existing={};local cell=getCell()
 for _,v in ipairs(positions) do
  local sq=cell:getGridSquare(s.siteX+v.x,s.siteY+v.y,0);if not sq then return end
  local name='TSBAstroluxBayCollision_'..v.index;local sp=getSprite(name)
  local flag=v.index==0 and IsoFlagType.collideN or IsoFlagType.collideW
  assert(sp and sp:getProperties():has(flag),'Missing collision tile definition: '..name)
  local found=nil;local objects=sq:getObjects()
  for i=0,objects:size()-1 do
   local obj=objects:get(i)
   if obj:getModData().TSBAstroluxBoundary==name and obj:getSpriteName()==name then found=obj;break end
  end
  if found then existing[#existing+1]=found else pending[#pending+1]={sq=sq,sp=sp,name=name} end
 end
 for _,v in ipairs(pending) do
  local obj=IsoObject.new(cell,v.sq,v.sp)
  obj:getModData().TSBAstroluxBoundary=v.name;obj:setDoRender(false)
  v.sq:AddTileObject(obj);v.sq:RecalcAllWithNeighbours(true)
  obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
 end
 for _,obj in ipairs(existing) do obj:setDoRender(false);obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW) end
 done=true;s.boundaryRevision=1
 print('[Astrolux Bay Collision] Ground enclosure ready: 18 invisible native collision edges; added '..#pending..', retained '..#existing)
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 then return end
 local ok,why=pcall(run)
 if not ok then failed=true;print('[Astrolux Bay Collision] Held: '..tostring(why)) end
end)
return {run=run}
