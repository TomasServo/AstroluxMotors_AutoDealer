-- Test-save-only whole-frame fallback using PZ's native orphan-structure cutaway flag.
local plan=require 'AstroluxBayTest/StackFramePlan'
local layers=require 'AstroluxBayTest/LayerPlan'
local M={visible={[0]=false,[1]=false},ready=false,outline=false,contents=false}
AstroluxStackCutaway=M
local touched={};local failed=false;local ticks=0
local nearPerimeter=false
local function state()
 if isClient() or isServer() or getNumActivePlayers()~=1 or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 if s and s.stackRevision==1 and s.siteX and s.siteY then return s end
end
local function visible(sq) return sq~=nil end
local function restore()
 for obj,original in pairs(touched) do
  obj:setDoRender(original);obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
 end
 touched={};nearPerimeter=false;M.ready=false;M.outline=false;M.contents=false
end
function M.update()
 local s=state()
 -- PZ's Lua environment does not provide next(). restore safely handles an
 -- empty table and clears all cached visibility after the test bay retires.
 if not s then restore();return end
 local cell=getCell();local nextVisible={};local groups={[0]={},[1]={}}
 local player=getSpecificPlayer(0)
 if not player then return end
 local x,y=player:getX()-s.siteX,player:getY()-s.siteY
 local inside=x>0 and x<6 and y>0 and y<3
 -- This isolated test bay uses its own footprint, not private renderer state.
 local collapse=inside and player:getZ()==0
 -- Keep the masked overlay around exterior corners even when native cutaway clears.
 -- Hysteresis avoids repeatedly swapping native and overlay frames at the boundary.
 local dx=math.max(0,-x,x-6);local dy=math.max(0,-y,y-3)
 local radius=nearPerimeter and 1.25 or 0.75
 nearPerimeter=not inside and player:getZ()==0 and dx*dx+dy*dy<=radius*radius
 -- Keep the distinct upper-car preview consistent at every exterior distance, including tiled-floor comparisons.
 local outline=not inside and player:getZ()==0
 -- Complete reads before changing render flags, so API failure cannot leave half a bay hidden.
 for level=0,1 do
  local all=true;local scanned={};local expected={}
  for _,p in ipairs(plan) do
   local z=p.z+level;local key=(s.siteX+p.x)..':'..(s.siteY+p.y)..':'..z
   if not expected[key] then expected[key]={} end
   expected[key][p.sprite]=true
   if not scanned[key] then
    local sq=cell:getGridSquare(s.siteX+p.x,s.siteY+p.y,z)
    scanned[key]=sq or false
    if not visible(sq) then all=false end
   end
  end
  for key,sq in pairs(scanned) do
   if sq then
    local objects=sq:getObjects()
    for i=0,objects:size()-1 do
     local obj=objects:get(i)
     if obj:getModData().TSBAstroluxStack=='StackFrame' and expected[key][obj:getSpriteName()] then
      groups[level][#groups[level]+1]=obj
     end
    end
   end
  end
  -- Include the bay's native floor/platform, not just its frame anchors.
  for x=0,5 do for y=0,2 do
   if not visible(cell:getGridSquare(s.siteX+x,s.siteY+y,level)) then all=false end
  end end
  nextVisible[level]=(not collapse or outline) and all and #groups[level]==#plan
 end
 -- Collect only the tagged upper car and platform. Never touch the lower car.
 local upper={};local seen={};local cars=0;local floors=0
 local function collect(x,y,z)
  local sq=cell:getGridSquare(x,y,z)
  if not sq or seen[sq] then return end
  seen[sq]=true
  local list=sq:getObjects()
  for i=0,list:size()-1 do
   local obj=list:get(i);local tag=obj:getModData().TSBAstroluxStack
   if tag=='UpperVehicle' or tag=='Platform' then
    upper[#upper+1]=obj
    if tag=='UpperVehicle' then cars=cars+1 else floors=floors+1 end
   end
  end
 end
 for _,v in ipairs(layers) do if v.layer=='Vehicle' then collect(s.siteX+v.x,s.siteY+v.y,v.z+1) end end
 for x=0,5 do for y=0,2 do collect(s.siteX+x,s.siteY+y,1) end end
 local contents=outline and nextVisible[1] and cars==76 and floors==18
 if contents then assert(getTexture('media/textures/AstroluxBayBlueSedan.png'),'Upper vehicle fallback texture missing') end
 for _,obj in ipairs(upper) do
  if touched[obj]==nil then touched[obj]=obj:getDoRender() end
  local wanted=not contents and touched[obj]
  if obj:getDoRender()~=wanted then obj:setDoRender(wanted);obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW) end
 end
 for level=0,1 do
  for _,obj in ipairs(groups[level]) do
   if touched[obj]==nil then touched[obj]=obj:getDoRender() end
   local wanted=not collapse and not outline and nextVisible[level] and touched[obj]
   if obj:getDoRender()~=wanted then
    obj:setDoRender(wanted);obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
   end
  end
 end
 if not M.ready or M.visible[0]~=nextVisible[0] or M.visible[1]~=nextVisible[1] then
  print('[Astrolux Stack Cutaway] Lower='..tostring(nextVisible[0])..' Upper='..tostring(nextVisible[1]))
 end
 M.visible=nextVisible;M.outline=outline;M.contents=contents;M.ready=true
end
Events.OnTick.Add(function()
 ticks=ticks+1;if failed or ticks%6~=0 then return end
 local ok,why=pcall(M.update)
 if not ok then
  failed=true;pcall(restore);M.ready=false
  print('[Astrolux Stack Cutaway] Disabled; original frame rendering restored: '..tostring(why))
 end
end)
return M
