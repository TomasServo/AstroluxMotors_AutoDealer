local db,world,save,addCalls,failAddAt={}, {},'AstroluxStructureLab',0,nil
function isClient() return false end
function isServer() return false end
function getDebug() return true end
function getWorld() return {getWorld=function() return save end} end
function getSprite(n) return {getName=function() return n end} end
function instanceof(o,c) return o.class==c end
ModData={getOrCreate=function() return db end}
local function list(t) return {size=function() return #t end,get=function(_,i) return t[i+1] end} end
local function object(class,sprite,north)
    local o={class=class,sprite=getSprite(sprite),north=north,md={},health=50,locked=false,perma=false}
    function o:getModData() return self.md end
    function o:getSprite() return self.sprite end
    function o:setSprite(s) self.sprite=s end
    function o:getNorth() return self.north end
    function o:getHealth() return self.health end
    function o:isLocked() return self.locked end
    function o:isPermaLocked() return self.perma end
    function o:setIsLocked(v) self.locked=v end
    function o:setPermaLocked(v) self.perma=v end
    function o:isBarricaded() return false end
    function o:HasCurtains() return self.curtain or false end
    function o:haveSheetRope() return false end
    function o:isDestroyed() return false end
    function o:isSmashed() return false end
    function o:IsOpen() return false end
    function o:isGlassRemoved() return false end
    function o:isInvincible() return false end
    return o
end
IsoWindow={new=function(_,_,sprite,north) return object('IsoWindow',sprite:getName(),north) end}
local function key(x,y) return x..':'..y end
local cell={getGridSquare=function(_,x,y,z) if z==0 then return world[key(x,y)] end end}
function getCell() return cell end
local player={isDead=function() return false end,getZ=function() return 0 end,getX=function() return 95 end,getY=function() return 195 end}
local function reset()
    db={tower={id='lab',x=100,y=200,revision=2,status='ready'}};world={};addCalls=0;failAddAt=nil
    for x=100,108 do for y=200,208 do
        local floor=object('floor','ground');local sq={objects={floor},loose={}}
        function sq:getObjects() return list(self.objects) end
        function sq:getWorldObjects() return list(self.loose) end
        function sq:getFloor() return floor end
        function sq:AddSpecialObject(o)
            addCalls=addCalls+1;if addCalls==failAddAt then error('injected insertion failure') end
            self.objects[#self.objects+1]=o
        end
        function sq:AddTileObject(o) self.objects[#self.objects+1]=o end
        function sq:RemoveTileObject(o) for i=#self.objects,1,-1 do if self.objects[i]==o then table.remove(self.objects,i) end end end
        function sq:RecalcAllWithNeighbours() end
        world[key(x,y)]=sq
    end end
    local function add(kind,x,y,north,sprite)
        local o=object(kind=='window' and 'IsoWindow' or kind=='door' and 'IsoDoor' or 'IsoObject',sprite,north)
        o.md={TSBAstroluxStructure='lab',TSBAstroluxStructureKind=kind,custom='preserved'}
        o.locked=true;o.perma=true
        world[key(x,y)]:AddTileObject(o);return o
    end
    for n=0,7 do for _,e in ipairs({{100+n,200,true},{100+n,208,true},{100,200+n,false},{108,200+n,false}}) do
        if n==3 then
            add('door',e[1],e[2],e[3],'fixtures_doors_01_'..(e[3] and 41 or 40))
            add('frame',e[1],e[2],e[3],'walls_commercial_01_'..(e[3] and 9 or 8))
        else add('window',e[1],e[2],e[3],'walls_commercial_01_'..(e[3] and 1 or 0)) end
    end end
    add('corner',108,208,false,'walls_commercial_01_2')
end
local M=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxStructure/ClearWalls.lua')
local function counts()
    local c={window=0,door=0,frame=0,corner=0}
    for _,sq in pairs(world) do for _,o in ipairs(sq.objects) do
        local kind=o.md.TSBAstroluxStructureKind
        if kind then c[kind]=c[kind]+1 end
    end end
    return c
end
reset();local ground=world[key(100,200)]:getFloor();assert(M.apply(player))
local c=counts();assert(c.window==24 and c.door==0 and c.frame==0 and c.corner==1)
assert(world[key(100,200)]:getFloor()==ground)
for _,sq in pairs(world) do for _,o in ipairs(sq.objects) do
    if o.md.TSBAstroluxStructureKind=='window' then
        assert(o.sprite:getName()=='TSBAstroluxClearGlass_'..(o.north and 1 or 0))
        assert(o.locked and o.perma and o.health==50 and o.md.custom=='preserved')
    end
end end
for n=3,4 do for _,p in ipairs({{100+n,200},{100+n,208},{100,200+n},{108,200+n}}) do
    assert(#world[key(p[1],p[2])].objects==1,'Entrance not fully open')
end end
assert(M.apply(player));assert(counts().window==24,'Replay duplicated panes')
reset();local damaged=world[key(100,200)].objects[2];damaged.health=10
assert(M.apply(player));assert(damaged.health==10 and damaged.sprite:getName()=='walls_commercial_01_1')
reset();local sq=world[key(103,200)];sq:AddTileObject(object('foreign','foreign'))
local ok,reason=M.apply(player);assert(not ok and reason:find('foreign'));assert(counts().door==4 and counts().window==28)
reset();failAddAt=2;ok,reason=M.apply(player);assert(not ok and reason:find('restored'))
c=counts();assert(c.window==28 and c.door==4 and c.frame==4 and db.tower.status=='ready')
reset();save='MainWorld';ok=M.apply(player);assert(not ok and counts().door==4)
print('PASS: 24 transparent panes, eight open entrance tiles, locks/health/data preserved, no duplicate migration and insertion rollback')
