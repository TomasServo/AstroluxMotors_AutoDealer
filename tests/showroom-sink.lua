package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
function isClient()return false end
function isServer()return false end
package.preload['Moveables/ISMoveableSpriteProps']=function()end
Events={OnTick={Add=function()end}}
local defaults={profile={objects={{dx=0,dy=6,sprite='appliances_cooking_01_60'}}}}
local exports=0
ModData={getOrCreate=function()return defaults end}
package.loaded['TSBAstroluxStructure/DecorCapture']={write=function(p)exports=exports+1;return true end}
local function object(name,index)
    return {getSprite=function()return {getName=function()return name end}end,getObjectIndex=function()return index end,
        getObjectName=function()return 'IsoObject'end,getRenderYOffset=function()return 1 end}
end
local floor=object('floor',0);local counter=object('fixtures_counters_01_57',1)
local entries={floor,counter};local blocked=false;local fail=false;local placed=0
local sq={getFloor=function()return floor end,getMovingObjects=function()return {size=function()return 0 end}end,
    getWorldObjects=function()return {size=function()return blocked and 1 or 0 end}end,
    getObjects=function()return {size=function()return #entries end,get=function(_,i)return entries[i+1]end}end}
function getCell()return {getGridSquare=function(_,x,y,z)assert(x==101 and y==207 and z==0);return sq end}end
function instanceItem(ft)assert(ft=='Base.Mov_ChromeSink');return {ReadFromWorldSprite=function(_,name)return name=='fixtures_sinks_01_11'end}end
ISMoveableSpriteProps={new=function(name)
    assert(name=='fixtures_sinks_01_11')
    return {canPlaceMoveable=function(_,p,square,item)assert(p==nil and square==sq);return true end,
        placeMoveableInternal=function(_,p,square,item,sprite)
            placed=placed+1;if fail then error('injected native placement failure')end
            local obj=object(sprite,2);entries[#entries+1]=obj;return obj
        end}
end}
local S=require 'TSBAstroluxStructure/ShowroomSink'
local r={x=100,y=200,status='ready'};local p={}
blocked=true;assert(not S.apply(r,p) and placed==0);blocked=false
entries[#entries+1]=object('plant',2);assert(not S.apply(r,p) and placed==0);table.remove(entries)
assert(S.apply(r,p) and placed==1 and entries[2]==counter and r.showroomSinkRevision==1)
assert(#defaults.profile.objects==2 and defaults.profile.objects[2].sprite==S.sprite and exports==1)
assert(S.apply(r,p) and placed==1,'Do not recreate an installed sink')
r.showroomSinkRevision=nil;assert(S.apply(r,p) and placed==1 and #defaults.profile.objects==2,'Adopt exact existing sink without duplicating it')
entries={floor,counter};r.showroomSinkRevision=nil;fail=true
assert(not pcall(S.apply,r,p) and r.showroomSinkHold)
assert(not S.apply(r,p) and placed==2,'Never replay uncertain native placement')
print('PASS: native sink on opposite counter, correct facing and default update, no object replacement/duplicates, uncertain placement held')
