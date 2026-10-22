package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
Events=setmetatable({},{__index=function(t,k)local v={Add=function()end};t[k]=v;return v end})
local client=false
function isClient()return client end
function isServer()return not client end
function getTimestamp()return 1 end
function getTimestampMs()return 1000 end
local db={serial=1,terminals={one={id='one',x=1,y=2,z=0,sprite='TSBAstroluxKiosk_0',spawnArea={x1=100,x2=120,heading='N'},ownerSetting=57}},orders={}}
ModData={getOrCreate=function()return db end}
local service={quotes={alice={}}}
package.loaded['TSBAstroluxVend/Cash']={new=function()return {}end}
package.loaded['TSBAstroluxVend/BankPayments']={new=function()return {}end}
package.loaded['TSBAstroluxVend/Domain']={new=function()return service end}
local S=require 'TSBAstroluxVend/Server'
local function square(x,y)
    return {x=x,y=y,getX=function(s)return s.x end,getY=function(s)return s.y end,getZ=function()return 0 end,TreatAsSolidFloor=function()return true end}
end
local function object(sq,md,name)
    return {sq=sq,md=md,index=0,name=name or 'TSBAstroluxKiosk_0',getModData=function(s)return s.md end,getObjectIndex=function(s)return s.index end,
        getSquare=function(s)return s.sq end,getSprite=function(s)return {getName=function()return s.name end}end,
        setIsThumpable=function()end,setIsDismantable=function()end,transmitModData=function()end}
end
local carried,removed,placed= nil,0,0
ISMoveableSpriteProps={
    canPickUpMoveable=function()return true end,
    pickUpMoveableInternal=function(self,p,sq,obj)
        -- Vanilla IsoThumpable saveThumpableParameters carries nested ModData.
        carried={data={modData={TSBAstroluxVend=obj.md.TSBAstroluxVend}},getModData=function(s)return s.data end}
        obj.index=-1;removed=removed+1;return carried
    end,
    placeMoveableInternal=function(self,p,sq,item,name)
        placed=placed+1;return object(sq,item.data.modData or {},name)
    end,
    doBreakTest=function()return true end,canScrapObject=function()return true end,scrapObject=function()error('must not scrap kiosk')end,
    rotateMoveableInternal=function()end,rotateMoveable=function(self)self.rotations=(self.rotations or 0)+1 end}
package.preload['Moveables/ISMoveableSpriteProps']=function()end
require 'TSBAstroluxVend/KioskFurniture'
local P=ISMoveableSpriteProps
local props=setmetatable({spriteName='TSBAstroluxKiosk_0'},{__index=P})
local sq=square(1,2);local obj=object(sq,{TSBAstroluxVend='one'})
function props:findOnSquare()return obj end
local p={Say=function()end}
for _,status in ipairs({'queued','paid','dispatching','hold'})do
    db.orders.bob={terminal='one',status=status}
    assert(not props:canPickUpMoveable(p,sq,obj))
    props:pickUpMoveableInternal(p,sq,obj,nil,props.spriteName,true,true)
    props:rotateMoveable(p,sq,props.spriteName)
    assert(not props.rotations,'Pending rotation must not run forced pickup + replacement')
    assert(removed==0,'Completion must refuse even forced/cheat pickup of outstanding order')
end
client=true;obj.md.TSBAstroluxPending=true
assert(not props:canPickUpMoveable(p,sq,obj),'Client UI must respect replicated lock')
client=false;db.orders.bob.status='delivered'
assert(props:canPickUpMoveable(p,sq,obj))
props:rotateMoveable(p,sq,props.spriteName);assert(props.rotations==1)
local area=db.terminals.one.spawnArea
assert(not props:doBreakTest(p) and not props:canScrapObject(p));props:scrapObject(p)
props:pickUpMoveableInternal(p,sq,obj,nil,props.spriteName,true,false)
assert(removed==1 and db.terminals.one.packed and not next(service.quotes))
-- Simulate world reload while the kiosk is in inventory.
package.loaded['TSBAstroluxVend/Server']=nil;S=require 'TSBAstroluxVend/Server'
local moved=props:placeMoveableInternal(p,square(300,400),carried,'TSBAstroluxKiosk_2')
local t=db.terminals.one
assert(t.x==300 and t.y==400 and t.sprite=='TSBAstroluxKiosk_2' and not t.packed)
assert(t.spawnArea==area and t.ownerSetting==57 and moved.md.TSBAstroluxVend=='one')
assert(not pcall(props.placeMoveableInternal,props,p,square(500,500),carried,'TSBAstroluxKiosk_0') and placed==1,'Reject second placement of same kiosk identity')
local fresh={getModData=function()return {}end,data={}}
local new=props:placeMoveableInternal(p,square(30,40),fresh,'TSBAstroluxKiosk_0')
assert(new.md.TSBAstroluxVend=='terminal:2' and db.terminals['terminal:2'])
local other=setmetatable({spriteName='vanilla_other'},{__index=P})
assert(other:doBreakTest(p) and other:canScrapObject(p),'Leave ordinary furniture alone')
print('PASS: native furniture hooks retain kiosk identity/setup through packed reload, block pending/forced pickup and duplicate placement')
