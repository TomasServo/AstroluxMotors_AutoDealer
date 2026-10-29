-- One-time repair after disabling the legacy eight-tile opening conversion.
if isClient() or isServer() then return end
local M={};local ticks=0
function M.run()
 if not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxCombined12.v1')
 if not s or not s.ready or (s.northWestGlassRepair or 0)>=2 then return end
 local pending={}
 for _,v in ipairs({{3,0,true},{4,0,true},{0,3,false},{0,4,false}})do
  local sq=getCell():getGridSquare(s.x+v[1],s.y+v[2],0);if not sq then return end
  local exists=false;local list=sq:getObjects()
  for i=0,list:size()-1 do local o=list:get(i)
   if (instanceof(o,'IsoWindow') or instanceof(o,'IsoDoor')) and o:getNorth()==v[3] then exists=true end
  end
  if not exists then
   local name='TSBAstroluxClearGlass_'..(v[3] and 1 or 0);local sprite=getSprite(name)
   if not sprite or sprite:getName()~=name then return end
   pending[#pending+1]={sq=sq,sprite=sprite,north=v[3]}
  end
 end
 for _,v in ipairs(pending)do
  local o=IsoWindow.new(getCell(),v.sq,v.sprite,v.north);o:setPermaLocked(true)
  o:getModData().TSBAstroluxStructure=s.recordId;o:getModData().TSBAstroluxStructureKind='window'
  v.sq:AddSpecialObject(o);v.sq:RecalcAllWithNeighbours(true);v.sq:setSquareChanged()
 end
 s.northWestGlassRepair=2
 print('[Astrolux Glass Repair] Restored '..#pending..' missing north/west panes; existing windows and door openings retained.')
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%60==0 then M.run()end end)
return M
