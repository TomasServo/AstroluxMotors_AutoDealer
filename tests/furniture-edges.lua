function isClient()return false end
function isServer()return false end
function instanceof(o,c)return o.class==c end
IsoFlagType={collideN='N',collideW='W'}
local function list()
 local a={};function a:size()return #self end;function a:get(i)return self[i+1]end;return a
end
function getSprite(n)
 return {getName=function()return n end,getProperties=function()return {has=function(_,f)
  return (n=='TSBAstroluxBayCollision_0' and f=='N') or (n=='TSBAstroluxBayCollision_1' and f=='W')
 end}end}
end
local function object(sq,sprite,class,owner)
 local o={sq=sq,sp=getSprite(sprite),class=class,md={}}
 if owner then o.md.movableData={TSBAstroluxFurnishingV1={tower=owner}} end
 function o:getModData()return self.md end
 function o:getSprite()return self.sp end
 function o:setDoRender(v)self.render=v end
 return o
end
IsoObject={new=function(_,sq,sp)local o=object(sq,'unused');o.sp=sp;return o end}
local grid={};local added,removed=0,0
for x=0,13 do for y=0,13 do
 local sq={objects=list(),moving=list(),static=list()}
 function sq:getObjects()return self.objects end
 function sq:getMovingObjects()return self.moving end
 function sq:getStaticMovingObjects()return self.static end
 function sq:AddTileObject(o)table.insert(self.objects,o);added=added+1 end
 function sq:transmitRemoveItemFromSquare(o,expand)
  assert(expand==false,'Never expand a deletion to adjacent furniture')
  for i,v in ipairs(self.objects)do if v==o then table.remove(self.objects,i);removed=removed+1;return end end
 end
 function sq:RecalcProperties()end
 function sq:RecalcAllWithNeighbours()end
 function sq:setSquareChanged()end
 grid[x..':'..y]=sq
end end
function getCell()return {getGridSquare=function(_,x,y)return grid[x..':'..y]end}end
local E=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxStructure/FurnitureEdges.lua')
local s={recordId='tower',x=0,y=0};local a=grid['3:0']
local kiosk=object(a,'TSBAstroluxKiosk_0','IsoThumpable','tower')
a.objects[1]=kiosk;a.objects[2]=object(a,'glass','IsoWindow')
assert(E.sync(s));assert(added==4,'Windows must not bypass the four furniture edges')
E.sync(s);assert(added==4 and removed==0,'Repeated reconciliation is idempotent')
local axes={}
for key,sq in pairs(grid)do for _,o in ipairs(sq.objects)do if o.md[E.tag]then
 assert(o.md[E.tag].owner=='tower' and not o.render)
 axes[key..':'..o.sp:getName()]=true
end end end
assert(axes['3:0:TSBAstroluxBayCollision_0'] and axes['3:0:TSBAstroluxBayCollision_1'])
assert(axes['3:1:TSBAstroluxBayCollision_0'] and axes['4:0:TSBAstroluxBayCollision_1'])
table.remove(a.objects,1);E.sync(s);assert(removed==4,'Moving furniture removes all its edges')
a.objects[1]=kiosk;a.moving[1]={};E.sync(s);assert(added==4,'Do not enclose an occupant')
a.moving[1]=nil;E.sync(s);assert(added==8,'Retry after occupant leaves')
local missing=grid['13:13'];grid['13:13']=nil
table.remove(a.objects,1);assert(not E.sync(s));assert(removed==4,'Unloaded site cannot trigger pruning')
grid['13:13']=missing;E.sync(s);assert(removed==8)
a.objects[1]=object(a,'TSBAstroluxKiosk_0','IsoThumpable','foreign');E.sync(s);assert(added==8)
a.objects[1]=kiosk;a.objects[2]=object(a,'door','IsoDoor');E.sync(s);assert(added==8,'Keep doorway clear')
a.objects[2]=nil;a.objects[1]=object(a,'furniture_tables_low_01_0','IsoThumpable','tower')
E.sync(s);assert(added==8,'Retain approved low-table exception')
a.objects[1]=object(a,'mannequin','IsoMannequin','tower')
E.sync(s);assert(added==8,'Do not wall off native mannequin inventory')
local counter=object(a,'fixtures_counters_01_57','IsoThumpable','tower')
function counter:getContainerCount()return 1 end
a.objects[1]=counter;E.sync(s);assert(added==8,'Native container access must remain reachable')
a.objects[1]=kiosk;E.sync(s);assert(added==12)
a.objects[1]=counter;E.sync(s);assert(removed==12,'Existing container boundaries are removed on reconciliation')
print('PASS: furniture boundaries, ownership, occupancy, reload, movement and doorway cleanup')

local support=object(a,'furniture_tables_high_01_16','IsoThumpable','tower')
a.objects[1]=support;E.sync(s);local before=removed
local lamp=object(a,'lighting_indoor_02_33','IsoLightSwitch','tower')
function lamp:getCanBeModified()return true end
table.insert(a.objects,lamp);E.sync(s)
assert(removed==before+4,'Remove existing supporting-table edges so native lamp interaction is reachable')
local oldAdded=added;E.sync(s);assert(added==oldAdded,'Lamp access remains open after repeated reconciliation')
assert(a.objects[1]==support and a.objects[2]==lamp,'Keep original lamp and table')
print('PASS: tabletop lamp access removes existing helper barriers without replacing fixtures')
