from pathlib import Path
import os
os.chdir(Path(__file__).resolve().parents[2])
from lupa.lua51 import LuaRuntime
l=LuaRuntime();l.execute('''
function sprite(n)return {getName=function()return n end}end
function getSprite(n)return sprite(n)end
function isServer()return true end
function sendServerCommand()end
function getTimestampMs()return 1000 end;function getTimestamp()return 1 end
r={id='tower',x=0,y=0,releaseTower=1,status='ready',flooring={tiles={}}};state={tower=r}
package.loaded['TSBAstroluxStructure/Records']={all=function()return state.tower and {r}or {}end,state=function()return state end}
package.loaded['TSBAstroluxStructure/ReleaseAccess']={allowed=function()return true end}
local empty={size=function()return 0 end};grid={};originals={}
for x=-1,13 do for y=-1,13 do
 local key=x..':'..y;local name=x%2==0 and 'pavement_original'or 'grass_original';originals[key]=name
 local md={};local o={sp=sprite(name)}
 function o:getModData()return md end;function o:getSprite()return self.sp end;function o:setSprite(s)self.sp=s end
 function o:transmitUpdatedSpriteToClients()end;function o:transmitModData()end
 local sq={o=o,getX=function()return x end,getY=function()return y end,getZ=function()return 0 end,getMovingObjects=function()return empty end,getStaticMovingObjects=function()return empty end,RecalcAllWithNeighbours=function()end,RecalcProperties=function()end,setSquareChanged=function()end}
 function sq:getFloor()return self.o end
 function sq:getObjects()return {size=function()return 1 end,get=function()return o end}end
 grid[key]=sq
 if x>=0 and x<12 and y>=0 and y<12 then
  r.flooring.tiles[#r.flooring.tiles+1]={x=x,y=y,from=name,to='showroom',created=false};md.TSBAstroluxFlooring='tower';o.sp=sprite('showroom')
 end
end end
-- A player replaced one tile after placement; another now belongs elsewhere.
grid['2:2'].o.sp=sprite('player_wood')
grid['3:3'].o:getModData().TSBAstroluxFlooring='other'
function getCell()return {getGridSquare=function(_,x,y,z)if z==0 then return grid[x..':'..y]end end,getVehicles=function()return {iterator=function()return {hasNext=function()return false end}end}end}end
ModData={getOrCreate=function()return {}end}
p={getUsername=function()return 'admin'end,getX=function()return 16 end,getY=function()return 0 end,getZ=function()return 0 end}
''')
l.globals().M=l.execute(Path('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxStructure/ReleaseDelete.lua').read_text(encoding='utf-8'))
l.execute('''
local review=M.review(p,'tower');assert(review);assert(M.execute(p,review.token));assert(not state.tower)
for key,sq in pairs(grid)do
 local expected=key=='2:2'and 'player_wood'or key=='3:3'and 'showroom'or originals[key]
 assert(sq.o:getSprite():getName()==expected,'Terrain mismatch at '..key)
 if key~='2:2'and key~='3:3'then assert(sq.o:getModData().TSBAstroluxFlooring==nil)end
end
''')
print('PASS: real deletion handler restores mixed grass/pavement to original coordinates, retains outside ground, preserves player edits and foreign ownership.')
