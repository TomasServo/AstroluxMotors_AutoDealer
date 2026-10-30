local r={id='tower',x=100,y=100,status='ready',releaseTower=true}
package.loaded['TSBAstroluxStructure/Records']={all=function()return {r}end}
local live,generator,user,derelict,owner=true,false,true,false,'tower'
local sq={haveElectricity=function()return generator end,hasGridPower=function()return false end,getRoom=function()return nil end,getFloor=function()return {getModData=function()return {TSBAstroluxFlooring=owner}end}end,getZ=function()return 0 end,getX=function()return 105 end,getY=function()return 105 end,isUserDefinedRoom=function()return user end,isDerelict=function()return derelict end}
local outside={isInARoom=function()return false end,hasGridPower=function()return live end}
function getCell()return {getGridSquare=function()return outside end}end
local E=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/TSBAstroluxStructure/Electricity.lua')
assert(E.square(sq),'Recognized dealer room can use live exterior grid')
live=false;assert(not E.square(sq),'Blackout must turn dealer off')
generator=true;assert(E.square(sq),'Native generator remains authoritative');generator=false
live=true;owner='foreign';assert(not E.square(sq));owner='tower'
r.status='deleting';assert(not E.square(sq));r.status='ready'
derelict=true;assert(not E.square(sq));derelict=false
user=false;assert(not E.square(sq),'Do not bypass arbitrary native power refusal');user=true
function getCell()return {getGridSquare=function()return nil end}end
assert(not E.square(sq),'Unloaded exterior fails closed')
print('PASS: owned room grid supply, blackout, generator, foreign/deleting/derelict refusal and unloaded perimeter')
