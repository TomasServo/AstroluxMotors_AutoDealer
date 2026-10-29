require 'ISUI/ISModalRichText'
local Access=require 'TSBAstroluxStructure/ReleaseAccess'
local M={channel='TSBAstroluxRelease'}
TSBAstroluxReleaseClient=M
local function message(text)
 local p=getSpecificPlayer(0);if not p then return end
 local modal=ISModalRichText:new(100,100,700,320,text,false,nil,nil,p:getPlayerNum())
 modal:initialise();modal:addToUIManager()
end
function M.send(command,args)
 local p=getSpecificPlayer(0);if not p then return end
 if isClient()then sendClientCommand(p,M.channel,command,args or {})
 elseif TSBAstroluxReleasePlacement then TSBAstroluxReleasePlacement.handle(p,command,args or {})end
end
function M.receive(command,data)
 if command=='sites'then
  local incoming=data.records or {};local present={}
  for _,r in ipairs(incoming)do present[r.id]=true end
  for _,r in ipairs(TSBAstroluxReleaseSites or {})do if not present[r.id]then
   -- Objects have already been removed by server packets. Refresh cached world
   -- drawing without deleting any client objects or guessing their ownership.
   for dx=-1,13 do for dy=-1,13 do for z=0,4 do
    local sq=getCell():getGridSquare(r.x+dx,r.y+dy,z)
    if sq then sq:RecalcAllWithNeighbours(true);sq:setSquareChanged();sq:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)end
   end end end
  end end
  TSBAstroluxReleaseSites=incoming
 elseif command=='deletedSite'then
  local ticks=0
  local function audit()
   ticks=ticks+1;if ticks<120 then return end
   Events.OnTick.Remove(audit)
   -- A later paste at the same origin supersedes this deletion notice.
   for _,r in ipairs(TSBAstroluxReleaseSites or {})do if r.id==data.id then return end end
   local removed=0
   local remaining=0
   for z=0,4 do for dx=-1,13 do for dy=-1,13 do
    local sq=getCell():getGridSquare(data.x+dx,data.y+dy,z)
    if sq then
     local list=sq:getObjects()
     for i=list:size()-1,0,-1 do
      local o=list:get(i);local md=o:getModData()
      local f=md.movableData and md.movableData.TSBAstroluxFurnishingV1
      local h=md.TSBAstroluxNativeHelperV1
      if md.TSBAstroluxStructure==data.id or(f and f.tower==data.id)or(h and h.owner==data.id)then
       -- Local reconciliation only: server already verified zero owned objects.
       -- Never send another removal packet or expand a multi-tile group.
       sq:RemoveTileObject(o,false)
       if o:getObjectIndex()>=0 then remaining=remaining+1 else removed=removed+1 end
      end
     end
     sq:invalidateRenderChunkLevel(-1)
    end
   end end end
   for _,t in ipairs(data.floors or {})do
    local sq=getCell():getGridSquare(t.x,t.y,0);local o=sq and sq:getFloor()
    if o and o:getModData().TSBAstroluxFlooring==data.id
     and o:getSprite()and o:getSprite():getName()==t.to then
     if t.created then sq:RemoveTileObject(o,false)
     else local sp=getSprite(t.from)
      if sp and sp:getName()==t.from then o:setSprite(sp);o:getModData().TSBAstroluxFlooring=t.owner end
     end
     sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged();sq:invalidateRenderChunkLevel(-1)
    end
   end
   print('[Astrolux delete audit] '..data.id..' reconciled client objects='..removed..'; remaining='..remaining)
  end
  Events.OnTick.Add(audit)
 elseif command=='review'then
  local sent=false
  local modal=ISModalRichText:new(100,100,700,320,'Place the approved Astrolux tower at '..data.x..', '..data.y..'? <LINE> The server rechecks the empty footprint before placement. Existing objects are never cleared. Delivery zones are configured separately in the kiosks.',true,nil,function(_,button)
   if button.internal=='YES'and not sent then sent=true;M.send('place',{token=data.token})end
  end,0)
  modal:initialise();modal:addToUIManager()
 elseif command=='reviewDelete'then
  local sent=false
  local modal=ISModalRichText:new(100,100,700,360,'Delete the pasted Astrolux tower at '..data.x..', '..data.y..'? <LINE> This permanently removes '..data.count..' tower objects, including tower furnishings & their contents. Move possessions out first. The original ground is restored where unchanged. Kiosks & their delivery zones are retired. <LINE> This cannot be undone.',true,nil,function(_,button)
   if button.internal=='YES'and not sent then sent=true;M.send('deleteTower',{token=data.token})end
  end,0)
  modal:initialise();modal:addToUIManager()
 elseif command=='result'then message(tostring(data.message))
 elseif command=='holds'then
  require('TSBAstroluxStructure/ReleaseRecoveryPanel').open(data.rows or {})
 end
