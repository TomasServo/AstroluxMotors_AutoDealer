package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local Plan=require 'TSBAstroluxStructure/FloorPlan'
local border,inner,seen=0,0,{}
for _,t in ipairs(Plan.plan(100,200)) do
    assert(t.x>=100 and t.x<=107 and t.y>=200 and t.y<=207)
    local key=t.x..':'..t.y;assert(not seen[key]);seen[key]=true
    if t.sprite==Plan.border then border=border+1 else assert(t.sprite==Plan.inner);inner=inner+1 end
end
assert(border==28 and inner==36)
FBORenderChunk={DIRTY_REDRAW=1}
local world,missing,failAt,calls={},nil,nil,0
function getSprite(name) if name==missing then return nil end;return {getName=function() return name end} end
local function reset()
    world={};missing=nil;failAt=nil;calls=0
    for x=99,108 do for y=199,208 do
        local obj={sprite=getSprite('asphalt'),md={custom='keep'},attachments={marker='keep'}}
        function obj:getSprite() return self.sprite end
        function obj:setSprite(sprite) calls=calls+1;if calls==failAt then error('injected floor failure') end;self.sprite=sprite end
        function obj:getModData() return self.md end
        function obj:invalidateRenderChunkLevel() end
        local sq={floor=obj,furniture={marker='keep'},items={marker='keep'}}
        function sq:getFloor() return self.floor end
        function sq:addFloor(name)
            local obj={sprite=getSprite(name),md={}}
            function obj:getSprite() return self.sprite end
            function obj:setSprite(s) self.sprite=s end
            function obj:getModData() return self.md end
            function obj:invalidateRenderChunkLevel() end
            self.floor=obj;return obj
        end
        function sq:RemoveTileObject(obj) if self.floor==obj then self.floor=nil end end
        function sq:AddTileObject(obj) self.floor=obj end
        function sq:RecalcAllWithNeighbours() end
        world[x..':'..y]=sq
    end end
end
function getCell() return {getGridSquare=function(_,x,y,z) if z==0 then return world[x..':'..y] end end} end
local F=require 'TSBAstroluxStructure/Flooring'
local function record() return {id='floor-lab',x=100,y=200,status='ready'} end
reset();local r=record();local first=world['100:200'].floor;local attachments=first.attachments
assert(F.paint(r));assert(#r.flooring.tiles==64)
for _,t in ipairs(Plan.plan(100,200)) do
    local sq=world[t.x..':'..t.y]
    assert(sq.floor:getSprite():getName()==t.sprite and sq.floor.md.custom=='keep')
    assert(sq.furniture.marker=='keep' and sq.items.marker=='keep')
end
assert(world['100:200'].floor==first and first.attachments==attachments)
assert(world['99:199'].floor:getSprite():getName()=='asphalt','Exterior floor changed')
first:setSprite(getSprite('player-selected-tile'))
assert(F.paint(r));assert(first:getSprite():getName()=='player-selected-tile','Load overwrote player floor change')
assert(F.restore(r));assert(first:getSprite():getName()=='player-selected-tile' and not first.md.TSBAstroluxFlooring)
assert(world['101:201'].floor:getSprite():getName()=='asphalt' and not r.flooring)
reset();r=record();missing=Plan.inner
local ok,reason=F.paint(r);assert(not ok and reason:find('Missing native'))
assert(world['100:200'].floor:getSprite():getName()=='asphalt')
reset();r=record();world['107:207']=nil
ok=F.paint(r);assert(not ok and world['100:200'].floor:getSprite():getName()=='asphalt')
reset();r=record();failAt=12
ok=F.paint(r);assert(not ok and not r.flooring and r.status=='ready')
for _,sq in pairs(world) do assert(sq.floor:getSprite():getName()=='asphalt' and not sq.floor.md.TSBAstroluxFlooring) end
print('PASS: 28 dark border tiles, 36 gray inner tiles, native floor identity/content preserved, player edits retained and failed paint rolled back')

-- Native terrain can have a loaded square without an explicit IsoObject floor.
reset();r=record();world['100:200'].floor=nil
assert(F.paint(r));assert(world['100:200'].floor:getSprite():getName()==Plan.border)
assert(r.flooring.tiles[1].created)
assert(F.restore(r));assert(world['100:200'].floor==nil,'Created floor was not removed during restoration')
-- Retry after a startup square becomes available; never repaint on later ticks.
reset();r=record();local streamed=world['100:200'];world['100:200']=nil
local callbacks={};Events={OnGameStart={Add=function(fn) callbacks.start=fn end},OnTick={Add=function(fn) callbacks.tick=fn end}}
function isClient() return false end
function isServer() return false end
function getDebug() return true end
function getWorld() return {getWorld=function() return 'AstroluxStructureLab' end} end
ModData={getOrCreate=function() return {tower=r} end}
function getSpecificPlayer() return {isDead=function() return false end,getZ=function() return 0 end,getX=function() return 95 end,getY=function() return 195 end} end
local now=0
function getTimestampMs() return now end
package.loaded['TSBAstroluxStructure/Flooring']=nil
F=require 'TSBAstroluxStructure/Flooring'
callbacks.start();assert(not r.flooring,'Unloaded site should defer, not mark complete')
world['100:200']=streamed;now=1001;callbacks.tick();assert(r.flooring and #r.flooring.tiles==64)
streamed.floor:setSprite(getSprite('player-tile'));now=2002;callbacks.tick()
assert(streamed.floor:getSprite():getName()=='player-tile','Retry overwrote a completed floor')
print('PASS: native floor creation and restore, deferred startup loading retries once ready, completed player floor edits preserved')

reset();r=record();world['100:200'].floor=nil;failAt=12
local painted=F.paint(r);assert(not painted and not r.flooring)
assert(world['100:200'].floor==nil,'Failure left newly constructed flooring behind')
for key,sq in pairs(world) do if key~='100:200' then assert(sq.floor:getSprite():getName()=='asphalt') end end
print('PASS: mixed new/existing floor failure restores terrain without orphan tiles')
