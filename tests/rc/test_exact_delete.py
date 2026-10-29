from pathlib import Path
import os
os.chdir(Path(__file__).resolve().parents[2])
from lupa.lua51 import LuaRuntime
l=LuaRuntime();l.execute('''
function isServer()return false end
local r={id='tower',x=0,y=0,releaseTower=1,status='deleting'}
state={tower=r};package.loaded['TSBAstroluxStructure/Records']={all=function()return state.tower and {state.tower}or {}end,state=function()return state end}
package.loaded['TSBAstroluxStructure/ReleaseAccess']={allowed=function()return true end}
local empty={size=function()return 0 end};local objects={}
local sq={getX=function()return 0 end,getY=function()return 0 end,getZ=function()return 0 end,getMovingObjects=function()return empty end,getStaticMovingObjects=function()return empty end,RecalcAllWithNeighbours=function()end}
function sq:getObjects()return {size=function()return #objects end,get=function(_,i)return objects[i+1]end}end
local o={getModData=function()return {movableData={TSBAstroluxFurnishingV1={tower='tower'}}}end,getObjectIndex=function()return #objects>0 and 0 or -1 end}
objects={o}
function sq:transmitRemoveItemFromSquare(obj,group)assert(group==false,'Incomplete multi-tile group would refuse removal');assert(obj==o);objects={}end
function getCell()return {getGridSquare=function(_,x,y,z)if z==0 then return sq end end,getVehicles=function()return {iterator=function()return {hasNext=function()return false end}end}end}end
ModData={getOrCreate=function()return {}end}
function getTimestampMs()return 1000 end;function getTimestamp()return 1 end
p={getUsername=function()return 'admin'end,getX=function()return 16 end,getY=function()return 0 end,getZ=function()return 0 end}
''')
m=l.execute(Path('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxStructure/ReleaseDelete.lua').read_text(encoding='utf-8'));l.globals().M=m
l.execute("local review=M.review(p,'tower');assert(review);assert(M.execute(p,review.token));assert(state.tower==nil);assert(M.execute(p,review.token)==nil)")
print('PASS: interrupted deletion resumes using exact-object removal; record cleared only after removal; token cannot replay.')
