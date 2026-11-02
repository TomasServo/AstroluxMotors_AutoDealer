package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;'..package.path
package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
function isClient()return false end
function isServer()return false end
Events={OnTick={Add=function()end}}
local function item(ft)return {getFullType=function()return ft end}end
function instanceItem(ft)return item(ft)end
local R=require 'TSBAstroluxVend/CoffeeSupplies'
local function cabinet()
    local data,items={},{};local room=true
    local list={size=function()return #items end,get=function(_,i)return items[i+1]end,contains=function(_,obj)for _,it in ipairs(items)do if it==obj then return true end end;return false end}
    local container={getItems=function()return list end,hasRoomFor=function()return room end,AddItem=function(_,obj)items[#items+1]=obj;return obj end}
    local obj={getModData=function()return data end,getContainer=function()return container end,transmitModData=function()end}
    return obj,items,data,function(v)room=v end
end
local function count(items,ft)local n=0;for _,it in ipairs(items)do if it:getFullType()==ft then n=n+1 end end;return n end
local function remove(items,ft)for i,it in ipairs(items)do if it:getFullType()==ft then return table.remove(items,i)end end;error('missing '..ft)end
local obj,items,md,capacity=cabinet();items[1]=item('Base.PlayerBelonging')
R.mark(obj);R.update(obj,1000)
for ft,target in pairs(R.targets)do assert(count(items,ft)==target,ft)end
assert(count(items,'Base.PlayerBelonging')==1 and count(items,'Base.Milk')==1)
local coffee=remove(items,'Base.Coffee2');R.update(obj,1001)
R.update(obj,1600);assert(count(items,'Base.Coffee2')==1,'Do not refill before 600 real seconds')
R.update(obj,1601);assert(count(items,'Base.Coffee2')==2)
remove(items,'Base.Coffee2');R.update(obj,2000)
remove(items,'Base.Coffee2');R.update(obj,2100)
R.update(obj,2600);assert(count(items,'Base.Coffee2')==1,'Separate deadlines per missing unit')
R.update(obj,2700);assert(count(items,'Base.Coffee2')==2)
local mug=remove(items,'Base.MugWhite');R.update(obj,3000);items[#items+1]=mug;R.update(obj,3100)
R.update(obj,3600);assert(count(items,'Base.MugWhite')==4,'Returned item cancels pending replacement')
items[#items+1]=item('Base.MugWhite');R.update(obj,4000);assert(count(items,'Base.MugWhite')==5,'Never remove extra player stock')
remove(items,'Base.Milk');R.update(obj,5000);capacity(false);R.update(obj,5600);assert(count(items,'Base.Milk')==0)
-- Pending epochs live in native movableData, not a Lua runtime timer.
package.loaded['TSBAstroluxVend/CoffeeSupplies']=nil;R=require 'TSBAstroluxVend/CoffeeSupplies'
capacity(true);R.update(obj,9000);assert(count(items,'Base.Milk')==1)
R.update(obj,9001);assert(count(items,'Base.Milk')==1 and count(items,'Base.PlayerBelonging')==1)
assert(md.movableData[R.key].pending and md.movableData[R.key].initialized)
local a,aItems,aData=cabinet();local b,bItems,bData=cabinet()
local function cornerSprite()return {getProperties=function()return {get=function(_,key)return key=='GroupName' and 'Dark Corner' or 'Counter'end}end}end
a.getSprite=cornerSprite;b.getSprite=cornerSprite
local candidates={a,b};local now=10000
function getTimestamp()return now end
ModData={getOrCreate=function()return {tower={x=100,y=200,status='ready'}}end}
function getCell()return {getGridSquare=function(_,x,y)
    local entries=x==100 and y==200 and candidates or {}
    return {getObjects=function()return {size=function()return #entries end,get=function(_,i)return entries[i+1]end}end}
end}end
R.tick();assert(not aData.movableData and not bData.movableData,'Ambiguous corners must not be auto-selected')
candidates={a};now=10001;R.tick()
assert(aData.movableData and count(aItems,'Base.Coffee2')==2 and not bData.movableData)
print('PASS: coffee cabinet targets, per-unit 600-second delays, staggered removals, returned stock, capacity, reload and player belongings')
