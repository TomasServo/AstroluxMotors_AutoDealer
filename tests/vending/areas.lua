package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local A=require 'TSBAstroluxVend/SpawnAreas'
local area=assert(A.rectangle(1000000,2000000,-50000,-60000,'W'))
assert(area.x1==-50000 and area.y2==2000000 and area.heading=='W')
assert(A.rectangle(1,1,1,1,'N'),'Single-tile configuration is permitted')
assert(not A.rectangle(1.2,1,3,4,'N'));assert(not A.rectangle(0/0,1,3,4,'N'))
assert(not A.rectangle(1,1,3,4,'NW'))
local function script(x,z)
    return {getModel=function() return {} end,getExtents=function() return {x=function() return x end,z=function() return z end} end,
        getCenterOfMassOffset=function() return {x=function() return 0 end,z=function() return 0 end} end}
end
local rx,ry=A.measure(script(2,4),'N');assert(rx==2 and ry==3)
rx,ry=A.measure(script(2,4),'E');assert(rx==3 and ry==2)
rx,ry=A.measure(script(100,200),'S');assert(rx>32 and ry>32,'No previous vehicle-radius ceiling')
local calls=0
local p=assert(A.find(area,2,3,{{x1=999900,y1=1999900,x2=1000000,y2=2000000}},function(q) calls=calls+1;return true end))
assert(calls==1 and A.contains(area,p),'Huge remote area only searches loaded intersection')
local small=assert(A.rectangle(0,0,1,1,'N'))
assert(not A.find(small,2,3,{},function() error('Must reject physical mismatch without probing') end))
assert(not A.find(area,2,3,{},function() error('Must not probe unloaded map') end))
local grid=assert(A.rectangle(0,0,30,30,'N'));local seen={}
local point=A.find(grid,2,3,{{x1=0,y1=0,x2=30,y2=30},{x1=0,y1=0,x2=30,y2=30}},function(q)
    local k=q.x..':'..q.y;assert(not seen[k]);seen[k]=true
    assert((q.x-2)%5==0 and (q.y-3)%7==0);return false
end)
assert(not point)
local first=assert(A.reserve(area,2,3,{}))
local second=assert(A.reserve(area,2,3,{first}))
assert(not A.overlap(first,second) and A.contains(area,second))
assert(not A.reserve(small,2,3,{}))
local full={x=15,y=15,rx=15,ry=15}
assert(not A.reserve(grid,2,3,{full}),'Fully reserved area cannot sell another space')
-- Native spawn direction and exact angle replace debug spawn's random yaw.
function isClient() return false end
function isServer() return false end
local restored,painted
package.loaded['TSBAstroluxVend/Delivery']={restore=function() restored=true end}
package.loaded['TSBAstroluxVend/Paint']={verify=function() end,apply=function() painted=true end}
function getScriptManager() return {getVehicle=function() return script(2,4) end} end
local sq={};function getCell() return {getGridSquare=function() return sq end} end
IsoDirections={}
for i,h in ipairs(A.directions) do local angle=(i-1)*math.pi/2;IsoDirections[h]={toAngle=function() return angle end} end
local created
function addVehicleDebug(name,dir,skin,square)
    assert(square==sq);local v={md={},dir=dir}
    function v:getId() return 42 end
    function v:getModData() return self.md end
    function v:transmitModData() end
    function v:getSquare() return sq end
    function v:setDir(d) self.dir=d end
    function v:setAngles(x,y,z) self.angle={x,y,z} end
    function v:createVehicleKey() return {id=42} end
    created=v;return v
end
local S=require 'TSBAstroluxVend/VehicleSpawn'
local inventory={AddItem=function(_,key) return key end}
local player={getInventory=function() return inventory end}
for _,h in ipairs(A.directions) do
    local o={id='test',script='Base.CarNormal',placement={x=100,y=200,heading=h}}
    S.create(o,player)
    assert(created.dir==IsoDirections[h] and created.angle[1]==0 and created.angle[3]==0)
    assert(math.abs(created.angle[2]-(math.deg(IsoDirections[h]:toAngle())+180)%360)<0.0001)
    assert(o.vehicleId==42 and o.keyIssued and restored and painted)
end
-- Exercise actual selection/clearance code, not only the geometric planner.
local loaded,blocked=true,false
local function list(items) return {size=function() return #items end,get=function(_,i) return items[i+1] end} end
local empty=list({})
local function tile(x,y)
    local floor={}
    return {TreatAsSolidFloor=function() return true end,isOutside=function() return true end,
        isFree=function() return not blocked end,getMovingObjects=function() return empty end,
        getStaticMovingObjects=function() return empty end,getWorldObjects=function() return empty end,
        getFloor=function() return floor end,getObjects=function() return list({floor}) end,
        isSeen=function() error('Exploration must not be queried') end}
end
local world={getGridSquare=function(_,x,y,z) if loaded and x>=0 and y>=0 and x<=20 and y<=20 then return tile(x,y) end end,
    getVehicles=function() return {iterator=function() return {hasNext=function() return false end} end} end}
function getCell() return world end
S.regions=function() return loaded and {{x1=0,y1=0,x2=20,y2=20}} or {} end
local configured=assert(A.rectangle(0,0,20,20,'N'));configured.revision=1
local terminal={spawnArea=configured};local db={orders={}}
local chosen=S.choose(db,terminal,nil,'Base.CarNormal');assert(not chosen.deferred and A.contains(configured,chosen))
blocked=true;assert(not pcall(S.choose,db,terminal,nil,'Base.CarNormal'),'Known blocked fully loaded ground must not sell a reservation')
loaded=false;local remote=S.choose(db,terminal,nil,'Base.CarNormal');assert(remote.deferred)
local own={status='queued',placement=remote};db.orders.alice=own
assert(not pcall(S.choose,db,terminal,own,'Base.CarNormal'))
loaded=true;blocked=false
local restored=S.choose(db,terminal,own,'Base.CarNormal');assert(restored.x==remote.x and restored.y==remote.y and not restored.deferred)
db.orders.bob={status='queued',placement=restored}
local relocated=S.choose(db,terminal,own,'Base.CarNormal');assert(not A.overlap(relocated,restored),'Reservations across buyers may not overlap')
print('PASS: unrestricted remote rectangles, streamed-only bounded search, actual vehicle fit, no old radius cap, four exact cardinal headings')
