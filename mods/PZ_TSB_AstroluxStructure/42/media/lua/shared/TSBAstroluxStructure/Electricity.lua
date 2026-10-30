-- Shared square rule used by kiosk sales and showroom ambience.
local E={}
function E.square(sq)
 if not sq then return false end
 -- Generator range, running state and sandbox rules remain native.
 if sq:haveElectricity()then return true end
 local grid=sq:hasGridPower()
 if grid and sq:getRoom()~=nil then return true end
 -- Pasted showrooms have no compiled map room. Only owned tiles belonging
 -- to a live, ready release tower may consume active grid power here.
 local floor=sq:getFloor();local owner=floor and floor:getModData().TSBAstroluxFlooring
 if not owner or sq:getZ()~=0 then return false end
 for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
  -- The optional SP test-map placement tool creates a combined lab record.
  -- It has the same owned floor but deliberately is not a release tower.
  local eligible=r.releaseTower or (r.combinedSize==12
   and require('AstroluxBayTest/TestWorld').testMap())
  if r.id==owner and eligible and r.status=='ready'
   and sq:getX()>=r.x and sq:getX()<r.x+12 and sq:getY()>=r.y and sq:getY()<r.y+12 then
   if grid then return true end
   -- Native user-built rooms reject grid power even before the blackout.
   -- Keep the installed dealer connected only while its exterior grid is live.
   if not sq:isUserDefinedRoom() or sq:isDerelict() then return false end
   local cell=getCell();if not cell then return false end
   for n=0,11 do
    for _,v in ipairs({{r.x-1,r.y+n},{r.x+12,r.y+n},{r.x+n,r.y-1},{r.x+n,r.y+12}})do
     local outside=cell:getGridSquare(v[1],v[2],0)
     if outside and not outside:isInARoom() and outside:hasGridPower()then return true end
    end
   end
   return false
  end
 end
 return false
end
function E.showroom(r)
 local cell=getCell()
 if not cell or not r or not r.x or not r.y then return false end
 local size=r.combinedSize or 8
 for x=r.x,r.x+size-1 do for y=r.y,r.y+size-1 do
  if E.square(cell:getGridSquare(x,y,0)) then return true end
 end end
 return false
end
-- Retire legacy test battery mode once. Keep actual battery, charge and bulb.
function E.retireTestBattery(o,tagged)
 if not tagged then return false end
 local md=o:getModData()
 if md.TSBAstroluxMainsMigrationV1 then return false end
 o:setUseBatteryDirect(false)
 md.TSBAstroluxMainsMigrationV1=true
 o:transmitModData()
 return true
end
return E
