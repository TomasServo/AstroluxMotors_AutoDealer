if isClient()then return end
local Plan=require 'TSBAstroluxVend/DeliveryBorderPlan'
-- Keep loaded square wrappers alive until refresh explicitly observes unloading.
local B={tracked={}}
function B.square(db,sq)
 if not sq or sq:getZ()~=0 then return end
 local wanted={};local x,y=sq:getX(),sq:getY()
 for id,t in pairs(db.terminals or {})do
  if t.deliveryBorder==true and not t.packed then local name=Plan.sprite(t.spawnArea,x,y);if name then wanted[id]=name end end
 end
 local found={};local objects=sq:getObjects();local changed=false
 for i=objects:size()-1,0,-1 do
  local obj=objects:get(i);local id=Plan.owner(obj)
  if id~=nil then
   B.tracked[sq]=true
   if wanted[id]==obj:getSprite():getName() and not found[id]then found[id]=true
   else sq:transmitRemoveItemFromSquare(obj);changed=true end
  end
 end
 if sq:getFloor() and sq:TreatAsSolidFloor() and sq:isOutside()then
  for id,name in pairs(wanted)do if not found[id]then
   local sprite=getSprite(name)
   if not sprite or sprite:getName()~=name then error('Native yellow delivery-border sprite unavailable.',0)end
   local obj=IsoObject.new(getCell(),sq,sprite);local md=obj:getModData()
   md.TSBAstroluxDeliveryBorder=id;md.TSBAstroluxDeliveryBorderKind='perimeter'
   local ok,err=pcall(function()sq:AddTileObject(obj);B.tracked[sq]=true;obj:transmitCompleteItemToClients()end)
   if not ok then pcall(function()sq:transmitRemoveItemFromSquare(obj)end);error(err,0)end
   changed=true;found[id]=true
  end end
 end
 if changed then sq:RecalcAllWithNeighbours(true)end
 local hasWanted=false;for _ in pairs(wanted)do hasWanted=true;break end
 if not hasWanted then B.tracked[sq]=nil end
end
function B.refresh(db,regions)
 local cell=getCell();local seen={}
 local function update(sq)
  if sq and not seen[sq]then seen[sq]=true;B.square(db,sq)end
 end
 for sq in pairs(B.tracked)do
  if cell:getGridSquare(sq:getX(),sq:getY(),0)==sq then update(sq)else B.tracked[sq]=nil end
 end
 for _,t in pairs(db.terminals or {})do
  if t.deliveryBorder==true and not t.packed and t.spawnArea then
   Plan.loaded(t.spawnArea,regions,function(x,y)update(cell:getGridSquare(x,y,0))end)
  end
 end
end
function B.safeRefresh(db,regions)
 local ok,err=pcall(B.refresh,db,regions)
 if not ok and tostring(err)~=B.lastError then B.lastError=tostring(err);print('[Astrolux delivery border] '..B.lastError)end
 if ok then B.lastError=nil end
end
Events.LoadGridsquare.Add(function(sq)
 local db=ModData.getOrCreate('TSBAstroluxVend.State.v1')
 local ok,err=pcall(B.square,db,sq)
 if not ok and tostring(err)~=B.lastError then B.lastError=tostring(err);print('[Astrolux delivery border] '..B.lastError)end
end)
return B
