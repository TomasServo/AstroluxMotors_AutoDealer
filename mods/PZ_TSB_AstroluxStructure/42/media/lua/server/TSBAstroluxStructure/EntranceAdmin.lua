-- Test-showroom controls. Native doors/windows retain collision and save behavior.
if isClient() or isServer() then return end
local E=require 'AstroluxBayTest/ShowroomEntrances12'
local R=require 'TSBAstroluxStructure/Records'
require 'Moveables/ISMoveableSpriteProps'
local M={}
local function allowed(p,r)
 if not getDebug() or not p or p:isDead() or p:getZ()~=0 or not (tostring(getWorld():getWorld()):match('^AstroluxStructureLab') or require('AstroluxBayTest/TestWorld').testMap()) then return false end
 for _,v in ipairs(R.all())do if v==r and r.status=='ready' then
  local size=r.combinedSize or 8
  return p:getX()>=r.x-3 and p:getX()<=r.x+size+3 and p:getY()>=r.y-3 and p:getY()<=r.y+size+3
 end end
 return false
end
local function pairFor(r,edge)
 for _,p in ipairs(E.plan(r))do if p.edge==edge then return p end end
end
local function rug(o)
 local s=o and o:getSprite();local n=s and s:getName()
 return type(n)=='string' and n:match('^TSBAstroluxLogoRug_%d+$')~=nil
end
local function each(sq,fn)
 local os=sq:getObjects();for i=0,os:size()-1 do fn(os:get(i))end
