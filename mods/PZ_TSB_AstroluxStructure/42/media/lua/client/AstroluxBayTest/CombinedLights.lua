local Electricity=require 'TSBAstroluxStructure/Electricity'
-- Transient native light sources for this single-player test save only.
local M={brightness=0};local current=nil;local sources={};local owner=nil;local site=nil;local ticks=0;local failed=false
local function clear()
 if owner then for _,source in ipairs(sources) do owner:removeLamppost(source) end end
 sources={};owner=nil;site=nil;current=nil;M.brightness=0
end
function M.intensity(daylight)
 local d=1-math.max(0,math.min(1,daylight))
 return 0.15+0.85*d*d*(3-2*d)
end
function M.update()
 local s
 if not isClient() and not isServer() and getNumActivePlayers()==1 and getWorld() and require('AstroluxBayTest/TestWorld').enabled() then
  s=ModData.get('TSBAstroluxCombined12.v1')
 end
 if not s or not s.ready or not s.x or not s.y then clear();return end
 local cell=getCell();if not cell then clear();return end
 if not Electricity.showroom(s) then clear();return end
 local key=s.x..':'..s.y
 -- Wait for both platforms to be loaded; remove our lights on streaming out.
 for _,p in ipairs({{4,10},{7,10},{10,4},{10,7},{4,1},{7,1},{1,4},{1,7}}) do local x,y=p[1],p[2]
  if not cell:getGridSquare(s.x+x,s.y+y,1) then clear();return end
 end
 local target=M.intensity(getClimateManager():getDayLightStrength())
 if owner==cell and site==key and #sources==8 then
  current=current+math.max(-0.015,math.min(0.015,target-current));M.brightness=current
  for _,source in ipairs(sources) do source:setR(0.45*current);source:setG(0.4725*current);source:setB(0.495*current) end
  return
 end
 clear();owner=cell;site=key;current=target;M.brightness=current
 for _,p in ipairs({{4,10},{7,10},{10,4},{10,7},{4,1},{7,1},{1,4},{1,7}}) do local x,y=p[1],p[2]
  local source=cell:addLamppost(s.x+x,s.y+y,1,0.45*current,0.4725*current,0.495*current,3)
  assert(source,'Native bay light creation failed')
  sources[#sources+1]=source
 end
 print('[Astrolux Combined Lights] Eight local cool-white test lights active; actual showroom power required.')
end
function M.refresh()
 if failed then return end
 local ok,why=pcall(M.update)
 if not ok then failed=true;pcall(clear);print('[Astrolux Combined Lights] Disabled: '..tostring(why)) end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%15==0 then M.refresh() end end)
return M

