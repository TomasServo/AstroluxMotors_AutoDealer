-- Exercise the actual demo initialization and cash grant with native boundaries mocked.
local base='mods/PZ_TSB_AstroluxTestMap/42/media/lua/server/TSBAstroluxTestMap/'
local challenge=true;local challengeID='AstroluxMotorsDemo';local world='generated-world';local fresh=true;local powered=true
function getCore()return {isChallenge=function()return challenge end,getChallengeID=function()return challengeID end}end
function getWorld()return {getWorld=function()return world end}end
local config={bundledDemo=true}
package.loaded['TSBAstroluxTestMap/Config']=config
package.loaded['AstroluxBayTest/TestWorld']={freshLot=function()return fresh end}
local record={id='structure:118:121',x=118,y=121,status='ready',combinedSize=12,furnishingsRevision=1}
local records={record}
package.loaded['TSBAstroluxStructure/Records']={all=function()return records end}
package.loaded['TSBAstroluxVend/SpawnAreas']=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/TSBAstroluxVend/SpawnAreas.lua')
package.loaded['TSBAstroluxVend/Power']={available=function()return powered end}
local stores={}
ModData={get=function(k)return stores[k]end,getOrCreate=function(k)stores[k]=stores[k]or {};return stores[k]end}
local a={kiosk=true,x=121,y=121,z=0};local b={kiosk=true,x=126,y=121,z=0}
local foreign={kiosk=true,x=160,y=160,z=0}
local function reset()
 a.spawnArea=nil;b.spawnArea=nil
 stores={['TSBAstroluxDemoScenario.v1']={status='ready',recordId=record.id},['TSBAstroluxVend.State.v1']={terminals={a=a,b=b,foreign=foreign},orders={}}}
 return dofile(base..'DemoReady.lua')
end
local demo=reset()
assert(demo.update());assert(a.spawnArea.x1==117 and a.spawnArea.y1==108 and a.spawnArea.x2==132 and a.spawnArea.y2==118)
assert(b.spawnArea.x1==134 and b.spawnArea.y1==120 and b.spawnArea.x2==143 and b.spawnArea.y2==137)
assert(a.deliveryBorder and b.deliveryBorder and not foreign.spawnArea)
local edited={x1=150,revision=7};a.spawnArea=edited
assert(dofile(base..'DemoReady.lua').update()and a.spawnArea==edited,'Reload preserves zone edits')
a.spawnArea=nil;assert(not demo.update()and not a.spawnArea,'Deliberately removed zone is not recreated')
for _,mode in ipairs({'other-challenge','ordinary-world','multiplayer','pending','missing-record','missing-kiosk','packed-kiosk','held-order'})do
 demo=reset();challenge=true;challengeID='AstroluxMotorsDemo';fresh=true;records={record}
 if mode=='other-challenge'then challengeID='Other'
 elseif mode=='ordinary-world'then challenge=false
 elseif mode=='multiplayer'then fresh=false
 elseif mode=='pending'then stores['TSBAstroluxDemoScenario.v1'].status='placing'
 elseif mode=='missing-record'then records={}
 elseif mode=='missing-kiosk'then stores['TSBAstroluxVend.State.v1'].terminals.b=nil
 elseif mode=='packed-kiosk'then b.packed=true
 elseif mode=='held-order'then stores['TSBAstroluxVend.State.v1'].orders.alice={status='hold'}end
 assert(not demo.update()and not a.spawnArea and not b.spawnArea,mode..' must not mutate zones')
 b.packed=nil
end
challenge=true;challengeID='AstroluxMotorsDemo';fresh=true;records={record}
demo=reset();a.spawnArea=edited;assert(demo.update()and a.spawnArea==edited,'Initial setup keeps existing zone')
powered=false;assert(not demo.update());powered=true;assert(demo.update())
-- Actual grant: 250 native $100 bundles, once per character across Lua reloads.
package.loaded['TSBAstroluxTestMap/DemoReady']=demo
Events={OnTick={Add=function()end}}
local md={};local inventory={items={}};local failAfterInsert=false
function inventory:AddItem(item)
 self.items[#self.items+1]=item
 if failAfterInsert then error('uncertain native insertion')end
 return item
end
local player={isDead=function()return false end,getModData=function()return md end,getInventory=function()return inventory end,Say=function()end}
function getSpecificPlayer()return player end
function instanceItem(kind)
 assert(kind=='Base.MoneyBundle');local data={}
 return {setActualWeight=function(_,w)assert(w==0)end,setCustomWeight=function(_,v)assert(v)end,getModData=function()return data end}
end
local cash=dofile(base..'StarterCash.lua')
powered=false;cash.update();assert(#inventory.items==0);powered=true
for i=1,10 do cash.update()end
assert(#inventory.items==250 and md['TSBAstroluxTestMap.StarterCash.v1'].done)
cash=dofile(base..'StarterCash.lua');cash.update();assert(#inventory.items==250,'Reload must not duplicate grant')
md={};inventory.items={};cash.update();assert(#inventory.items==25)
cash=dofile(base..'StarterCash.lua');for i=1,9 do cash.update()end;assert(#inventory.items==250,'Partial completed batches resume exactly')
md={};inventory.items={};failAfterInsert=true;cash.update();assert(#inventory.items==1 and md['TSBAstroluxTestMap.StarterCash.v1'].hold)
failAfterInsert=false;cash=dofile(base..'StarterCash.lua');cash.update();assert(#inventory.items==1,'Uncertain insertion must not replay')
print('PASS demo defaults: exact challenge/record scope, relative clear zones, foreign/held/partial refusal, edited-zone persistence, power gate, $25000 once per character and safe interrupted grants')