end
-- Only adopt a complete rug immediately inside this entrance. Never scan
-- unrelated showroom decor or remove ambiguous/partially loaded rugs.
local function entranceRug(r,pair)
 local size=r.combinedSize or 8
 local zone,seen,candidates={},{},{}
 for _,leaf in ipairs(pair.leaves)do
  for depth=0,2 do
   local x=leaf.x+(pair.edge=='east' and -1-depth or pair.edge=='west' and depth or 0)
   local y=leaf.y+(pair.edge=='south' and -1-depth or pair.edge=='north' and depth or 0)
   if x>=r.x and x<r.x+size and y>=r.y and y<r.y+size then
    local sq=getCell():getGridSquare(x,y,0)
    if not sq then return nil,'Load the entrance rug area before changing this entrance.' end
    zone[x..':'..y]=sq
   end
  end
 end
 for _,sq in pairs(zone)do
  local os=sq:getObjects()
  for i=0,os:size()-1 do
   local obj=os:get(i)
   if rug(obj) and not seen[obj] then
    local grid=ISMoveableSpriteProps.new(obj:getSprite():getName()):getSpriteGridInfo(sq,true)
    if not grid or #grid~=2 then return nil,'Entrance rug is incomplete; restore both pieces first.' end
    -- The search zone selects the entrance, not the rug's entire footprint.
    -- Native two-tile rugs may straddle its edge after rotation/placement.
    local first,second=grid[1].square,grid[2].square
    if not first or not second or first:getZ()~=0 or second:getZ()~=0
     or math.abs(first:getX()-second:getX())+math.abs(first:getY()-second:getY())~=1 then
     return nil,'Entrance rug is incomplete; restore both pieces first.'
    end
    local entries={}
    for _,g in ipairs(grid)do
     local o,s=g.object,g.square
     if not s or not rug(o) or o:getObjectIndex()<0 or getCell():getGridSquare(s:getX(),s:getY(),0)~=s then
      return nil,'Entrance rug is incomplete or not loaded; restore both pieces first.'
     end
     local owner=o:getModData().TSBAstroluxEntranceRug
     if owner and (owner.tower~=r.id or owner.edge~=pair.edge) then
      return nil,'Entrance rug is linked elsewhere; resolve its link first.'
     end
     seen[o]=true
     entries[#entries+1]={x=s:getX(),y=s:getY(),sprite=o:getSprite():getName(),object=o}
    end
    candidates[#candidates+1]=entries
   end
  end
 end
 if #candidates>1 then return nil,'Several rugs occupy this entrance; link the intended rug explicitly.' end
 return candidates[1] or {}
end
function M.link(player,r,edge,obj)
 if not allowed(player,r) or not pairFor(r,edge) then return nil,'Showroom administrator access required.' end
 if r.closedEntrances and r.closedEntrances[edge] then return nil,'Restore this entrance before linking a rug.' end
 if not rug(obj) or obj:getObjectIndex()<0 then return nil,'Right-click a placed Astrolux rug to link it.' end
 local props=ISMoveableSpriteProps.new(obj:getSprite():getName())
 local grid=props:getSpriteGridInfo(obj:getSquare(),true)
 if not grid or #grid~=2 then return nil,'Both rug tiles must be present and loaded.' end
 local size=r.combinedSize or 8
 local entries={}
 for _,g in ipairs(grid)do
  local sq=g.square;local o=g.object
  if not sq or not rug(o) or sq:getZ()~=0 or sq:getX()<r.x or sq:getX()>=r.x+size or sq:getY()<r.y or sq:getY()>=r.y+size then return nil,'Link a complete rug inside this showroom.' end
  local owner=o:getModData().TSBAstroluxEntranceRug
  if owner and (owner.tower~=r.id or owner.edge~=edge)then return nil,'Rug is already linked to another entrance.' end
  entries[#entries+1]={x=sq:getX(),y=sq:getY(),sprite=o:getSprite():getName(),object=o}
 end
 r.entranceRugs=r.entranceRugs or {}
 if r.entranceRugs[edge] then return nil,'This entrance already has a linked rug. Unlink it first.' end
 local saved={}
 for _,v in ipairs(entries)do
  v.object:getModData().TSBAstroluxEntranceRug={tower=r.id,edge=edge}
  saved[#saved+1]={x=v.x,y=v.y,sprite=v.sprite}
 end
 r.entranceRugs[edge]=saved
 return true
end
function M.unlink(player,r,edge)
 if not allowed(player,r) then return nil,'Showroom administrator access required.' end
 if r.closedEntrances and r.closedEntrances[edge] then return nil,'Restore this entrance before unlinking its stored rug.' end
 local entries=r.entranceRugs and r.entranceRugs[edge] or {}
 for _,v in ipairs(entries)do if not getCell():getGridSquare(v.x,v.y,0)then return nil,'Linked rug area is not loaded.' end end
 for _,v in ipairs(entries)do each(getCell():getGridSquare(v.x,v.y,0),function(o)
  local md=o:getModData();local link=md.TSBAstroluxEntranceRug
  if link and link.tower==r.id and link.edge==edge then md.TSBAstroluxEntranceRug=nil end
 end)end
 if r.entranceRugs then r.entranceRugs[edge]=nil end
 return true
end
function M.toggle(player,r,edge)
 if not allowed(player,r)then return nil,'Showroom administrator access required.' end
 local pair=pairFor(r,edge);if not pair then return nil,'Unknown entrance.' end
 local opening=r.closedEntrances and r.closedEntrances[edge]==true
 local removals,additions,stored={},{},{}
 local function clear(sq)
  return sq and sq:getMovingObjects():size()==0 and sq:getWorldObjects():size()==0 and sq:getStaticMovingObjects():size()==0
 end
 for _,leaf in ipairs(pair.leaves)do
  local sq=getCell():getGridSquare(leaf.x,leaf.y,0)
  local other=getCell():getGridSquare(leaf.x-(pair.north and 0 or 1),leaf.y-(pair.north and 1 or 0),0)
  if not clear(sq) or not clear(other)then return nil,'Clear both sides of the entrance and load its tiles first.' end
  local found={}
  each(sq,function(o)
   local md=o:getModData()
   if md.TSBAstroluxStructure==r.id and o.getNorth and o:getNorth()==pair.north then
    if opening and md.TSBAstroluxStructureKind=='entranceWindow' and instanceof(o,'IsoWindow') or not opening and md.TSBAstroluxStructureKind=='slidingDoor' and instanceof(o,'IsoDoor') then found[#found+1]=o end
   end
  end)
  if #found~=1 then return nil,'Entrance is missing or changed; nothing replaced.' end
  local old=found[1]
  if old:isDestroyed() or old:isBarricaded()then return nil,'Repair and unbarricade this entrance first.' end
  local name=opening and ('TSBAstroluxSlidingDoor_'..leaf.base) or ('TSBAstroluxClearGlass_'..(pair.north and 1 or 0))
  local sprite=getSprite(name);if not sprite or sprite:getName()~=name then return nil,'Entrance asset missing.' end
  local obj
  if opening then
   local openName='TSBAstroluxSlidingDoor_'..(leaf.base+2);local openSprite=getSprite(openName)
   if not openSprite or openSprite:getName()~=openName then return nil,'Open-door asset missing.' end
   obj=IsoDoor.new(getCell(),sq,sprite,pair.north);obj:setOpenSprite(openSprite);obj:setIsLocked(false);obj:setLockedByKey(false)
  else obj=IsoWindow.new(getCell(),sq,sprite,pair.north);obj:setPermaLocked(true) end
  local md=obj:getModData();md.TSBAstroluxStructure=r.id;md.TSBAstroluxStructureKind=opening and 'slidingDoor' or 'entranceWindow'
  removals[#removals+1]={sq=sq,obj=old,special=true}
  additions[#additions+1]={sq=sq,obj=obj,special=true}
 end
 local linked=r.entranceRugs and r.entranceRugs[edge] or {}
 local hidden=r.hiddenEntranceRugs and r.hiddenEntranceRugs[edge] or {}
 if opening then
  for _,v in ipairs(hidden)do
   local sq=getCell():getGridSquare(v.x,v.y,0)
   if not clear(sq) or not sq:getFloor()then return nil,'Clear the stored rug location before restoring this entrance.' end
   local conflict=false;each(sq,function(o)
    if o~=sq:getFloor()then
     local replaced=false
     for _,v in ipairs(removals)do if v.obj==o then replaced=true;break end end
     -- A floor rug may share its boundary tile with our perimeter window.
     -- Retain that window; never exempt furniture, other owners or interior walls.
     local md=o:getModData()
     local size=r.combinedSize or 8
     local boundary=pair.north and v.y==(edge=='south' and r.y+size or r.y)
        or not pair.north and v.x==(edge=='east' and r.x+size or r.x)
     local window=boundary and instanceof(o,'IsoWindow') and o:getNorth()==pair.north
        and md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='window'
     -- Native frame art shares north/west rug boundary squares. It is
     -- decorative, owned by this tower, and must remain in place.
     local helper=md.TSBAstroluxNativeHelperV1
     local sp=o:getSprite();local spriteName=sp and sp:getName()
     local frame=boundary and md.TSBAstroluxStructure==r.id
        and md.TSBAstroluxStructureKind=='glassFrameVisual'
        and helper and helper.owner==r.id and helper.kind=='glassFrameArt'
        and type(spriteName)=='string' and spriteName:match('^TSBAstroluxGlassFrame_[0-8]$')
        and not o:getContainer()
     if not replaced and not window and not frame then conflict=true end
    end
   end)
   if conflict then return nil,'An object occupies the stored rug location; nothing replaced.' end
   local sprite=getSprite(v.sprite);if not sprite or sprite:getName()~=v.sprite then return nil,'Rug asset missing.' end
   local obj=IsoObject.new(getCell(),sq,sprite);obj:getModData().TSBAstroluxEntranceRug={tower=r.id,edge=edge}
   additions[#additions+1]={sq=sq,obj=obj}
  end
 else
  for _,v in ipairs(linked)do
   local sq=getCell():getGridSquare(v.x,v.y,0);if not sq then return nil,'Linked rug location is not loaded.' end
   each(sq,function(o)
    local owner=o:getModData().TSBAstroluxEntranceRug
    if rug(o) and owner and owner.tower==r.id and owner.edge==edge then
     removals[#removals+1]={sq=sq,obj=o};stored[#stored+1]={x=v.x,y=v.y,sprite=o:getSprite():getName()}
    end
   end)
  end
  if #stored~=0 and #stored~=2 then return nil,'Linked rug is incomplete; unlink it before changing this entrance.' end
  if #stored==0 then
   local found,why=entranceRug(r,pair)
   if not found then return nil,why end
   for _,v in ipairs(found)do
    removals[#removals+1]={sq=v.object:getSquare(),obj=v.object}
    stored[#stored+1]={x=v.x,y=v.y,sprite=v.sprite}
   end
  end
 end
 local removed,added={},{}
 local function add(v)if v.special then v.sq:AddSpecialObject(v.obj)else v.sq:AddTileObject(v.obj)end;v.sq:RecalcAllWithNeighbours(true)end
 local ok,err=pcall(function()
  for _,v in ipairs(removals)do removed[#removed+1]=v;v.sq:RemoveTileObject(v.obj);v.sq:RecalcAllWithNeighbours(true)end
  for _,v in ipairs(additions)do added[#added+1]=v;add(v);assert(v.obj:getObjectIndex()>=0,'Insertion failed')end
 end)
 if not ok then
  local clean=true
  for i=#added,1,-1 do local v=added[i];if not pcall(function()if v.obj:getObjectIndex()>=0 then v.sq:RemoveTileObject(v.obj)end;v.sq:RecalcAllWithNeighbours(true)end)then clean=false end end
  for _,v in ipairs(removed)do if not pcall(function()if v.obj:getObjectIndex()<0 then add(v)end end)then clean=false end end
  if not clean then r.status='hold' end
  return nil,'Entrance update failed: '..tostring(err)
 end
 r.closedEntrances=r.closedEntrances or {};r.closedEntrances[edge]=not opening
 if not opening then
  r.entranceRugs=r.entranceRugs or {}
  r.entranceRugs[edge]=#stored>0 and stored or nil
 end
 r.hiddenEntranceRugs=r.hiddenEntranceRugs or {};r.hiddenEntranceRugs[edge]=opening and nil or stored
 return true
end
-- Explicit one-time move of the pictured west entrance rug, preserving its link.
function M.moveWestRugSouth(player)
 local r=player and R.near(player:getX(),player:getY())
 if not r or not allowed(player,r) then return nil,'Showroom administrator access required.' end
 if r.westRugSouth20261027 then return true,'Already moved; nothing changed.' end
 if r.closedEntrances and r.closedEntrances.west then return nil,'Open the west entrance first.' end
 local pair=pairFor(r,'west')
 if not pair then return nil,'West entrance missing.' end
 local entries,why=entranceRug(r,pair)
 if not entries or #entries~=2 then return nil,why or 'Complete west entrance rug required.' end
 local sources,targets={},{}
 for _,v in ipairs(entries)do
  if v.x~=r.x or (v.y~=r.y+4 and v.y~=r.y+5) then return nil,'Rug differs from the pictured placement; no move made.' end
  sources[v.object]=true
 end
 for i,v in ipairs(entries)do
  local sq=getCell():getGridSquare(v.x,v.y+1,0)
  if not sq or not sq:getFloor() then return nil,'Destination floor is not loaded.' end
  local os=sq:getObjects()
  for j=0,os:size()-1 do
   local o=os:get(j)
   if o~=sq:getFloor() and not sources[o] and not instanceof(o,'IsoWindow') and not instanceof(o,'IsoDoor') then
    return nil,'Destination contains another object; no move made.'
   end
  end
  targets[i]=sq
 end
 local old={}
 for i,v in ipairs(entries)do old[i]=v.object:getSquare() end
 local ok,err=pcall(function()
  for i,v in ipairs(entries)do old[i]:RemoveTileObject(v.object) end
  for i,v in ipairs(entries)do v.object:setSquare(targets[i]);targets[i]:AddTileObject(v.object) end
 end)
 if not ok then
  for i,v in ipairs(entries)do
   if v.object:getObjectIndex()>=0 then v.object:getSquare():RemoveTileObject(v.object) end
   v.object:setSquare(old[i]);old[i]:AddTileObject(v.object)
  end
  return nil,'Move rolled back: '..tostring(err)
 end
 local saved={}
 for i,v in ipairs(entries)do
  v.object:getModData().TSBAstroluxEntranceRug={tower=r.id,edge='west'}
  saved[i]={x=v.x,y=v.y+1,sprite=v.sprite}
  old[i]:RecalcProperties();old[i]:setSquareChanged()
  targets[i]:RecalcProperties();targets[i]:setSquareChanged()
  v.object:invalidateRenderChunkLevel(-1)
 end
 r.entranceRugs=r.entranceRugs or {};r.entranceRugs.west=saved
 r.westRugSouth20261027=true
 return true,'West rug moved one tile south; door-toggle link updated.'
end
function TSBAstroluxMoveWestRugSouth()
 local ok,why=M.moveWestRugSouth(getSpecificPlayer(0))
 print('[Astrolux rug move] '..tostring(ok)..' '..tostring(why))
end

return M
