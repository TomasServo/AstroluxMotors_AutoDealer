local base='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
assert(loadfile(base..'client/TSBAstroluxVend/TabsUI.lua'))
local A=dofile(base..'shared/TSBAstroluxVend/SpawnAreas.lua');package.loaded['TSBAstroluxVend/SpawnAreas']=A
local script={getModel=function()return {}end,getExtents=function()return {x=function()return 2 end,z=function()return 6 end}end,getCenterOfMassOffset=function()return {x=function()return .3 end,z=function()return .6 end}end}
assert(#A.directions==8 and #A.labels==8)
for i,direction in ipairs(A.directions)do
 assert(A.labels[i]:find('('..direction..')',1,true))
 local a=assert(A.rectangle(0,0,20,20,direction));assert(a.heading==direction)
 local rx,ry=A.dimensions(script,direction);local dx,dy=A.vectors[direction][1],A.vectors[direction][2]
 assert(math.abs(dx*dx+dy*dy-1)<.000001,'unit direction arrow')
 local angle=(i-1)*math.pi/4;local bx,by=A.dimensions(script,'N')
 for _,x in ipairs({-bx,bx})do for _,y in ipairs({-by,by})do
  local px=x*math.cos(angle)-y*math.sin(angle);local py=x*math.sin(angle)+y*math.cos(angle)
  assert(math.abs(px)<=rx+.000001 and math.abs(py)<=ry+.000001,'rotated padded corner fits envelope')
 end end
 local mx,my=A.measure(script,direction)
 local p=assert(A.find(a,mx,my,{{x1=0,y1=0,x2=20,y2=20}},function()return true end));assert(A.contains(a,p))
end
assert(not A.rectangle(0,0,10,10,'NNW'))
local thin=assert(A.rectangle(0,0,4,8,'N'));local rx,ry=A.measure(script,'N');assert(A.find(thin,rx,ry,{{x1=0,y1=0,x2=4,y2=8}},function()return true end))
thin.heading='NE';rx,ry=A.measure(script,'NE');assert(not A.find(thin,rx,ry,{{x1=0,y1=0,x2=4,y2=8}},function()return true end),'diagonal cannot use unrotated narrow footprint')
for _,name in ipairs({'ISUI/ISPanel','ISUI/ISModalRichText'})do package.preload[name]=function()return {}end end
ISPanel={derive=function()return {}end};Events={OnKeyPressed={Add=function()end}};UIFont={Small=1}
function getPlayerScreenLeft()return 0 end;function getPlayerScreenTop()return 0 end
function isoToScreenX(_,x)return x end;function isoToScreenY(_,x,y)return y end
local Cursor=dofile(base..'client/TSBAstroluxVend/AreaCursor.lua')
for _,d in ipairs(A.directions)do
 local lines={};local cursor={player=0,drawText=function()end,drawLine=function(_,texture,x1,y1,x2,y2)lines[#lines+1]={x2-x1,y2-y1}end}
 Cursor.drawFacingArrow(cursor,{x1=0,y1=0,x2=20,y2=20,heading=d});assert(#lines==3)
 local v=A.vectors[d];assert(math.abs(lines[1][1]-6*v[1])<.000001 and math.abs(lines[1][2]-6*v[2])<.000001,'arrow points in selected direction')
end
function isClient()return false end;function isServer()return false end
package.loaded['TSBAstroluxVend/DeliveryBorderPlan']={}
package.loaded['TSBAstroluxVend/Delivery']={restore=function()end}
package.loaded['TSBAstroluxVend/Accessories']={verify=function()end}
package.loaded['TSBAstroluxVend/Equipment']={selection=function()end}
package.loaded['TSBAstroluxVend/Paint']={verify=function()end,apply=function()end}
package.loaded['TSBAstroluxVend/CamperCapacity']={update=function()end}
package.loaded['TSBAstroluxVend/SpawnDefaults']={create=function(_,fn)return fn()end}
function getScriptManager()return {getVehicle=function()return script end}end
local selected,vehicle
function getCell()return {getGridSquare=function()return {}end}end
IsoDirections={};for i,d in ipairs(A.directions)do local angle=(i-1)*math.pi/4;IsoDirections[d]={toAngle=function()return angle end}end
function addVehicleDebug(_,dir)
 assert(dir==selected);vehicle={md={}}
 function vehicle:getId()return 12 end;function vehicle:getModData()return self.md end;function vehicle:transmitModData()end;function vehicle:getSquare()return {}end
 function vehicle:setDir(dir)assert(dir==selected)end;function vehicle:setAngles(_,yaw)self.yaw=yaw end
 function vehicle:getPartCount()return 0 end;function vehicle:getPartById()end;function vehicle:createVehicleKey()return {}end
 return vehicle
end
local Spawn=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxVend/VehicleSpawn.lua')
local player={getInventory=function()return {AddItem=function(_,item)return item end}end}
for _,d in ipairs(A.directions)do
 selected=IsoDirections[d];local order={id=d,script='Test.Car',placement={x=5,y=5,heading=d}}
 Spawn.create(order,player);assert(math.abs(vehicle.yaw-(math.deg(selected:toAngle())+180)%360)<.000001 and order.keyIssued and order.vehicleId==12)
end
print('PASS eight headings: selection/validation, cardinal compatibility, rotated clearance and fit, normalized arrows, exact native enum/angle routing, vehicle identity and key issuance')
