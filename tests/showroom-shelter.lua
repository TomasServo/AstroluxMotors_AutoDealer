function isClient()return false end
Events={LoadGridsquare={Add=function()end},OnTick={Add=function()end}}
local changed,roof=0,0
IsoRegions={squareChanged=function(_,force)assert(force);changed=changed+1 end}
function getCell()return {checkHaveRoof=function()roof=roof+1 end}end
local function square(owned)
 local o={getModData=function()return owned and {TSBAstroluxNativeHelperV1={owner='tower',kind='rain'}}or{}end,getSprite=function()return {getName=function()return 'TSBAstroluxBayCollision_3'end}end}
 return {getObjects=function()return {size=function()return 1 end,get=function()return o end}end,RecalcProperties=function()end,RecalcAllWithNeighbours=function()end,setSquareChanged=function()end,getX=function()return 3 end,getY=function()return 4 end}
end
local M=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxStructure/ShowroomShelter.lua')
M.visit(nil);M.visit(square(false));assert(changed==0)
local s=square(true);M.visit(s);M.visit(s);assert(changed==1 and roof==1)
M.visit(square(true));assert(changed==2,'Newly loaded squares must refresh again')
print('PASS: owned existing roof refresh, foreign exclusion, unload/reload and per-square idempotence')

local doorSquare=square(false)
local door={getModData=function()return {TSBAstroluxStructure='tower',TSBAstroluxStructureKind='slidingDoor'}end,getSprite=function()return {getName=function()return 'TSBAstroluxSlidingDoor_1'end}end}
function doorSquare:getObjects()return {size=function()return 1 end,get=function()return door end}end
M.visit(doorSquare);M.visit(doorSquare);assert(changed==3,'Owned doorway refresh occurs once without moving the door')
print('PASS: native doorway boundary refresh')
