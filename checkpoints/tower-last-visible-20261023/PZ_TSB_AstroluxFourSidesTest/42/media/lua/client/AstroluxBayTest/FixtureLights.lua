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
 if not isClient() and not isServer() and getNumActivePlayers()==1 and getWorld() and tostring(getWorld():getWorld())=='AstroluxStructureLab_12x12_FourSides' then
  s=ModData.get('TSBAstroluxBayTest.v1')
 end
 if not s or s.stackRevision~=1 or not s.siteX or not s.siteY or s.fixtureLights==false or s.bayDetails==false or s.platformStyleTest==false or not s.layerVisible or not s.layerVisible.Frame then clear();return end
 local cell=getCell();if not cell then clear();return end
 local key=s.siteX..':'..s.siteY
 -- Wait for both platforms to be loaded; remove our lights on streaming out.
 for z=0,1 do for _,x in ipairs({1,4}) do
  if not cell:getGridSquare(s.siteX+x,s.siteY+1,z) then clear();return end
 end end
 local target=M.intensity(getClimateManager():getDayLightStrength())
 if owner==cell and site==key and #sources==4 then
  current=current+math.max(-0.015,math.min(0.015,target-current));M.brightness=current
  for _,source in ipairs(sources) do source:setR(0.30*current);source:setG(0.315*current);source:setB(0.33*current) end
  return
 end
 clear();owner=cell;site=key;current=target;M.brightness=current
 for z=0,1 do for _,x in ipairs({1,4}) do
  local source=cell:addLamppost(s.siteX+x,s.siteY+1,z,0.30*current,0.315*current,0.33*current,3)
  assert(source,'Native bay light creation failed')
  sources[#sources+1]=source
 end end
 print('[Astrolux Bay Lights] Four local cool-white test lights active; power simulation deferred.')
end
function M.refresh()
 if failed then return end
 local ok,why=pcall(M.update)
 if not ok then failed=true;pcall(clear);print('[Astrolux Bay Lights] Disabled: '..tostring(why)) end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%15==0 then M.refresh() end end)
return M
