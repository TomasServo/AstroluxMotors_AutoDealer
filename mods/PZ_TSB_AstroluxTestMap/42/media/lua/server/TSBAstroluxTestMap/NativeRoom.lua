-- Fixed native map room for the already-placed bundled demonstration building.
require 'TSBAstroluxTestMap/Config'
local W=require 'AstroluxBayTest/TestWorld'
local R=require 'TSBAstroluxStructure/Records'
local M={};local ticks=0;local message
local function record()
 if not W.freshLot()then return nil end
 for _,r in ipairs(R.all())do
  if r.x==120 and r.y==135 and r.combinedSize==12 and r.status=='ready'then return r end
 end
end
local function report(text)
 if text~=message then print('[Astrolux Native Room] '..text);message=text end
end
function M.square(sq)
 local r=record()
 if not r or not sq or sq:getZ()~=0 then return false end
 local x,y=sq:getX(),sq:getY()
 if x<120 or x>=132 or y<135 or y>=147 then return false end
 local floor=sq:getFloor()
 if not floor or floor:getModData().TSBAstroluxFlooring~=r.id then return false end
 local def=getWorld():getMetaGrid():getRoomAt(x,y,0)
 if not def or def:getName()~='astroluxshowroom' then return false end
 if sq:getRoomID()~=-1 and sq:getRoomID()~=def:getID()then return false end
 if not sq:getRoom()then
  sq:setRoomID(def:getID())
  local room=sq:getRoom();if not room then return false end
  room:addSquare(sq);sq:RecalcAllWithNeighbours(true)
 end
 return sq:getRoomID()==def:getID()and sq:getRoom()~=nil and sq:getBuilding()~=nil
end
function M.update()
 if not record()then M.ready=false;return false end
 local cell=getCell();if not cell then M.ready=false;return false end
 local count=0
 for x=120,131 do for y=135,146 do
  local sq=cell:getGridSquare(x,y,0)
  if M.square(sq)and sq:hasGridPower()then count=count+1 end
 end end
 M.ready=count==144
 if M.ready then report('144 showroom squares linked to native map building; municipal grid power available.')
 else report('Waiting for native room/grid association: '..count..'/144 squares.')end
 return M.ready
end
Events.LoadGridsquare.Add(M.square)
Events.OnGameStart.Add(M.update)
Events.OnTick.Add(function()ticks=ticks+1;if ticks%60==0 then M.update()end end)
return M
