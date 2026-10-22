local root='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
package.path=root..'shared/?.lua;'..root..'server/?.lua;'..package.path
local P=require 'TSBAstroluxStructure/Plan'
local p=P.plan(100,200)
local counts,edges={},{}
for _,o in ipairs(p.objects) do
    counts[o.kind]=(counts[o.kind] or 0)+1
    if o.kind~='art' then assert(o.x>=100 and o.x<=108 and o.y>=200 and o.y<=208) end
    if o.kind=='floor' then assert(o.z==1) end
    if o.kind=='door' or o.kind=='window' then
        local key=o.x..':'..o.y..':'..o.z..':'..tostring(o.north)
        assert(not edges[key],'Duplicate physical edge');edges[key]=true
    end
end
assert(counts.floor==64 and counts.window==28 and counts.door==4 and counts.frame==4 and counts.corner==1 and counts.art==404)
for z=0,0 do for n=0,7 do
    for _,e in ipairs({{100+n,200,true},{100+n,208,true},{100,200+n,false},{108,200+n,false}}) do
        assert(edges[e[1]..':'..e[2]..':'..z..':'..tostring(e[3])],'Gap in physical perimeter')
    end
end end

local db,world,sprites,vehicles,client,server,debug={}, {},{}, {},false,false,true
local save='AstroluxStructureLab_Test'
function isClient() return client end
function isServer() return server end
function getDebug() return debug end
function getWorld() return {getWorld=function() return save end} end
ModData={getOrCreate=function() return db end}
local function list(t)
    return {size=function() return #t end,get=function(_,i) return t[i+1] end,
        iterator=function() local i=0;return {hasNext=function() return i<#t end,next=function() i=i+1;return t[i] end} end}
end
local failAt,createCount,removeFail=nil,0,false
local function object(sprite)
    createCount=createCount+1
    if failAt==createCount then error('injected constructor failure') end
    local md={}
    return {getModData=function() return md end,getContainer=function() return nil end,
        setPermaLocked=function() end,sprite=sprite}
end
local function key(x,y,z) return x..':'..y..':'..z end
local function square(x,y,z)
    local t,moving,static,loose={},{},{},{}
    local floor
    if z==0 then floor=object('original');t[1]=floor end
    local sq={objects=t,moving=moving,static=static,loose=loose}
    function sq:TreatAsSolidFloor() return floor~=nil end
    function sq:isOutside() return true end
    function sq:getMovingObjects() return list(moving) end
    function sq:getStaticMovingObjects() return list(static) end
    function sq:getWorldObjects() return list(loose) end
    function sq:getObjects() return list(t) end
    function sq:getFloor() return floor end
    function sq:addFloor(sprite) floor=object(sprite);t[#t+1]=floor;return floor end
    function sq:AddSpecialObject(o) t[#t+1]=o end
    function sq:AddTileObject(o) t[#t+1]=o end
    function sq:RecalcAllWithNeighbours() end
    function sq:RemoveTileObject(o)
        if removeFail then error('injected cleanup failure') end
        for i=#t,1,-1 do if t[i]==o then table.remove(t,i) end end
        if floor==o then floor=nil end
    end
    world[key(x,y,z)]=sq;return sq
end
local cell={}
function cell:getGridSquare(x,y,z) return world[key(x,y,z)] end
function cell:createNewGridSquare(x,y,z) return square(x,y,z) end
function cell:getVehicles() return list(vehicles) end
function getCell() return cell end
function getSprite(name)
    if sprites[name]==false then return nil end
    return {getName=function() return name end}
end
IsoWindow={new=function(_,_,sprite) return object(sprite) end}
IsoDoor={new=function(_,_,sprite) return object(sprite) end}
IsoObject={new=function(_,_,sprite) return object(sprite) end}
local player={isDead=function() return false end,getZ=function() return 0 end,
    getX=function() return 95 end,getY=function() return 195 end}
local function reset()
    world={};db={};vehicles={};sprites={};failAt=nil;removeFail=false
    for x=99,109 do for y=199,209 do square(x,y,0) end end
    createCount=0
end
local B=require 'TSBAstroluxStructure/Builder'
local function rejects(fn) local ok,result,reason=pcall(fn);assert(not ok or (result==nil and type(reason)=='string'),'Expected rejection') end
local function preview() return B.preview(player,100,200) end
reset();assert(#preview().objects==505)
for _,mode in ipairs({'main','client','server','debug'}) do
    save='AstroluxStructureLab_Test';client=false;server=false;debug=true
    if mode=='main' then save='The Space Bar' elseif mode=='client' then client=true
    elseif mode=='server' then server=true else debug=false end
    rejects(preview);assert(not db.tower)
end
save='AstroluxStructureLab_Test';client=false;server=false;debug=true
rejects(function() return B.preview(player,0/0,200) end)
rejects(function() return B.preview(player,math.huge,200) end)
rejects(function() return B.preview(player,100.5,200) end)
rejects(function() return B.preview(player,900,900) end)
reset();world[key(100,200,0)].loose[1]={};rejects(preview)
reset();world[key(100,200,0)].moving[1]={};rejects(preview)
reset();world[key(100,200,0)].static[1]={};rejects(preview)
reset();square(103,203,3).objects[1]=object('foreign');rejects(preview)
reset();world[key(99,199,0)]=nil;rejects(preview)
reset();vehicles[1]={getX=function() return 105 end,getY=function() return 205 end};rejects(preview)
reset();sprites.walls_commercial_01_0=false;rejects(preview)
reset();preview();world[key(100,200,0)].loose[1]={}
rejects(function() return B.place(player,100,200) end);assert(not db.tower)

reset();local original=world[key(100,200,0)]:getFloor()
B.place(player,100,200);assert(db.tower.status=='ready')
assert(world[key(100,200,0)]:getFloor()==original)
rejects(function() return B.place(player,100,200) end)
local dropSquare=world[key(100,200,3)] or square(100,200,3);dropSquare.loose[1]={};rejects(function() return B.remove(player) end)
assert(db.tower)
-- Start a fresh fixture for the independent normal-cleanup case.
reset();B.place(player,100,200);original=world[key(100,200,0)]:getFloor()
B.remove(player);assert(not db.tower)
for _,sq in pairs(world) do
    for _,o in ipairs(sq.objects) do assert(o.sprite=='original','Prototype residue after cleanup') end
end
assert(world[key(100,200,0)]:getFloor()==original)

reset();B.place(player,100,200)
local foreign=object('foreign');local foreignSquare=world[key(102,202,2)] or square(102,202,2);foreignSquare.objects[#foreignSquare.objects+1]=foreign
rejects(function() return B.remove(player) end);assert(db.tower and foreign:getModData().TSBAstroluxStructure==nil)

-- Reload the Lua module while retaining persisted objects/state, then clean up.
reset();B.place(player,100,200)
package.loaded['TSBAstroluxStructure/Builder']=nil
B=require 'TSBAstroluxStructure/Builder'
B.remove(player);assert(not db.tower)

-- Fail in the floor pass and glass pass. All created objects must disappear.
for _,failure in ipairs({20,350,480}) do
    reset();failAt=failure
    rejects(function() return B.place(player,100,200) end);assert(not db.tower)
    for _,sq in pairs(world) do for _,o in ipairs(sq.objects) do assert(o.sprite=='original') end end
end
reset();failAt=350;removeFail=true
rejects(function() return B.place(player,100,200) end);assert(db.tower.status=='hold')
removeFail=false;failAt=nil;B.remove(player);assert(not db.tower)
print('PASS: perimeter, floors, four doors, lab isolation, obstruction checks, revalidation, duplicate prevention, cleanup and injected failures')

-- Ordinary site rejection must not throw (Kahlua logs thrown errors even under pcall).
reset();world[key(100,200,0)].loose[1]={}
local ok,result,reason=pcall(preview)
assert(ok and not result and reason:find('Dropped item') and reason:find('100, 200, 0'))
reset();world[key(99,199,0)]=nil
ok,result,reason=pcall(preview)
assert(ok and not result and reason:find('not loaded') and reason:find('99, 199, 0'))
-- The owner may stand in the safety margin, never inside the construction footprint.
reset();world[key(99,199,0)].moving[1]=player;assert(preview())
reset();world[key(100,200,0)].moving[1]=player
ok,result,reason=pcall(preview);assert(ok and not result and reason:find('Step outside'))
print('PASS: expected rejection is non-throwing, exact blocker coordinates, player margin and footprint guards')

local function legacy()
    reset()
    local record={id='legacy',x=100,y=200,revision=1,status='ready'}
    db.tower=record
    for z=1,5 do for x=100,107 do for y=200,207 do
        local sq=cell:createNewGridSquare(x,y,z)
        local obj=sq:addFloor('legacyfloor')
        obj:getModData().TSBAstroluxStructure=record.id
        obj:getModData().TSBAstroluxStructureKind='floor'
    end end end
    local sq=cell:getGridSquare(100,200,2)
    local wall=object('legacyglass');wall:getModData().TSBAstroluxStructure='legacy';wall:getModData().TSBAstroluxStructureKind='window'
    sq:AddSpecialObject(wall)
end
legacy();local ceiling=world[key(100,200,1)]:getFloor();local ground=world[key(100,200,0)]:getFloor()
assert(B.convert(player));assert(db.tower.revision==2)
assert(world[key(100,200,1)]:getFloor()==ceiling and world[key(100,200,0)]:getFloor()==ground)
local art=0
for _,sq in pairs(world) do for _,obj in ipairs(sq.objects) do
    assert(obj.sprite~='legacyglass')
    if obj:getModData().TSBAstroluxStructureKind=='art' then art=art+1 end
end end
assert(art==404 and not world[key(100,200,2)]:getFloor())
assert(B.convert(player));local count=0
for _,sq in pairs(world) do for _,obj in ipairs(sq.objects) do if obj:getModData().TSBAstroluxStructureKind=='art' then count=count+1 end end end
assert(count==404,'Conversion replay duplicated artwork')
B.remove(player);assert(not db.tower)
legacy();createCount=0;failAt=20
local converted,why=B.convert(player)
assert(not converted and why:find('restored') and db.tower.revision==1 and world[key(100,200,2)]:getFloor())
legacy();local dropSquare=world[key(100,200,3)] or square(100,200,3);dropSquare.loose[1]={}
converted,why=B.convert(player);assert(not converted and why:find('Dropped item') and db.tower.revision==1)
print('PASS: conversion preserves ground and ceiling, removes native upper stories, adds 404 pieces once, rejects occupied sites and rolls back failures')
