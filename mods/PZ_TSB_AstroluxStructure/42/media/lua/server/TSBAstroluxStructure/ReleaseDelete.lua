-- Use exact-object removal: native default expands multi-tile furniture groups.
-- Explicit, retryable removal of a released tower. Never infer ownership by proximity.
local Records=require 'TSBAstroluxStructure/Records'
local Access=require 'TSBAstroluxStructure/ReleaseAccess'
local M={pending={},serial=0}
local lamps={{3,3},{8,3},{3,8},{8,8},{6,6}}
local function name(o)return o:getSprite() and o:getSprite():getName()end
local function owned(o,r,sq)
 local md=o:getModData();local f=md.movableData and md.movableData.TSBAstroluxFurnishingV1
 local h=md.TSBAstroluxNativeHelperV1
 if md.TSBAstroluxStructure==r.id or (f and f.tower==r.id)or(h and h.owner==r.id)then return true end
 -- Earlier native lights have no owner tag; match their exact original slot and asset.
 if sq:getZ()==0 and not md.TSBAstroluxStructure then
  local key=md.TSBAstroluxCeilingV1
  if key=='switch' and sq:getX()==r.x+9 and sq:getY()==r.y+12 and name(o)=='TSBAstroluxCeilingSwitch_0'then return true end
  for i,p in ipairs(lamps)do if key=='panel'..i and sq:getX()==r.x+p[1]and sq:getY()==r.y+p[2]and name(o)=='TSBAstroluxCeiling_0'then return true end end
 end
 return false
