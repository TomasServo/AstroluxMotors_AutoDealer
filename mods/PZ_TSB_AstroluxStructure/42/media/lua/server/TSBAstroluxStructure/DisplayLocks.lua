if isClient()then return end
local M={key='TSBAstroluxDisplayOutfitLocked'}
function M.set(r,enabled)
 assert(type(enabled)=='boolean','Choose an on/off value')
 local displays={}
 for dx=0,12 do for dy=0,12 do
  local sq=assert(getCell():getGridSquare(r.x+dx,r.y+dy,0),'Load the whole showroom before changing its displays.')
  local objects=sq:getObjects()
  for i=0,objects:size()-1 do
   local o=objects:get(i);local md=o:getModData()
   local f=md.movableData and md.movableData.TSBAstroluxFurnishingV1
   if instanceof(o,'IsoMannequin')and f and f.tower==r.id then displays[#displays+1]=o end
  end
 end end
 assert(#displays>0,'No owned showroom mannequins found.')
 for _,o in ipairs(displays)do o:getModData()[M.key]=enabled or nil;o:transmitModData()end
 r.displayOutfitsLocked=enabled
 return #displays
end
return M
