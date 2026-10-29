-- Private diagnostic: absence means removed IsoObjects, never alpha-only hiding.
local plan=require 'AstroluxBayTest/LayerPlan'
local active={Vehicle=true,Frame=true,Glass=true}
local ticks=0;local initialized=false;local sequence=nil;local nextTime=0
local stages={
 {name='1: Vehicle + Frame (Glass Removed)',Vehicle=true,Frame=true},
 {name='2: Frame Only (Vehicle Removed)',Frame=true},
 {name='3: Vehicle Only (Frame Removed)',Vehicle=true},
 {name='4: Native Floor Only (All Decorative Layers Removed)'},
 {name='5: Restored Vehicle + Frame',Vehicle=true,Frame=true},
}
local function state()
 if isClient() or isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return nil end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 if s and not s.stackRevision and not s.stackBuildHold and s.layerRevision==1 and s.nativeFloorRevision==1 and s.siteX and s.siteY then return s end
end
local function announce(message)
 print('[Astrolux Shadow Test] '..message)
 local player=getPlayer();if player then player:Say(message) end
end
local function redraw(s)
 -- Rebuild loaded squares and request chunk redraws around the bay/downwind.
 -- Removal/addition also runs native object-change invalidation.
 for x=s.siteX-16,s.siteX+22 do for y=s.siteY-16,s.siteY+22 do
  for z=0,2 do
   local sq=getCell():getGridSquare(x,y,z)
   if sq then
    sq:RecalcAllWithNeighbours(true)
    sq:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
   end
  end
 end end
end
local function apply(mode)
 local s=state();if not s then return false end
 if s.glassEffect==nil then s.glassEffect=true end
 local cell=getCell();local expected={};local found={};local remove={};local add={};local squares={}
 -- Preflight every placement before any change; restore from unchanged sprites.
 for _,p in ipairs(plan) do
  if active[p.layer] then
   local x,y=s.siteX+p.x,s.siteY+p.y
   if not cell:getGridSquare(x,y,0) then announce('Waiting for test area to load');return false end
   local key=x..':'..y..':'..p.z
   expected[p.sprite]={p=p,x=x,y=y,key=key}
   squares[key]={x=x,y=y,z=p.z}
   if mode[p.layer] then
    local sp=getSprite(p.sprite)
    if not sp or sp:getProperties():get('CustomName')~='Astrolux Test Layer' then
     announce('Stopped: missing tile definition '..p.sprite);return false
    end
   end
  end
 end
 for key,pos in pairs(squares) do
  local sq=cell:getGridSquare(pos.x,pos.y,pos.z)
  if sq then
   local list=sq:getObjects()
   for i=0,list:size()-1 do
    local obj=list:get(i);local md=obj:getModData();local sp=obj:getSprite()
    local entry=sp and expected[sp:getName()]
    if md.TSBAstroluxBayTest and entry and entry.key==key and md.TSBAstroluxBayLayer==entry.p.layer then
     if not mode[entry.p.layer] or found[sp:getName()] then
      remove[#remove+1]={sq=sq,obj=obj}
     else found[sp:getName()]=obj end
    end
   end
  end
 end
 for name,entry in pairs(expected) do
  if mode[entry.p.layer] and not found[name] then add[#add+1]=entry end
 end
 local created={}
 local ok,why=pcall(function()
  for _,entry in ipairs(add) do
   local p=entry.p
   local sq=cell:getGridSquare(entry.x,entry.y,p.z) or cell:createNewGridSquare(entry.x,entry.y,p.z,true)
   assert(sq,'Unable to restore layer square')
   local obj=IsoObject.new(cell,sq,getSprite(p.sprite))
   obj:getModData().TSBAstroluxBayTest=true;obj:getModData().TSBAstroluxBayLayer=p.layer
   sq:AddTileObject(obj);created[#created+1]={sq=sq,obj=obj};found[p.sprite]=obj
  end
 end)
 if not ok then
  for _,v in ipairs(created) do v.sq:RemoveTileObject(v.obj) end
  announce('Restore stopped: '..tostring(why));return false
 end
 for _,v in ipairs(remove) do v.sq:RemoveTileObject(v.obj) end
 for _,obj in pairs(found) do
  for i=0,getNumActivePlayers()-1 do obj:setAlphaAndTarget(i,1) end
  obj:setDoRender(true);obj:setSceneCulled(false)
  -- Fully opaque color modulation: no pane objects, alpha or depth changes.
  if obj:getModData().TSBAstroluxBayLayer=='Vehicle' then
   obj:setCustomColor(ColorInfo.new(1,1,1,1))
   obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
  end
 end
 s.layerVisible={Floor=true,Vehicle=mode.Vehicle==true,Frame=mode.Frame==true,Glass=mode.Glass==true}
 redraw(s)
 announce(mode.name..' — removed '..#remove..', restored '..#created..'; area redraw requested')
 return true
end
local function manual(mode)
 sequence=nil
 local ok,why=pcall(apply,mode)
 if not ok then announce('Stopped: '..tostring(why)) end
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%30~=0 or not state() then return end
 if not initialized then
  initialized=true
  -- Always recover a stopped/reloaded test to its working baseline.
  manual(stages[1])
 end
 if sequence and getTimestampMs()>=nextTime then
  local index=sequence
  local ok,result=pcall(apply,stages[index])
  if not ok or not result then sequence=nil;announce('Sequence stopped; use Restore Vehicle + Frame')
  elseif index==#stages then sequence=nil;announce('Sequence complete')
  else sequence=index+1;nextTime=getTimestampMs()+30000 end
 end
end)
Events.OnFillWorldObjectContextMenu.Add(function(player,context,objects,test)
 if test or not state() then return end
 local option=context:addOption('Test Bay Shadows')
 local sub=ISContextMenu:getNew(context);context:addSubMenu(option,sub)
 sub:addOption('Run All Stages (30 Seconds Each)',nil,function()sequence=1;nextTime=0 end)
 sub:addOption('Pause Sequence',nil,function()sequence=nil;announce('Paused')end)
 for _,mode in ipairs(stages) do sub:addOption(mode.name,mode,manual) end
 sub:addOption('Restore Vehicle + Frame',stages[5],manual)
 local s=state()
 sub:addOption(s.glassOverlay~=false and 'Hide Glass Overlay' or 'Show Blue-Gray Glass Overlay',nil,function()
  local current=state();if not current then return end
  current.glassOverlay=current.glassOverlay==false
  manual(stages[1])
 end)
end)
return {apply=apply,stages=stages}