end
local function plan(p,id)
 if not (Access.allowed(p))then return nil,'Administrator access required' end 
 local r;for _,v in ipairs(Records.all())do if v.id==id and v.releaseTower then r=v end end
 if not (r)then return nil,'Select a pasted release tower' end 
 if not (p:getZ()==0 and (p:getX()-r.x)^2+(p:getY()-r.y)^2<=900)then return nil,'Stand within 30 tiles of the tower' end 
 if not (p:getX()<r.x-1 or p:getX()>r.x+14 or p:getY()<r.y-1 or p:getY()>r.y+14)then return nil,'Stand outside the tower footprint' end 
 local out={record=r,objects={},floors={},terminals={}}
 for id in pairs(r.deleteTerminals or {})do out.terminals[id]=true end
 for z=4,0,-1 do for dx=-1,13 do for dy=-1,13 do
  local sq=getCell():getGridSquare(r.x+dx,r.y+dy,z)
  if z==0 then if not (sq)then return nil,'Load the entire tower site before deleting' end end
  if sq then
   if not (sq:getMovingObjects():size()==0 and sq:getStaticMovingObjects():size()==0)then return nil,'Move occupants, bodies & animals out of the tower first' end 
   local list=sq:getObjects()
   for i=0,list:size()-1 do local o=list:get(i)
    if owned(o,r,sq)then
     out.objects[#out.objects+1]={object=o,square=sq}
     local terminal=o:getModData().TSBAstroluxVend;if terminal then out.terminals[terminal]=true end
    elseif z>0 then return nil,'Remove unrelated objects from the upper floors first'end
   end
  end
 end end end
 local vehicles=getCell():getVehicles():iterator()
 while vehicles:hasNext()do local v=vehicles:next()
  if not (v:getX()<r.x-2 or v:getX()>r.x+15 or v:getY()<r.y-2 or v:getY()>r.y+15)then return nil,'Move vehicles clear of the tower first' end 
 end
 for _,t in ipairs(r.flooring and r.flooring.tiles or {})do
  local sq=getCell():getGridSquare(t.x,t.y,0);if not sq then return nil,'Ground unloaded'end;local o=sq:getFloor()
  if o and o:getModData().TSBAstroluxFlooring==r.id then
   if name(o)==t.to then
    if not t.created then local spr=getSprite(t.from);if not (spr and spr:getName()==t.from)then return nil,'Original ground asset unavailable' end end
    out.floors[#out.floors+1]={object=o,square=sq,tile=t}
   end
  end
 end
 local db=ModData.getOrCreate('TSBAstroluxVend.State.v1')
 for _,h in pairs(db.kioskHolds or {})do
  if not (h.x<r.x-1 or h.x>r.x+13 or h.y<r.y-1 or h.y>r.y+13)then return nil,'Resolve held kiosk placement before deleting this tower' end 
 end
 for id,t in pairs(db.terminals or {})do
  if t.x>=r.x and t.x<=r.x+12 and t.y>=r.y and t.y<=r.y+12 then
   if not (out.terminals[id])then return nil,'An unrelated kiosk is inside this tower; move it first' end 
  end
 end
 for _,o in pairs(db.orders or {})do if not (not out.terminals[o.terminal]or o.status=='delivered')then return nil,'Resolve pending purchases before deleting this tower' end end
 for _,o in pairs(db.tradeIns or {})do if not (not out.terminals[o.terminal]or(o.status~='hold'and o.status~='processing'))then return nil,'Resolve held trade-ins before deleting this tower' end end
 return out
end
function M.review(p,id)
 local a,why=plan(p,id);if not a then return nil,why end;M.serial=M.serial+1
 local token=tostring(getTimestampMs())..':'..M.serial
 M.pending[tostring(p:getUsername())]={token=token,id=id,expires=getTimestampMs()+60000}
 return {token=token,x=a.record.x,y=a.record.y,count=#a.objects}
end
function M.execute(p,token)
 local actor=tostring(p:getUsername());local q=M.pending[actor]
 if not(q and q.token==token and getTimestampMs()<=q.expires)then return nil,'Deletion confirmation expired; select the tower again'end
 M.pending[actor]=nil
 local a,why=plan(p,q.id);if not a then return nil,why end;local r=a.record
 r.status='deleting';r.deleteTerminals=a.terminals
 local function remove(o,sq)
  sq:transmitRemoveItemFromSquare(o,false)
  assert(o:getObjectIndex()<0,'Object removal failed; use Delete Tower again to resume')
  sq:RecalcAllWithNeighbours(true)
 end
 for _,v in ipairs(a.objects)do remove(v.object,v.square)end
 for _,v in ipairs(a.floors)do
  if v.tile.created then remove(v.object,v.square)
  else
   v.object:setSprite(getSprite(v.tile.from));v.object:getModData().TSBAstroluxFlooring=v.tile.owner
   v.object:transmitUpdatedSpriteToClients();v.object:transmitModData();v.square:RecalcAllWithNeighbours(true)
   v.square:RecalcProperties();v.square:setSquareChanged()
   if not isServer()then v.object:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)end
  end
 end
 local db=ModData.getOrCreate('TSBAstroluxVend.State.v1')
 for id in pairs(a.terminals)do if db.terminals then db.terminals[id]=nil end end
 pcall(function()require('TSBAstroluxVend/DeliveryBorder').safeRefresh(db,require('TSBAstroluxVend/VehicleSpawn').regions())end)
 -- Do not claim completion while an owned object remains on the server.
 local remaining=0
 for z=0,4 do for dx=-1,13 do for dy=-1,13 do
  local sq=getCell():getGridSquare(r.x+dx,r.y+dy,z)
  if sq then local list=sq:getObjects();for i=0,list:size()-1 do
   if owned(list:get(i),r,sq)then remaining=remaining+1 end
  end end
 end end end
 print('[Astrolux delete audit] '..r.id..' remaining server objects='..remaining)
 assert(remaining==0,'Owned objects remain; use Delete Tower again to resume')
 if isServer()then
  local floors={}
  for _,v in ipairs(a.floors)do
   local t=v.tile
   floors[#floors+1]={x=t.x,y=t.y,from=t.from,to=t.to,owner=t.owner,created=t.created}
  end
  sendServerCommand('TSBAstroluxRelease','deletedSite',{id=r.id,x=r.x,y=r.y,floors=floors})
 end
 local state=Records.state();if state.tower==r then state.tower=nil end
 if state.showrooms then state.showrooms[r.id]=nil end
 for _,e in pairs(ModData.getOrCreate('TSBAstroluxReleasePlacements.v1'))do if e.id==r.id then e.status='cleared';e.deletedBy=actor;e.deletedAt=getTimestamp()end end
 return 'Tower deleted. Original ground restored where unchanged; unrelated ground objects retained.'
end
return M
