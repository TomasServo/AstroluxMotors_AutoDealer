-- The native floor already exists. Retire only the diagnostic floor artwork.
if isClient() then return end
local plan=require 'AstroluxBayTest/LayerPlan'
local ticks=0
local function run()
 if isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 if not s or s.layerRevision~=1 or s.nativeFloorRevision==1 or s.nativeFloorHold then return end
 if not s.siteX or not s.siteY then return end
 local cell=getCell();local scanned={};local remove={};local affected={}
 -- Require the whole native support floor before removing any artwork.
 for dx=0,5 do for dy=0,2 do
  local sq=cell:getGridSquare(s.siteX+dx,s.siteY+dy,0)
  if not sq or not sq:getFloor() then return end
 end end
 for _,p in ipairs(plan) do
  if p.layer=='Floor' then
   if not cell:getGridSquare(s.siteX+p.x,s.siteY+p.y,0) then return end
   local sq=cell:getGridSquare(s.siteX+p.x,s.siteY+p.y,p.z)
   if sq and not scanned[sq] then
    scanned[sq]=true
    local list=sq:getObjects()
    for i=0,list:size()-1 do
     local obj=list:get(i);local md=obj:getModData();local sp=obj:getSprite()
     if obj~=sq:getFloor() and md.TSBAstroluxBayTest and md.TSBAstroluxBayLayer=='Floor' and sp and string.find(sp:getName(),'TSBAstroluxLayerFloor',1,true)==1 then
      remove[#remove+1]={sq=sq,obj=obj};affected[sq]=true
     end
    end
   end
  end
 end
 for _,v in ipairs(remove) do
  v.obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
  v.sq:RemoveTileObject(v.obj)
 end
 for sq in pairs(affected) do
  sq:RecalcAllWithNeighbours(true)
  local floor=sq:getFloor()
  if floor then floor:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW) end
 end
 s.nativeFloorRevision=1
 s.layerVisible={Floor=true,Vehicle=true,Frame=true,Glass=false}
 print('[Astrolux Bay Test] Native floor active; removed '..#remove..' tagged floor fragments. Vehicle and frame preserved.')
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%120~=0 then return end
 local ok,why=pcall(run)
 if not ok then
  local s=ModData.get('TSBAstroluxBayTest.v1');if s then s.nativeFloorHold=tostring(why) end
  print('[Astrolux Bay Test] Native floor recovery held: '..tostring(why))
 end
end)
