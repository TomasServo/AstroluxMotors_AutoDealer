-- Approved diagonal appearance on the existing private showroom.
-- Default applies only to the exact accepted site; menu choices persist per site.
-- Furniture, containers, inventories and native window collision are untouched.
-- This view changes only glass rendering. The canopy preview also temporarily
-- removes generated ground supports and their blockers through FurnitureSolid.
if TSBAstroluxShowroomDiagonalPreview then return TSBAstroluxShowroomDiagonalPreview end
require 'ISUI/ISUIElement'
local P=require 'AstroluxDiagonalLab/Plan'
local native=require 'AstroluxBayTest/ShowroomGlassVisibility'
local M={enabled=false,hidden={},targets={},straight={},doors={},corners={
 {name='NW',a={0,3},b={3,0}}, {name='NE',a={9,0},b={12,3}},
 {name='SE',a={12,9},b={9,12}}, {name='SW',a={3,12},b={0,9}},
}}
TSBAstroluxShowroomDiagonalPreview=M
local View=ISUIElement:derive('AstroluxShowroomDiagonalPreview')
local hiddenAlpha={}
local lastScan
local selectedId,selectedX,selectedY
M.preferenceKey="TSBAstroluxDiagonalAppearance.v1"
function M.site()
 if not P.runtimeEnabled() then return nil end
 local s=ModData.get('TSBAstroluxCombined12.v1')
 local c=ModData.get('TSBAstroluxCityPerformance.v1')
 if not s or not s.ready or not s.recordId or not c or c.recordId~=s.recordId
  or c.x~=s.x or c.y~=s.y then return nil end
 return s
end
function M.isCornerWindow(o,s)
 if not o or o:getObjectIndex()<0 then return false end
 local sq=o:getSquare();if not sq or sq:getZ()~=0 then return false end
 local md=o:getModData();local sp=o:getSprite();local name=sp and sp:getName()
 if md.TSBAstroluxStructure~=s.recordId then return false end
 if md.TSBAstroluxCornerCollisionV1 and md.TSBAstroluxCornerCollisionV1.owner==s.recordId then return true end
 local x,y=sq:getX()-s.x,sq:getY()-s.y
 if md.TSBAstroluxStructureKind=='corner' then
  return (name=='TSBAstroluxClearGlass_3' or name=='TSBAstroluxClearGlass_15') and x==12 and y==12
 end
 if md.TSBAstroluxStructureKind~='window' or not instanceof(o,'IsoWindow') then return false end
 if o:isDestroyed() then return false end
 local ending=function(n)return n>=0 and n<12 and (n<3 or n>=9)end
 return (name=='TSBAstroluxClearGlass_1' and o:getNorth() and (y==0 or y==12) and ending(x))
  or (name=='TSBAstroluxClearGlass_0' and not o:getNorth() and (x==0 or x==12) and ending(y))
end
local function dirty(o)
 o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)
 local sq=o:getSquare()
 if sq then sq:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)end
end
local function restoreObject(o,old)
 if o:getObjectIndex()>=0 then
  o:setDoRender(old)
  for index,alpha in pairs(hiddenAlpha[o]or {})do
   o:setAlpha(index,alpha.current);o:setTargetAlpha(index,alpha.target)
  end
  dirty(o)
 end
 hiddenAlpha[o]=nil
end
function M.restore()
 for o,old in pairs(M.hidden) do restoreObject(o,old)end
 M.hidden={};M.targets={};M.straight={};M.doors={};lastScan=nil
end
function M.discover(s)
 local found={};local straight={};local doors={}
 for x=0,12 do for y=0,12 do
  do -- Relocated corner windows also occupy interior anchor squares.
   local sq=getCell():getGridSquare(s.x+x,s.y+y,0)
   if sq then local objects=sq:getObjects();for i=0,objects:size()-1 do
    local o=objects:get(i)
    if M.isCornerWindow(o,s)then found[o]=true
    else
     local md=o:getModData();local sp=o:getSprite();local name=sp and sp:getName()
     if md.TSBAstroluxStructure==s.recordId and md.TSBAstroluxStructureKind=='window'
      and name and name:match('^TSBAstroluxClearGlass_') and instanceof(o,'IsoWindow')then straight[o]=true end
     if md.TSBAstroluxStructure==s.recordId and md.TSBAstroluxStructureKind=='slidingDoor'
      and name and name:match('^TSBAstroluxSlidingDoor_') and instanceof(o,'IsoDoor')then doors[o]=true end
    end
   end end
  end
 end end
 for o,old in pairs(M.hidden)do if not found[o] and not straight[o]then
  restoreObject(o,old);M.hidden[o]=nil
 end end
 M.targets=found;M.straight=straight;M.doors=doors
