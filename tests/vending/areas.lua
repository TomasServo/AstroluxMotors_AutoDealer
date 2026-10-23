package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local A=require 'TSBAstroluxVend/SpawnAreas'
local area=assert(A.rectangle(1000000,2000000,-50000,-60000,'W'))
assert(area.x1==-50000 and area.y2==2000000 and area.heading=='W')
assert(A.rectangle(1,1,1,1,'N'),'Single-tile configuration is permitted')
assert(not A.rectangle(1.2,1,3,4,'N'));assert(not A.rectangle(0/0,1,3,4,'N'))
assert(A.rectangle(1,1,3,4,'NW'));assert(not A.rectangle(1,1,3,4,'NNW'))
local function script(x,z)
    return {getModel=function() return {} end,getExtents=function() return {x=function() return x end,z=function() return z end} end,
        getCenterOfMassOffset=function() return {x=function() return 0 end,z=function() return 0 end} end}
end
local rx,ry=A.measure(script(2,4),'N');assert(rx==1 and ry==2)
rx,ry=A.measure(script(2,4),'E');assert(rx==2 and ry==1)
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
    assert(A.contains(grid,q));return false
end)
assert(not point)
local first=assert(A.reserve(area,2,3,{}))
local second=assert(A.reserve(area,2,3,{first}))
assert(not A.overlap(first,second) and A.contains(area,second))
assert(not A.reserve(small,2,3,{}))
local full={x=15,y=15,rx=15,ry=15}
assert(not A.reserve(grid,2,3,{full}),'Fully reserved area cannot sell another space')

print('PASS: unrestricted remote rectangles and reservation geometry')

