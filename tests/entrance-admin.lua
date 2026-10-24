package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;'..package.path
local root='mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxStructure/'
function isClient()return false end;function isServer()return false end;function getDebug()return true end
function getWorld()return {getWorld=function()return 'AstroluxStructureLab_Test' end}end
local r={id='r',x=0,y=0,combinedSize=12,status='ready'}
local player={isDead=function()return false end,getZ=function()return 0 end,getX=function()return 6 end,getY=function()return 6 end}
package.loaded['TSBAstroluxStructure/Records']={all=function()return {r}end}
package.loaded['Moveables/ISMoveableSpriteProps']={}
local function list(t)return {size=function()return #t end,get=function(_,i)return t[i+1]end}end
local squares={}
local function square(x,y)
 local sq={x=x,y=y,objects={},moving={},floor={getModData=function()return {} end,getSprite=function()return nil end}}
 function sq:getX()return self.x end;function sq:getY()return self.y end;function sq:getZ()return 0 end
 function sq:getObjects()return list(self.objects)end;function sq:getMovingObjects()return list(self.moving)end
 function sq:getStaticMovingObjects()return list({})end;function sq:getWorldObjects()return list({})end
 function sq:getFloor()return self.floor end;function sq:RecalcAllWithNeighbours()end
 function sq:AddTileObject(o)self.objects[#self.objects+1]=o;o.index=#self.objects end;sq.AddSpecialObject=sq.AddTileObject
 function sq:RemoveTileObject(o)for i,v in ipairs(self.objects)do if v==o then table.remove(self.objects,i);o.index=-1;return end end end
 squares[x..':'..y]=sq;return sq
end
for x=-1,12 do for y=-1,12 do square(x,y)end end
local cell={getGridSquare=function(_,x,y)return squares[x..':'..y]end}
function getCell()return cell end
function getSprite(name)return {getName=function()return name end}end
function instanceof(o,kind)return o.kind==kind end
local function object(kind,sq,sprite,north)
 local o={kind=kind,sq=sq,sprite=sprite,north=north,md={},index=-1}
 function o:getSprite()return self.sprite end;function o:getModData()return self.md end;function o:getNorth()return self.north end
 function o:getObjectIndex()return self.index end;function o:getSquare()return self.sq end
 function o:isDestroyed()return false end;function o:isBarricaded()return false end
 function o:setOpenSprite()end;function o:setIsLocked()end;function o:setLockedByKey()end;function o:setPermaLocked()end
 return o
end
IsoDoor={new=function(_,sq,s,n)return object('IsoDoor',sq,s,n)end};IsoWindow={new=function(_,sq,s,n)return object('IsoWindow',sq,s,n)end};IsoObject={new=function(_,sq,s)return object('IsoObject',sq,s)end}
local E=require 'AstroluxBayTest/ShowroomEntrances12'
for _,pair in ipairs(E.plan(r))do for _,leaf in ipairs(pair.leaves)do
 local sq=cell:getGridSquare(leaf.x,leaf.y);local o=IsoDoor.new(cell,sq,getSprite('TSBAstroluxSlidingDoor_'..leaf.base),pair.north)
 o.md.TSBAstroluxStructure=r.id;o.md.TSBAstroluxStructureKind='slidingDoor';sq:AddSpecialObject(o)
end end
local a,b=cell:getGridSquare(5,1),cell:getGridSquare(6,1)
a.objects={a.floor};b.objects={b.floor}
local ra=IsoObject.new(cell,a,getSprite('TSBAstroluxLogoRug_2'));local rb=IsoObject.new(cell,b,getSprite('TSBAstroluxLogoRug_3'));a:AddTileObject(ra);b:AddTileObject(rb)
ISMoveableSpriteProps={new=function()return {getSpriteGridInfo=function()return {{square=a,object=a.objects[2]},{square=b,object=b.objects[2]}}end}end}
local M=dofile(root..'EntranceAdmin.lua')
assert(M.link(player,r,'north',ra));assert(not M.link(player,r,'east',ra))
squares['5:0'].moving={player};assert(not M.toggle(player,r,'north'));assert(ra.index>0);squares['5:0'].moving={}
assert(M.toggle(player,r,'north'));assert(r.closedEntrances.north and ra.index<0 and rb.index<0 and #r.hiddenEntranceRugs.north==2)
assert(squares['5:0'].objects[1].kind=='IsoWindow')
assert(M.toggle(player,r,'north'));assert(not r.closedEntrances.north and #a.objects==2 and #b.objects==2)
assert(squares['5:0'].objects[1].kind=='IsoDoor');assert(M.unlink(player,r,'north'));assert(not r.entranceRugs.north)
assert(not M.toggle(player,{id='fake'},'north'))
print('PASS entrance link, ownership, occupied-door rejection, two-leaf window swap, rug removal/restoration, unlink, unregistered showroom rejection')

-- Insertion failure must restore the original pair without committing state.
local sq=squares['5:0'];local original=sq.AddSpecialObject;local once=true
sq.AddSpecialObject=function(self,obj)if once then once=false;error('injected insertion failure')end;return original(self,obj)end
assert(not M.toggle(player,r,'north'));assert(not r.closedEntrances.north)
assert(squares['5:0'].objects[1].kind=='IsoDoor' and squares['6:0'].objects[1].kind=='IsoDoor')
sq.AddSpecialObject=original
for _,edge in ipairs({'north','south','east','west'})do assert(M.toggle(player,r,edge));assert(r.closedEntrances[edge]);assert(M.toggle(player,r,edge));assert(not r.closedEntrances[edge])end
print('PASS rollback after insertion failure and independent four-side toggles')

-- Previously unlinked rugs must automatically follow the door transaction.
assert(M.toggle(player,r,'north'));assert(#a.objects==1 and #b.objects==1)
assert(#r.hiddenEntranceRugs.north==2)
assert(M.toggle(player,r,'north'));assert(#a.objects==2 and #b.objects==2)
assert(M.unlink(player,r,'north'))
-- Interrupted/partial rug must block the whole door change.
local piece=b.objects[2];b:RemoveTileObject(piece)
assert(not M.toggle(player,r,'north'));assert(not r.closedEntrances.north)
b:AddTileObject(piece)
-- Unloaded rug area blocks; original doors and rugs remain intact.
local old=squares['5:2'];squares['5:2']=nil
assert(not M.toggle(player,r,'north'));assert(not r.closedEntrances.north)
squares['5:2']=old
print('PASS automatic unlinked rug close/reopen, incomplete rug and unloaded-area refusal')
-- Exercise automatic rug detection on every entrance plane.
for _,edge in ipairs({'north','south','east','west'})do
 if r.entranceRugs and r.entranceRugs[edge] then assert(M.unlink(player,r,edge))end
 local pair;for _,v in ipairs(E.plan(r))do if v.edge==edge then pair=v end end
 local cells={}
 for _,leaf in ipairs(pair.leaves)do
  local x=leaf.x+(edge=='east' and -2 or edge=='west' and 1 or 0)
  local y=leaf.y+(edge=='south' and -2 or edge=='north' and 1 or 0)
  local s=cell:getGridSquare(x,y);s.objects={s.floor}
  s:AddTileObject(IsoObject.new(cell,s,getSprite('TSBAstroluxLogoRug_'..(#cells+2))))
  cells[#cells+1]=s
 end
 ISMoveableSpriteProps.new=function()return {getSpriteGridInfo=function()return {{square=cells[1],object=cells[1].objects[2]},{square=cells[2],object=cells[2].objects[2]}}end}end
 assert(M.toggle(player,r,edge));assert(#r.hiddenEntranceRugs[edge]==2)
 assert(#cells[1].objects==1 and #cells[2].objects==1)
 assert(M.toggle(player,r,edge));assert(#cells[1].objects==2 and #cells[2].objects==2)
end
print('PASS automatic hide/restore on north, south, east and west entrances')
local function cleanRugs()
 for _,s in pairs(squares)do
  for i=#s.objects,1,-1 do
   local o=s.objects[i];local sprite=o:getSprite()
   if sprite and sprite:getName():match('^TSBAstroluxLogoRug_')then s:RemoveTileObject(o)end
  end
 end
 r.entranceRugs={};r.hiddenEntranceRugs={}
end
local function boundaryCase(edge,x1,y1,x2,y2)
 cleanRugs()
 local s1,s2=squares[x1..':'..y1],squares[x2..':'..y2]
 local o1=IsoObject.new(cell,s1,getSprite('TSBAstroluxLogoRug_2'))
 local o2=IsoObject.new(cell,s2,getSprite('TSBAstroluxLogoRug_3'))
 s1:AddTileObject(o1);s2:AddTileObject(o2)
 ISMoveableSpriteProps.new=function()return {getSpriteGridInfo=function()return {{square=s1,object=o1},{square=s2,object=o2}}end}end
 -- A conflicting explicit link must still prevent the entire transaction.
 o2.md.TSBAstroluxEntranceRug={tower='other',edge=edge}
 assert(not M.toggle(player,r,edge));assert(not r.closedEntrances[edge] and o1.index>0 and o2.index>0)
 o2.md.TSBAstroluxEntranceRug=nil
 local ok,why=M.toggle(player,r,edge);assert(ok,why)
 assert(o1.index<0 and o2.index<0 and #r.hiddenEntranceRugs[edge]==2)
 assert(r.hiddenEntranceRugs[edge][1].sprite=='TSBAstroluxLogoRug_2')
 ok,why=M.toggle(player,r,edge);assert(ok,why)
 local function restored(s)
  for _,o in ipairs(s.objects)do if o:getSprite() and o:getSprite():getName():match('^TSBAstroluxLogoRug_')then return true end end
 end
 assert(restored(s1) and restored(s2))
end
boundaryCase('south',5,11,4,11) -- sideways half outside doorway width
boundaryCase('south',5,11,5,12) -- native south wall square at threshold
boundaryCase('north',5,0,5,-1)
boundaryCase('east',11,5,12,5)
boundaryCase('west',0,5,-1,5)
print('PASS boundary rugs: south lateral and all four thresholds; ownership guard; exact two-piece removal/restoration')
cleanRugs()
local s1,s2=squares['5:11'],squares['5:8']
local o1=IsoObject.new(cell,s1,getSprite('TSBAstroluxLogoRug_2'));s1:AddTileObject(o1)
local o2=IsoObject.new(cell,s2,getSprite('TSBAstroluxLogoRug_3'));s2:AddTileObject(o2)
ISMoveableSpriteProps.new=function()return {getSpriteGridInfo=function()return {{square=s1,object=o1},{square=s2,object=o2}}end}end
assert(not M.toggle(player,r,'south'));assert(o1.index>0 and o2.index>0 and not r.closedEntrances.south)
print('PASS disconnected grid rejected without door or rug mutation')
