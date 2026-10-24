-- Local test-world surface correction. No objects removed and no room IDs invented.
local detached={};local inspected={};
local M={};local ticks=0;local tracked={};local hidden={};local reported=false;local failed=false
local function dirty(obj)
 obj:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
end
local function restoreAttachments(floor)
 local entries=detached[floor]
 if not entries then return end
 for _,entry in ipairs(entries)do floor:addAttachedAnimSpriteInstance(entry) end
 dirty(floor);detached[floor]=nil
end
local function restore()
 for floor in pairs(detached)do restoreAttachments(floor)end
 for obj,old in pairs(hidden)do obj:setDoRender(old);dirty(obj)end
 for sq,wasOutside in pairs(tracked)do
  if wasOutside then sq:getProperties():set(IsoFlagType.exterior) end
  sq:clearPuddles()
  local floor=sq:getFloor();if floor then dirty(floor)end
 end
 hidden={};tracked={}
end
local function dirt(name)
 if type(name)~='string' then return false end
 -- Explicit dirt/debris families only; preserve manholes, markings and fixtures.
 return name:match('^overlay_grime_') or name:match('^trash_')
  or name:match('^trash&junk_') or name:match('^d_floorleaves_')
  or name:match('^d_trash_') or name:match('^LS_Scraps_')
  or name=='street_decoration_01_41' or name=='street_decoration_01_42'
end
function M.update()
 if isClient() or isServer() or not getDebug() or not getWorld()
 or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then restore();return end
 local s=ModData.get('TSBAstroluxCombined12.v1')
 if not s or not s.ready or not s.recordId then restore();return end
 local cell=getCell();if not cell then return end
 local active={};local activeObjects={};local count=0;local concealed=0
 for dx=0,11 do for dy=0,11 do
  local sq=cell:getGridSquare(s.x+dx,s.y+dy,0)
  local floor=sq and sq:getFloor()
  if floor and floor:getModData().TSBAstroluxFlooring==s.recordId then
   active[sq]=true;count=count+1
   local attachments=floor:getAttachedAnimSprite()
   if attachments then for i=attachments:size()-1,0,-1 do
    local instance=attachments:get(i);local sprite=instance:getParentSprite()
    local name=sprite and sprite:getName()
    if name and (dirt(name) or name:match('^blends_natural_')) then
     detached[floor]=detached[floor] or {}
     table.insert(detached[floor],1,instance)
     attachments:remove(instance);dirty(floor)
     print('[Astrolux Showroom Surface] Concealed floor attachment '..name..' at '..(s.x+dx)..','..(s.y+dy))
    elseif name and not inspected['attached:'..name]then
     inspected['attached:'..name]=true;print('[Astrolux Surface Inspect] floor attachment '..name)
    end
   end end
   local overlay=floor:getOverlaySprite()
   if overlay and not inspected['overlay:'..overlay:getName()]then
    inspected['overlay:'..overlay:getName()]=true;print('[Astrolux Surface Inspect] floor overlay '..overlay:getName())
   end
   if tracked[sq]==nil then tracked[sq]=sq:isOutside() end
   -- Native puddle geometry and isOutside() both read this square-local flag.
   -- Shared tile sprites and global rain settings are never modified.
   if sq:isOutside() then
    sq:getProperties():unset(IsoFlagType.exterior)
    sq:clearPuddles();dirty(floor)
   end
   local objects=sq:getObjects()
   for i=0,objects:size()-1 do
    local obj=objects:get(i);local sprite=obj:getSprite()
    if obj~=floor and sprite and not inspected['object:'..sprite:getName()]then
     inspected['object:'..sprite:getName()]=true
     print('[Astrolux Surface Inspect] object '..sprite:getName()..' type='..tostring(obj:getObjectName())..' floor='..tostring(obj:isFloor()))
    end
    if obj~=floor and not obj:isFloor() and not instanceof(obj,'IsoMovingObject')
    and obj:getContainerCount()==0 and sprite and dirt(sprite:getName()) then
     activeObjects[obj]=true;concealed=concealed+1
     if hidden[obj]==nil then hidden[obj]=obj:getDoRender() end
     if obj:getDoRender() then obj:setDoRender(false);dirty(obj) end
    end
   end
  end
 end end
 for floor in pairs(detached)do
  if floor:getModData().TSBAstroluxFlooring~=s.recordId then restoreAttachments(floor)end
 end
 for obj,old in pairs(hidden)do
  if not activeObjects[obj] then obj:setDoRender(old);dirty(obj);hidden[obj]=nil end
 end
 for sq,wasOutside in pairs(tracked)do
  if not active[sq] then
   if wasOutside then sq:getProperties():set(IsoFlagType.exterior)end
   sq:clearPuddles();local floor=sq:getFloor();if floor then dirty(floor)end
   tracked[sq]=nil
  end
 end
 if count==144 and not reported then
  reported=true;print('[Astrolux Showroom Surface] 144 owned floor squares protected from exterior puddles; '..concealed..' dirt decorations hidden.')
 end
end
Events.OnTick.Add(function()
 ticks=ticks+1;if failed or ticks%15~=0 then return end
 local ok,err=pcall(M.update)
 if not ok then failed=true;pcall(restore);print('[Astrolux Showroom Surface] '..tostring(err))end
end)
M.restore=restore
return M