end
function M.update()
 if not TSBAstroluxNativeFramesReady then M.restore();return end
 local s=M.enabled and M.site();local p=getSpecificPlayer(0)
 if not s or not p or p:getZ()~=0 or (p:getX()-s.x)^2+(p:getY()-s.y)^2>3600 then M.restore();return end
 local now=getTimestampMs()
 if not lastScan or now-lastScan>=500 then M.discover(s);lastScan=now end
 for o in pairs(M.targets)do
  if M.isCornerWindow(o,s)then
   if M.hidden[o]==nil then M.hidden[o]=o:getDoRender() end
   local changed=false
   -- Match ReleaseNativeView: exclude the pane from rendering rather than
   -- continually forcing alpha, which the native cutaway pass recalculates.
   if o:getDoRender()then o:setDoRender(false);changed=true end
   if changed then dirty(o)end
  end
 end
 -- NativeGlassFrames already supplies these exact straight-window frames.
 -- Retaining the source artwork also invokes the engine's interior cutaway
 -- outline pass. Hide only intact owned window art; retain the IsoWindows,
 -- collision, broken-glass artwork, and moving door leaves.
 for o in pairs(M.straight)do if o:getObjectIndex()>=0 then
  if not o:isDestroyed()then
   if M.hidden[o]==nil then M.hidden[o]=o:getDoRender()end
   if o:getDoRender()then o:setDoRender(false);dirty(o)end
  elseif M.hidden[o]~=nil then
   restoreObject(o,M.hidden[o]);M.hidden[o]=nil
  end
 end end
end
-- Re-read the selected layout when the active showroom changes or reloads.
-- Old sites and new pastes do not inherit the accepted site's default.
function M.syncSelection()
 local s=M.site()
 if not s then
  if selectedId then M.restore();M.enabled=false;selectedId=nil;selectedX=nil;selectedY=nil end
  return nil
 end
 if selectedId==s.recordId and selectedX==s.x and selectedY==s.y then return s end
 M.restore();selectedId=s.recordId;selectedX=s.x;selectedY=s.y
 local choices=ModData.get(M.preferenceKey)
 local chosen=choices and choices[s.recordId]
 if type(chosen)~='boolean' then
  chosen=require('AstroluxBayTest/TestWorld').freshLot() or (s.recordId=='structure:10275:9261' and s.x==10275 and s.y==9261)
 end
 M.enabled=chosen
 return s
end
-- The provider otherwise makes every owned clear pane visible each render.
-- Delegate to it outside this preview. While enabled, perform one visibility
-- pass so concealed corners never flip visible/hidden and rebuild every frame.
local originalUpdate=native.update
local function combinedUpdate()
 M.syncSelection()
 if M.enabled and M.site()then M.update()else M.restore();originalUpdate()end
end
Events.OnRenderTick.Remove(originalUpdate)
native.update=combinedUpdate
Events.OnRenderTick.Add(combinedUpdate)
function View:onMouseDown()return false end
function View:onMouseUp()return false end
function View:onRightMouseDown()return false end
function View:onRightMouseUp()return false end
function View:onMouseMove()return false end
function View:onMouseWheel()return false end
-- Ground frames are native IsoObjects with per-pixel world depth. Keeping
-- this compatibility hook empty preserves the tower's single decorative pass
-- without painting over furniture, players or native girders.
function View:render()end
function M.draw(target)end
function M.setEnabled(value)
 local s=M.syncSelection();if not s then return false end
 M.enabled=value==true
 ModData.getOrCreate(M.preferenceKey)[s.recordId]=M.enabled
 if M.enabled then M.update()else M.restore()end
 print('[Diagonal Showroom Preview] '..(M.enabled and 'Diagonal glass and half-canopies visible; eight diagonal-joint girders enabled. Native stepped corner collision follows on the next update.' or 'Square glass/canopies restored; ground supports return when their tiles are clear.'))
 return true
end
function M.report()
 local count=0;for _ in pairs(M.targets)do count=count+1 end
 print('[Diagonal Showroom Preview] enabled='..tostring(M.enabled)..'; original corner pieces hidden='..count..'; visual panes=12; native stepped corner collision; eight diagonal-joint girders enabled')
end
Events.OnFillWorldObjectContextMenu.Add(function(index,context,objects,test)
 if test or not M.site()then return end
 context:addOption(M.enabled and 'Restore square corners and pillars' or 'Use diagonal glass and half-canopies',nil,function()M.setEnabled(not M.enabled)end)
end)
Events.OnGameStart.Add(function()M.syncSelection();if M.enabled then M.update()end end)
M.View=View
return M
