package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
function isClient()return false end
function isServer()return false end
Events=setmetatable({},{__index=function(t,k)local e={Add=function()end};t[k]=e;return e end})
function getTimestamp()return 1000 end
package.preload['Moveables/ISMoveableSpriteProps']=function()end
local layout=require 'TSBAstroluxStructure/DefaultFurnishings'
local definitions={};for _,entry in ipairs(layout.objects)do definitions[entry.sprite]=entry end
local vend={serial=10,terminals={original={id='original',x=0,y=0,z=0}},orders={alice={terminal='original',status='queued'}}}
local lab={tower={id='original-room',x=0,y=0,status='ready'}}
ModData={getOrCreate=function(key)if key=='TSBAstroluxVend.State.v1' then return vend end;return lab end}
package.loaded['TSBAstroluxVend/Cash']={new=function()return {}end}
package.loaded['TSBAstroluxVend/BankPayments']={new=function()return {}end}
package.loaded['TSBAstroluxVend/Domain']={new=function()return {quotes={}}end}
local world={};local failAt,failAfter,created= nil,false,0
local function list(items)return {size=function()return #items end,get=function(_,i)return items[i+1]end}end
local function object(sq,sprite)
    local md={};local obj={sq=sq,sprite=sprite,offset=0}
    function obj:getModData()return md end
    function obj:getSprite()return {getName=function()return self.sprite end}end
    function obj:getSquare()return self.sq end
    function obj:getObjectIndex()for i,o in ipairs(self.sq.objects)do if o==self then return i-1 end end;return -1 end
    function obj:setRenderYOffset(v)self.offset=v end
    function obj:transmitModData()end
    function obj:setIsThumpable()end
    function obj:setIsDismantable()end
    return obj
end
local function room(x,y)
    local r={id='room:'..x..':'..y,x=x,y=y,status='ready'}
    for dx=0,7 do for dy=0,7 do
        local sq={x=x+dx,y=y+dy,objects={}}
        function sq:getX()return self.x end
        function sq:getY()return self.y end
        function sq:getZ()return 0 end
        function sq:getObjects()return list(self.objects)end
        function sq:getFloor()return self.objects[1]end
        function sq:TreatAsSolidFloor()return true end
        function sq:getMovingObjects()return list({})end
        function sq:getStaticMovingObjects()return list({})end
        function sq:getWorldObjects()return list({})end
        function sq:RecalcAllWithNeighbours()end
        function sq:transmitRemoveItemFromSquare(obj)for i,o in ipairs(self.objects)do if obj==o then table.remove(self.objects,i);return end end end
        sq.objects[1]=object(sq,'floor');world[sq.x..':'..sq.y]=sq
    end end
    return r
end
function getCell()return {getGridSquare=function(_,x,y,z)assert(z==0);return world[x..':'..y]end}end
function getSprite(name)return {getName=function()return name end}end
ISMoveableSpriteProps={canPickUpMoveable=function()return true end,pickUpMoveableInternal=function()end,
    doBreakTest=function()return false end,canScrapObject=function()return false end,scrapObject=function()end,
    rotateMoveableInternal=function()end,rotateMoveable=function()end}
local P=ISMoveableSpriteProps
local function isTop(name)return name=='appliances_cooking_01_60' or name=='fixtures_sinks_01_11' or name=='vegetation_indoor_01_3' or name=='lighting_indoor_02_35'end
function P:instanceItem()local md={};return {getModData=function()return md end}end
function P:canPlaceMoveableInternal(p,sq,item)
    assert(p==nil,'Geometry validation must not consume player supplies or tools')
    if self.isTableTop then
        for _,obj in ipairs(sq.objects)do if obj.sprite:find('fixtures_counters_',1,true) or obj.sprite:find('furniture_tables_',1,true) then return true end end
        -- Native cactus BlocksPlacement permits this captured floor position.
        return self.spriteName=='vegetation_indoor_01_3'
    end
    return true
end
function P:placeMoveableInternal(p,sq,item,name)
    created=created+1
    if failAt==created and not failAfter then error('injected native placement failure')end
    local obj=object(sq,name);sq.objects[#sq.objects+1]=obj
    obj.nativeType=definitions[name].objectType
    if failAt==created and failAfter then error('injected post-insertion failure')end
    return obj
end
function P.new(name)return setmetatable({spriteName=name,isMoveable=true,isTableTop=isTop(name)},{__index=P})end
local F=require 'TSBAstroluxStructure/Furnishings'
local r=room(100,200);assert(F.apply(r,{}));assert(r.furnishingCount==19 and r.showroomSinkRevision==1)
local count,kiosks=0,{}
for _,sq in pairs(world)do for _,obj in ipairs(sq.objects)do if obj.sprite~='floor' then
    count=count+1;local entry=definitions[obj.sprite];assert(entry and obj.offset==entry.renderYOffset)
    assert(obj.nativeType==entry.objectType)
    if entry.service then local id=obj:getModData().TSBAstroluxVend;assert(id and id~='original');kiosks[id]=true;assert(not vend.terminals[id].spawnArea)end
    if entry.coffeeSupplies then assert(obj:getModData().movableData.TSBAstroluxCoffeeSuppliesV1.pending)end
end end end
assert(count==19 and kiosks['terminal:11'] and kiosks['terminal:12'])
assert(F.apply(r,{}) and created==19,'Do not duplicate a pasted furnishing layout')
assert(vend.orders.alice.status=='queued' and vend.terminals.original,'Existing purchases and kiosks remain intact')
local blocked=room(200,200);world['200:202'].objects[2]=object(world['200:202'],'foreign')
assert(not F.apply(blocked,{}) and created==19,'Existing objects must block before native placement')
for _,after in ipairs({false,true})do
    local r2=room(after and 400 or 300,200);failAt=created+6;failAfter=after
    local priorSerial=vend.serial
    assert(not F.apply(r2,{}));assert(not r2.furnishingsHold)
    for dx=0,7 do for dy=0,7 do assert(#world[(r2.x+dx)..':'..(r2.y+dy)].objects==1)end end
    for id in pairs(vend.terminals)do assert(id=='original' or kiosks[id],'Rolled-back kiosk registrations must not survive')end
    assert(vend.serial>=priorSerial,'Never rewind the identity allocator')
end
print('PASS: all 19 native furnishing entries and offsets, fresh kiosks, tabletop ordering, no inventory/identity copies, collision rejection and post-insertion rollback')
