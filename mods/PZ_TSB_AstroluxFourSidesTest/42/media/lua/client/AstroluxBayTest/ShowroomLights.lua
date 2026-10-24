-- Decorative ceiling fixtures with native local light sources and a separate switch.
local M={};local owner=nil;local key=nil;local sources={};local ticks=0;local failed=false
local positions={{3,3},{8,3},{3,8},{8,8}}
local function state()
 if isClient() or isServer() or getNumActivePlayers()~=1 or not getWorld()
 or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxCombined12.v1')
 if s and s.ready and s.x and s.y then return s end
end
local function clear()
 if owner then for _,source in ipairs(sources)do owner:removeLamppost(source)end end
 owner=nil;key=nil;sources={}
end
function M.update()
 local s=state();local cell=getCell()
 if not s or not cell or s.showroomLights==false then clear();return end
 for _,p in ipairs(positions)do if not cell:getGridSquare(s.x+p[1],s.y+p[2],0) then clear();return end end
 local site=s.x..':'..s.y
 if owner==cell and key==site and #sources==4 then return end
 clear();owner=cell;key=site
 for _,p in ipairs(positions)do
  local light=cell:addLamppost(s.x+p[1],s.y+p[2],0,.48,.50,.52,5)
  assert(light,'Showroom light creation failed');sources[#sources+1]=light
 end
end
function M.toggle()
 local s=state();if not s then return end
 s.showroomLights=s.showroomLights==false
 M.refresh()
end
function M.refresh()
 if failed then return end
 local ok,err=pcall(M.update)
 if not ok then failed=true;pcall(clear);print('[Astrolux Showroom Lights] Disabled: '..tostring(err))end
end
function M.draw(panel)
 local s=state();local player=getSpecificPlayer(0)
 if not s or not player or player:getZ()~=0 or not getCell():getGridSquare(s.x+6,s.y+6,0) then return end
 local zoom=getCore():getZoom(0);local on=s.showroomLights~=false
 local function point(x,y,z)
  return (IsoUtils.XToScreen(s.x+x,s.y+y,z,0)-IsoCamera.getOffX(0))/zoom,
   (IsoUtils.YToScreen(s.x+x,s.y+y,z,0)-IsoCamera.getOffY(0))/zoom
 end
 local function strip(x1,y1,x2,y2,z,width,r,g,b)
  local ax,ay=point(x1,y1,z);local bx,by=point(x2,y2,z)
  local dx,dy=bx-ax,by-ay;local len=math.sqrt(dx*dx+dy*dy);if len==0 then return end
  local nx,ny=-dy/len*width/zoom/2,dx/len*width/zoom/2
  panel:drawPolygon(nil,ax+nx,ay+ny,bx+nx,by+ny,bx-nx,by-ny,ax-nx,ay-ny,r,g,b,1)
 end
 for _,p in ipairs(positions)do
  strip(p[1]-.8,p[2],p[1]+.8,p[2],.94,9,.20,.23,.25)
  local glow=on and 1 or .24
  strip(p[1]-.72,p[2],p[1]+.72,p[2],.94,5,.86*glow,.91*glow,.94*glow)
 end
 -- Rocker plate two tiles beyond the old location, clear of the south sliding leaf.
 local function plate(x0,x1,z0,z1,r,g,b)
  local ax,ay=point(x0,12.01,z0);local bx,by=point(x1,12.01,z0)
  local cx,cy=point(x1,12.01,z1);local dx,dy=point(x0,12.01,z1)
  panel:drawPolygon(nil,ax,ay,bx,by,cx,cy,dx,dy,r,g,b,1)
 end
 plate(9.10,9.32,.39,.54,.24,.27,.29)
 plate(9.15,9.27,.42,.51,.65,.68,.70)
 if on then plate(9.17,9.25,.49,.505,.10,.65,.80)end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%15==0 then M.refresh()end end)
Events.OnFillWorldObjectContextMenu.Add(function(playerIndex,context,objects,test)
 local s=state();local p=getSpecificPlayer(playerIndex)
 if not s or not p or p:getZ()~=0 then return end
 local dx,dy=p:getX()-(s.x+9.2),p:getY()-(s.y+12)
 if dx*dx+dy*dy>9 then return end
 if test then return ISWorldObjectContextMenu.setTest()end
 context:addOption(s.showroomLights==false and 'Switch Showroom Ceiling Lights On' or 'Switch Showroom Ceiling Lights Off',nil,M.toggle)
end)
-- The drawn rocker is not an IsoLightSwitch: give it an explicit click target.
function M.click(mx,my)
 local s=state();local player=getSpecificPlayer(0)
 if not s or not player or player:getZ()~=0 then return end
 local dx,dy=player:getX()-(s.x+9.2),player:getY()-(s.y+12)
 if dx*dx+dy*dy>9 then return end
 local zoom=getCore():getZoom(0)
 local x=(IsoUtils.XToScreen(s.x+9.21,s.y+12.01,.465,0)-IsoCamera.getOffX(0))/zoom
 local y=(IsoUtils.YToScreen(s.x+9.21,s.y+12.01,.465,0)-IsoCamera.getOffY(0))/zoom
 if math.abs(mx-x)<=math.max(8,10/zoom) and math.abs(my-y)<=math.max(12,18/zoom) then M.toggle();return true end
end
Events.OnMouseDown.Add(M.click)
return M
