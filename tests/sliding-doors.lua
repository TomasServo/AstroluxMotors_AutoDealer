package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;'..package.path
function isClient() return false end
function isServer() return false end
function getDebug() return true end
function getWorld() return {getWorld=function() return 'AstroluxStructureLab' end} end
Events={OnTick={Add=function() end},LoadGridsquare={Add=function() end},OnGameStart={Add=function() end}}
local now=1000
function getTimestampMs() return now end
local function list(items) return {size=function() return #items end,get=function(_,i) return items[i+1] end} end
local squares={};local failInsert,failToggle
local function key(x,y,z) return x..':'..y..':'..z end
local function square(x,y)
    local s={x=x,y=y,objects={},moving={},loose={}}
    s.floor={getModData=function() return {} end,getSprite=function() return nil end,getObjectIndex=function() return 0 end};s.objects={s.floor}
    function s:getX() return self.x end
    function s:getY() return self.y end
    function s:getZ() return 0 end
    function s:getObjects() return list(self.objects) end
    function s:getFloor() return self.floor end
    function s:getMovingObjects() return list(self.moving) end
    function s:getWorldObjects() return list(self.loose) end
    function s:RecalcAllWithNeighbours() end
    function s:AddSpecialObject(o) if failInsert==x..':'..y then error('injected insertion failure') end;self.objects[#self.objects+1]=o;o.index=#self.objects-1 end
    function s:RemoveTileObject(o) for i,v in ipairs(self.objects) do if v==o then table.remove(self.objects,i);o.index=-1;return end end end
    squares[key(x,y,0)]=s;return s
end
local cell={getGridSquare=function(_,x,y,z) return squares[key(x,y,z)] end}
function getCell() return cell end
function getSprite(name) return {getName=function() return name end} end
function instanceof(o,t) return o.kind==t end
IsoDoor={new=function(_,sq,sprite,north)
    local o={kind='IsoDoor',sq=sq,sprite=sprite,north=north,md={},index=-1,open=false}
    function o:getSprite() return self.sprite end
    function o:setSprite(v) self.sprite=v end
    function o:getModData() return self.md end
    function o:getObjectIndex() return self.index end
    function o:getSquare() return self.sq end
    function o:getNorth() return self.north end
    function o:setOpenSprite(v) self.openSprite=v end
    function o:setIsLocked(v) self.locked=v end
    function o:setLockedByKey(v) self.lockedByKey=v end
    function o:isDestroyed() return self.destroyed end
    function o:isBarricaded() return self.barricaded end
    function o:isLocked() return self.locked end
    function o:IsOpen() return self.open end
    function o:ToggleDoorSilent() self.open=not self.open end
    function o:ToggleDoor() if self~=failToggle then self:ToggleDoorSilent() end end
    function o:getOppositeSquare() return nil end
    function o:syncIsoObject() end
    return o
end}
local r={id='lab',x=100,y=200,status='ready',clearWallsRevision=1}
ModData={getOrCreate=function() return {tower=r} end}
local E=require 'TSBAstroluxStructure/Entrances'
for _,pair in ipairs(E.plan(r)) do
    local a=pair.leaves[1]
    assert(E.hit(r,a.x+(pair.north and 1 or 0),a.y+(pair.north and 0 or 1)).edge==pair.edge)
    for _,leaf in ipairs(pair.leaves) do square(leaf.x,leaf.y) end
end
assert(not E.hit(r,104,204))
local I=require 'TSBAstroluxStructure/SlidingInstall'
failInsert='104:208'
assert(not I.apply(r));assert(not r.slidingDoorsRevision)
for _,s in pairs(squares) do assert(#s.objects==1) end
failInsert=nil
local occupied=squares[key(103,200,0)];occupied.moving={true}
assert(not I.apply(r));occupied.moving={}
assert(I.apply(r));assert(r.slidingDoorsRevision==1)
for _,s in pairs(squares) do assert(#s.objects==2) end
assert(I.apply(r));for _,s in pairs(squares) do assert(#s.objects==2) end
local M=TSBAstroluxSlidingDoors
local a=occupied.objects[2];local b=M.partner(a,cell);assert(b)
local p={x=104,y=199,z=0}
function p:getX() return self.x end
function p:getY() return self.y end
function p:getZ() return self.z end
function p:isDead() return false end
function p:isAiming() return self.aiming end
function p:isIgnoreContextKey() return false end
function p:getCurrentSquare() return occupied end
assert(M.togglePair(p,a,b));assert(a.open and b.open)
assert(M.togglePair(p,a,b));assert(not a.open and not b.open)
b.locked=true;assert(not M.togglePair(p,a,b));assert(not a.open and not b.open);b.locked=false
failToggle=b;assert(not M.togglePair(p,a,b));assert(not a.open and not b.open);failToggle=nil
assert(M.togglePair(p,a,b));occupied.moving={p};p.y=200
assert(not M.togglePair(p,a,b));assert(a.open and b.open);p.y=199
assert(M.togglePair(p,a,b),'Adjacent player outside threshold should be able to close');assert(not a.open and not b.open)
assert(M.togglePair(p,a,b));occupied.moving={}
p.x=150;assert(not M.togglePair(p,a,b));p.x=104
-- Clicking the empty doorway floor closes, then reopens, the same pair.
function screenToIsoX(_,x) return x end
function screenToIsoY(_,x,y) return y end
-- An invertible isometric projection, with height shifting only screen Y.
function isoToScreenX(_,x,y,z) return (x-y)*32 end
function isoToScreenY(_,x,y,z) return (x+y)*16-z*96 end
UIManager={getSpeedControls=function() return nil end}
for _,pair in ipairs(E.plan(r)) do
    local leaf=pair.leaves[1]
    local wx=leaf.x+(pair.north and 1 or 0);local wy=leaf.y+(pair.north and 0 or 1)
    local hit=E.screenHit(r,isoToScreenX(0,wx,wy,0.5),isoToScreenY(0,wx,wy,0.5),function(x,y,z)
        return isoToScreenX(0,x,y,z),isoToScreenY(0,x,y,z)
    end)
    assert(hit and hit.edge==pair.edge,'Projected center must identify each correct entrance')
end
local originalCalls=0
ISObjectClickHandler=nil
function occupied.floor:getSquare() return occupied end
local C=require 'TSBAstroluxStructure/EntranceClick'
assert(not C.install(),'Client loading before native handler must be safe')
ISObjectClickHandler={doClickSpecificObject=function() originalCalls=originalCalls+1;return false end}
assert(C.install());local attached=ISObjectClickHandler.doClickSpecificObject
assert(C.install() and attached==ISObjectClickHandler.doClickSpecificObject,'Do not wrap twice')
local sx,sy=isoToScreenX(0,104,200,0.5),isoToScreenY(0,104,200,0.5)
assert(C.click(occupied.floor,p,sx,sy));assert(not a.open and not b.open)
now=now+100
assert(C.click(occupied.floor,p,sx,sy));assert(not a.open and not b.open,'Double click must not immediately reopen')
now=now+500
assert(C.click(occupied.floor,p,sx,sy));assert(a.open and b.open)
assert(not C.click(occupied.floor,p,-10000,-10000));assert(a.open and b.open)
assert(not C.click(a,p,sx,sy),'Native leaf clicks must not double-toggle')
p.aiming=true;assert(not C.click(occupied.floor,p,sx,sy));p.aiming=false
function getMouseX() return sx end
function getMouseY() return sy end
now=now+500
assert(ISObjectClickHandler.doClickSpecificObject(occupied.floor,0,p));assert(originalCalls==0)
assert(not ISObjectClickHandler.doClickSpecificObject(a,0,p));assert(originalCalls==1)
-- Existing native leaf clicks still synchronize both leaves.
a.open=false;b.open=true;assert(M.reconcile(a,b,true)==false);assert(not a.open and not b.open)
print('PASS: eight native sliding leaves, four center hit areas, locks, occupancy, native refusal rollback, repeat install, native click coexistence')
