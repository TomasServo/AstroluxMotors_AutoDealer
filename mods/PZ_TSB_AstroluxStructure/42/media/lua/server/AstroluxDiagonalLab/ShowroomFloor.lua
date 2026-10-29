-- Private, reversible floor-only octagon. The engine writes changes when the
-- user saves normally. No map files, furnishings, walls or helpers are edited.
if isClient() or isServer() then return end
local P=require 'AstroluxDiagonalLab/Plan'
local L=require 'AstroluxDiagonalLab/FloorLayout'
local Records=require 'TSBAstroluxStructure/Records'
local M={};local ticks=0;local failed=false;local lastMessage
local tag='TSBAstroluxFlooring'
local function name(o)
 local sprite=o and o:getSprite();return sprite and sprite:getName()
end
local function refresh(sq,floor)
 sq:RecalcAllWithNeighbours(true)
 floor:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
end
local function report(message)
 if message~=lastMessage then lastMessage=message;print('[Astrolux octagon floor] '..message) end
end
function M.apply(record,active)
 local flooring=record.flooring
 if not flooring or flooring.hold or record.status=='hold' then return nil,'Floor record unavailable or held' end
 local pending={};local seen={};local skipped=0
 for _,tile in ipairs(flooring.tiles) do
  local x,y=tile.x-record.x,tile.y-record.y
  if x<0 or x>11 or y<0 or y>11 or x%1~=0 or y%1~=0 then return nil,'Unexpected floor record bounds' end
  local key=x..':'..y;if seen[key] then return nil,'Duplicate recorded floor square' end;seen[key]=true
  local sq=getCell():getGridSquare(tile.x,tile.y,0)
  if not sq then return nil,'Waiting for all showroom floor squares to load' end
  local floor=sq:getFloor();local current=name(floor)
  if not floor or floor:getModData()[tag]~=record.id or current~=tile.to then
   skipped=skipped+1 -- Preserve player-replaced/removed floors and foreign owners.
  else
   local target,why
   if active then target,why=L.target(x,y,tile.from)
   else target=tile.diagonalSquareSprite or tile.to end
   if not target then return nil,why end
   if target~=current then
    local sprite=getSprite(target)
    if not sprite or sprite:getName()~=target
     or not sprite:getProperties():has(IsoFlagType.solidfloor) then
     return nil,'Native floor asset unavailable: '..target
    end
    pending[#pending+1]={sq=sq,floor=floor,tile=tile,oldSprite=floor:getSprite(),
     oldTo=tile.to,oldSquare=tile.diagonalSquareSprite,target=target,sprite=sprite}
   end
  end
 end
 -- The saved original-floor journal must cover this complete 12x12 showroom.
 -- Never guess an exterior material or paint an unrecorded/player-owned floor.
 local count=0;for _ in pairs(seen) do count=count+1 end
 if count~=144 then return nil,'Complete 144-square original-floor journal required' end
 local undo={}
 local ok,err=pcall(function()
  for _,e in ipairs(pending) do
   if e.sq:getFloor()~=e.floor or name(e.floor)~=e.oldTo
    or e.floor:getModData()[tag]~=record.id then error('Floor changed during update') end
   undo[#undo+1]=e
   e.floor:setSprite(e.sprite)
   e.tile.diagonalSquareSprite=e.oldSquare or e.oldTo
   e.tile.to=e.target -- Keep the existing building-removal restoration journal valid.
   refresh(e.sq,e.floor)
  end
 end)
 if not ok then
  local clean=true
  for i=#undo,1,-1 do local e=undo[i]
   if not pcall(function()
    e.floor:setSprite(e.oldSprite);e.tile.to=e.oldTo;e.tile.diagonalSquareSprite=e.oldSquare
    refresh(e.sq,e.floor)
   end) then clean=false end
  end
  if not clean then flooring.hold=true;record.status='hold' end
  error('Floor change rolled back; '..tostring(err)..(clean and '' or '; restoration needs inspection'))
 end
 flooring.diagonalBoundary=active and 1 or nil
 return true,#pending,skipped
end
function M.update()
 if not P.runtimeEnabled() then return end
 local preview=TSBAstroluxShowroomDiagonalPreview
 if not preview then return end
 local s=preview.site();if not s or not s.ready then return end
 local record
 for _,r in ipairs(Records.all()) do
  if r.id==s.recordId and r.x==s.x and r.y==s.y then record=r;break end
 end
 if not record or not getCell() then return end
 local ok,detail,skipped=M.apply(record,preview.enabled==true)
 if not ok then report(detail)
 elseif detail>0 then
  report(tostring(detail)..' native floor sprites updated for '..(preview.enabled and 'diagonal' or 'square')
   ..' boundary; '..tostring(skipped)..' user-changed floors preserved')
 end
end
Events.OnTick.Add(function()
 ticks=ticks+1;if failed or ticks%60~=0 then return end
 local ok,err=pcall(M.update)
 if not ok then failed=true;report(tostring(err)) end
end)
return M