end
local Cursor
function M.start()
 if not Cursor then
  require 'BuildingObjects/ISBuildingObject'
  require 'BuildingObjects/ISBuildCursorMouse'
  Cursor=ISBuildCursorMouse:derive('AstroluxReleaseCursor')
  function Cursor:isValid(sq)return sq and sq:getZ()==0 end
  function Cursor:rotateKey()end
  function Cursor:rotateMouse()end
  function Cursor:render(x,y,z,sq)
   if z~=0 then return end
   if not self.tile then self.tile=IsoSprite.new();self.tile:LoadSingleTexture('carpentry_02_56')end
   for dx=0,12 do for dy=0,12 do self.tile:RenderGhostTileColor(x+dx,y+dy,0,.15,.65,1,.3)end end
   self.tooltipName='Place Astrolux Tower';self.tooltipTxt='Click to request server validation of this 13 x 13 footprint. Stand outside it, within 30 tiles. Existing objects remain.';self:renderTooltip()
  end
  function Cursor:onSquareSelected(sq)
   if sq and sq:getZ()==0 then getCell():setDrag(nil,self.player);M.send('review',{x=sq:getX(),y=sq:getY()})end
  end
 end
 local p=getSpecificPlayer(0);if not Access.allowed(p)then return end
 local o=ISBuildCursorMouse.new(Cursor,p,Cursor.onSquareSelected,Cursor.isValid)
 o.dragNilAfterPlace=true;o:setSprite('carpentry_02_56');getCell():setDrag(o,p:getPlayerNum())
end
Events.OnServerCommand.Add(function(module,command,data)if module==M.channel then M.receive(command,data)end end)
-- OnGameStart can precede the usable MP connection. Keep authoritative
-- sites refreshed after joining, including changes made by another admin.
local lastSitesRequest=0
local function refreshSites()
 if not isClient() or not getSpecificPlayer(0) then return end
 local now=getTimestampMs()
 if now-lastSitesRequest<5000 then return end
 lastSitesRequest=now
 M.send('sites')
end
Events.OnGameStart.Add(function()lastSitesRequest=0;M.send('sites')end)
Events.OnTick.Add(refreshSites)
Events.OnDisconnect.Add(function()TSBAstroluxReleaseSites=nil;lastSitesRequest=0 end)
function M.menuAllowed(index)
 if index~=0 or not Access.allowed(getSpecificPlayer(index))then return false end
 return isClient()or not require('AstroluxBayTest/TestWorld').enabled()
end
function M.addMenu(index,context,test)
 if not M.menuAllowed(index)then return false end
 if test then return true end
 -- Both the legacy event and native world-menu element may run for one click.
 for _,option in ipairs(context.options or {})do
  if option.name=='Place Astrolux Tower...'then return true end
 end
 context:addOption('Place Astrolux Tower...',nil,M.start)
 context:addOption('Inspect Held Astrolux Placements',nil,function()M.send('holds')end)
 context:addOption('Delete Nearby Astrolux Tower...',nil,function()M.send('reviewDeleteNearby')end)
 local p=getSpecificPlayer(index)
 local rows=isClient()and(TSBAstroluxReleaseSites or {})or require('TSBAstroluxStructure/Records').all()
 local nearby={}
 for _,r in ipairs(rows)do
  if r.releaseTower and (p:getX()-r.x)^2+(p:getY()-r.y)^2<=900 then
   local dx=math.max(r.x-p:getX(),0,p:getX()-(r.x+12))
   local dy=math.max(r.y-p:getY(),0,p:getY()-(r.y+12))
   nearby[#nearby+1]={record=r,distance=math.sqrt(dx*dx+dy*dy)}
  end
 end
 table.sort(nearby,function(a,b)
  if a.distance==b.distance then return tostring(a.record.id)<tostring(b.record.id)end
  return a.distance<b.distance
 end)
 for _,entry in ipairs(nearby)do
  local r=entry.record;local id=r.id
  local nearest=entry.distance==nearby[1].distance and 'Nearest — 'or ''
  context:addOption('Delete Astrolux Tower — '..nearest..string.format('%.1f',entry.distance)..' Tiles ('..r.x..', '..r.y..')...',nil,function()M.send('reviewDelete',{id=id})end)
 end
 return true
end
Events.OnFillWorldObjectContextMenu.Add(function(index,context,objects,test)
 if M.addMenu(index,context,test)and test then return ISWorldObjectContextMenu.setTest()end
end)
print('[Astrolux placement] Client menu v4 loaded (non-debug supported).')
return M
