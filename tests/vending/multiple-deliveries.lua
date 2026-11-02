package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local A=require 'TSBAstroluxVend/SpawnAreas'
local D=require 'TSBAstroluxVend/Domain'
function isClient()return false end
function isServer()return false end
package.loaded['TSBAstroluxVend/Delivery']={restore=function()end}
package.loaded['TSBAstroluxVend/Paint']={verify=function()end,apply=function()end}
local function script(w,l)return {getModel=function()return {}end,
    getExtents=function()return {x=function()return w end,z=function()return l end}end,
    getCenterOfMassOffset=function()return {x=function()return 0 end,z=function()return 0 end}end}end
local scripts={sedan=script(2,4),van=script(2,6),hilux=script(1.6889,4.5556)}
function getScriptManager()return {getVehicle=function(_,id)return scripts[id]end}end
IsoDirections={};for i,h in ipairs(A.directions)do local a=(i-1)*math.pi/2;IsoDirections[h]={toAngle=function()return a end}end
local vehicles,loaded={},true
local function list(items)return {size=function()return #items end,get=function(_,i)return items[i+1]end,
    iterator=function()local i=0;return {hasNext=function()return i<#items end,next=function()i=i+1;return items[i]end}end}end
local empty=list({})
Vector3f={new=function()local v={};function v:set(x,y,z)self.xx=x;self.yy=y;self.zz=z end
    function v:x()return self.xx end;function v:y()return self.yy end;function v:z()return self.zz end;return v end}
local function square(x,y)
    local floor={};return {getX=function()return x end,getY=function()return y end,
        TreatAsSolidFloor=function()return true end,isOutside=function()return true end,isFree=function()return true end,
        getMovingObjects=function()return empty end,getStaticMovingObjects=function()return empty end,
        getWorldObjects=function()return empty end,getFloor=function()return floor end,getObjects=function()return list({floor})end}
end
function getCell()return {getGridSquare=function(_,x,y,z)if loaded and z==0 then return square(x,y)end end,
    getVehicles=function()return list(vehicles)end}end
local keys,spawns,charges=0,0,0
function addVehicleDebug(name,dir,skin,sq)
    spawns=spawns+1
    local v={x=sq:getX()+0.5,y=sq:getY()+0.5,yaw=0,md={},id=spawns,script=scripts[name]}
    function v:getId()return self.id end
    function v:getX()return self.x end
    function v:getY()return self.y end
    function v:getZ()return 0 end
    function v:getAngleY()return self.yaw end
    function v:getWorldPos(point,out)
        local c,s=math.cos(math.rad(self.yaw)),math.sin(math.rad(self.yaw))
        out:set(self.x+c*point:x()-s*point:z(),self.y+s*point:x()+c*point:z(),0)
    end
    function v:getScript()return self.script end
    function v:getModData()return self.md end
    function v:transmitModData()end
    function v:getSquare()return sq end
    function v:setDir(d)self.dir=d end
    function v:setAngles(_,yaw)self.yaw=yaw end
    function v:createVehicleKey()return {id=self.id}end
    vehicles[#vehicles+1]=v;return v
end
local S=require 'TSBAstroluxVend/VehicleSpawn'
S.regions=function()return loaded and {{x1=-100,y1=-100,x2=100,y2=100}} or {}end
local player={getInventory=function()return {AddItem=function(_,key)keys=keys+1;return key end}end}
local db={orders={}}
local function service()return D.new(db,{now=function()return 1000 end,
    clear=function(t,own,id)return S.choose(db,t,own,id)end,
    charge=function(_,_,_,apply)charges=charges+1;apply({set=function(_,t,k,v)t[k]=v end})end,
    spawn=function(order)S.create(order,player)end})end
local domain=service()
local function offer(id)return {id=id,script=id,price=1000}end
local function buy(actor,t,id)
    local q=domain:quote(actor,t,offer(id));return domain:buy(actor,q.token,t,offer(id))
end
local t={id='one',spawnArea=assert(A.rectangle(0,0,5,6,'N'))};t.spawnArea.revision=1
-- Two concurrent quotes may initially see the same gap. Purchases must reselect.
local qa=domain:quote('a',t,offer('sedan'));local qb=domain:quote('b',t,offer('hilux'))
local a=domain:buy('a',qa.token,t,offer('sedan'));local b=domain:buy('b',qb.token,t,offer('hilux'))
assert(a.status=='delivered' and b.status=='delivered' and not A.overlap(a.placement,b.placement))
assert(a.placement.rx*2+1==3 and b.placement.rx*2+1==3,'Each car occupies one ordinary three-tile-wide parking space')
assert(spawns==2 and charges==2 and keys==2,'Two cars, two charges, two keys')
local no,why=S.choose(db,t,nil,'sedan',true);assert(not no and why:find('clear'))
assert(spawns==2 and charges==2 and keys==2,'Full area cannot spawn or charge')
-- Moving an actual vehicle frees its old position; historical orders do not.
vehicles[1].x=-50;vehicles[1].y=-50
local again=buy('a',t,'sedan');assert(again.status=='delivered' and spawns==3 and keys==3)
-- Yaw-aware bounds safely allow neighboring rows and protect diagonal vehicles.
local diagonal=vehicles[2];diagonal.yaw=45
local bound=A.vehicleBounds(diagonal);assert(bound.rx>2.5 and bound.ry>2.5)
assert(not S.clear(db,{x=diagonal.x+4,y=diagonal.y,rx=2,ry=3},nil))
-- Find a usable gap that is not aligned to the initial packing grid.
local gap=assert(A.find(A.rectangle(0,0,13,6,'N'),2,3,{{x1=0,y1=0,x2=13,y2=6}},function(p)return p.x==6 end))
assert(gap.x==6)
-- Reservations are global across kiosks; mixed footprints remain distinct.
vehicles={};db={orders={}};domain=service();loaded=false
local wide=assert(A.rectangle(0,0,35,20,'E'));wide.revision=1
local ta={id='A',spawnArea=wide};local tb={id='B',spawnArea=wide}
local first=buy('a',ta,'van');local second=buy('b',tb,'hilux')
assert(first.status=='queued' and second.status=='queued' and not A.overlap(first.placement,second.placement))
local function clone(t)if type(t)~='table'then return t end;local out={};for k,v in pairs(t)do out[k]=clone(v)end;return out end
db=clone(db);domain=service() -- Simulate persisted reservation reload.
local third=buy('c',tb,'sedan')
assert(third.status=='queued')
for _,o in pairs(db.orders)do for _,other in pairs(db.orders)do if o~=other then assert(not A.overlap(o.placement,other.placement))end end end
-- A moved car may occupy a queued reservation before streaming resumes.
loaded=true
local held=db.orders.a.placement
addVehicleDebug('sedan',IsoDirections.N,nil,square(held.x,held.y))
local before=spawns
domain:deliver('a',ta);domain:deliver('b',tb);domain:deliver('c',tb)
assert(spawns==before+3 and db.orders.a.status=='delivered' and db.orders.b.status=='delivered' and db.orders.c.status=='delivered')
for i=1,#vehicles do for j=i+1,#vehicles do assert(not A.overlap(A.vehicleBounds(vehicles[i]),A.vehicleBounds(vehicles[j])),'Native vehicle envelopes overlap')end end
local final=spawns;assert(not pcall(domain.deliver,domain,'a',ta) and spawns==final,'Delivered orders cannot spawn twice')
-- The user's 14x7 lot fits four normal-width Hilux spaces, not one giant halo.
for _,heading in ipairs(A.directions)do
    vehicles={};db={orders={}};domain=service()
    local sideways=heading=='E' or heading=='W'
    local parking=assert(A.rectangle(0,0,sideways and 6 or 13,sideways and 13 or 6,heading));parking.revision=1
    local kiosk={id='parking',spawnArea=parking}
    for i=1,4 do assert(buy('same-buyer',kiosk,'hilux').status=='delivered')end
    assert(#vehicles==4)
    for i=1,4 do for j=i+1,4 do assert(not A.overlap(A.vehicleBounds(vehicles[i]),A.vehicleBounds(vehicles[j])))end end
    local blocked=S.choose(db,kiosk,nil,'hilux',true);assert(not blocked,'Full parking row must reject a fifth vehicle')
end
print('PASS: multiple vehicles, simultaneous quotes, full-area rejection, moved cars, diagonal bounds, mixed queued footprints, cross-kiosk reservations, reload and relocation')
