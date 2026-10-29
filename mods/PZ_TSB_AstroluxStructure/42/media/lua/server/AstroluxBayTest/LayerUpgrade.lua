if isClient() then return end
local oldPlan=require 'AstroluxBayTest/Plan'
local surfaces=require 'AstroluxBayTest/SurfacePlan'
local layers=require 'AstroluxBayTest/LayerPlan'
local ticks=0
local function run()
 if isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local state=ModData.get('TSBAstroluxBayTest.v1')
 if not state or not state.ready or not state.siteX or not state.siteY or state.layerRevision==1 then return end
 -- Only the known pre-mutation missing-sprite failure is safe to retry.
 -- The installed v1 recovery failed in preflight at Val(), before mutation.
 -- Retry that exact logged failure once; retain all other interruption holds.
 if state.layerUpgradeHold=='Object tried to call nil in run java.lang.RuntimeException' and state.surfaceDepthRevision==1 and not state.propertyApiRecovery then
  state.propertyApiRecovery=true
  state.layerUpgradeHold=nil
 end
 if state.layerUpgradeHold then
  if state.surfaceDepthRevision==1 and string.find(tostring(state.layerUpgradeHold),'Old bay sprite missing: TSBAstroluxBaySurface_',1,true) then
   state.layerUpgradeHold=nil
  else return end
 end
 local cell=getCell();local old={};local seen={};local pending={}
 local expected=state.surfaceDepthRevision==1 and surfaces or oldPlan
 local scanned={}
 for _,p in ipairs(expected) do
  -- Rejected legacy tile definitions can leave no saved sprite/object at all.
  -- A loaded ground column is required, but an empty upper square is valid.
  if not cell:getGridSquare(state.siteX+p.x,state.siteY+p.y,0) then return end
  local sq=cell:getGridSquare(state.siteX+p.x,state.siteY+p.y,p.z)
  if state.surfaceDepthRevision==1 then
   if sq and not scanned[sq] then
    scanned[sq]=true
    local list=sq:getObjects()
    for i=0,list:size()-1 do
     local obj=list:get(i);local md=obj:getModData()
     -- Never clear terrain or unrelated objects to recover artwork.
     if md.TSBAstroluxBayTest and md.TSBAstroluxBaySurface==1 and not md.TSBAstroluxBayLayer then
      old[#old+1]={sq=sq,obj=obj}
     end
    end
   end
  else
  if not sq then return end
  local found=nil;local list=sq:getObjects()
  for i=0,list:size()-1 do
   local obj=list:get(i)
   if obj:getModData().TSBAstroluxBayTest and obj:getSprite() and obj:getSprite():getName()==p.sprite then
    assert(not found,'Duplicate old bay sprite; layer migration stopped')
    found=obj
   end
  end
  assert(found,'Old bay sprite missing: '..p.sprite..'; layer migration stopped')
  if not seen[found] then old[#old+1]={sq=sq,obj=found};seen[found]=true end
  end
 end
 for _,p in ipairs(layers) do
  local x,y=state.siteX+p.x,state.siteY+p.y
  if not cell:getGridSquare(x,y,0) then return end
  local sprite=getSprite(p.sprite)
  assert(sprite and sprite:getProperties():get('CustomName')=='Astrolux Test Layer','Tile definition missing: '..p.sprite)
  pending[#pending+1]={x=x,y=y,z=p.z,sprite=sprite,layer=p.layer}
 end
 state.layerUpgradeHold='Layer replacement interrupted; inspect before retrying.'
 local added={}
 local ok,why=pcall(function()
  for _,p in ipairs(pending) do
   local sq=cell:getGridSquare(p.x,p.y,p.z) or cell:createNewGridSquare(p.x,p.y,p.z,true)
   assert(sq,'Layer square unavailable')
   local obj=IsoObject.new(cell,sq,p.sprite)
   obj:getModData().TSBAstroluxBayTest=true
   obj:getModData().TSBAstroluxBayLayer=p.layer
   sq:AddTileObject(obj);added[#added+1]={sq=sq,obj=obj}
   if p.layer=='Glass' then obj:setAlphaAndTarget(0,0);obj:setDoRender(false) end
   obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
  end
 end)
 if not ok then
  for _,v in ipairs(added) do v.sq:RemoveTileObject(v.obj) end
  error(why)
 end
 for _,v in ipairs(old) do v.sq:RemoveTileObject(v.obj);v.sq:RecalcAllWithNeighbours(true) end
 state.layerVisible={Floor=true,Vehicle=true,Frame=true,Glass=false}
 state.layerRevision=1;state.layerUpgradeHold=nil
 print('[Astrolux Bay Test] Independent layers ready: '..#added..' pieces. Glass hidden. Right-click: Test Bay Layers.')
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 then return end
 local ok,why=pcall(run)
 if not ok then
  local state=ModData.get('TSBAstroluxBayTest.v1');if state then state.layerUpgradeHold=tostring(why) end
  print('[Astrolux Bay Test] Layer migration held: '..tostring(why))
 end
end)
