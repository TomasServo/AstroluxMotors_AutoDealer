local roofCap=require 'AstroluxBayTest/RoofCap'
local roofRim=require 'AstroluxBayTest/RoofRimOverlay'
local serviceCore=require 'AstroluxBayTest/ServiceCore'
local glassMask=require 'AstroluxBayTest/GlassMask'
local fixtureLights=require 'AstroluxBayTest/FixtureLights'
local combinedLights=require 'AstroluxBayTest/CombinedLights'
local metalPlatform=require 'AstroluxBayTest/MetalPlatform'
local railMask=require 'AstroluxBayTest/RailMask'
local frameSegments=require 'AstroluxBayTest/FrameOcclusion'
local cutaway=require 'AstroluxBayTest/StackCutaway'
require 'ISUI/ISUIElement'
local Glass=ISUIElement:derive('AstroluxTestGlassOverlay')
local panel=nil;local ticks=0
local function state()
 if isClient() or isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' or getNumActivePlayers()~=1 then return nil end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 if s and s.layerRevision==1 and s.nativeFloorRevision==1 and s.siteX and s.siteY then return s end
end
function Glass:onMouseDown()return false end
function Glass:onMouseUp()return false end
function Glass:onRightMouseDown()return false end
function Glass:onRightMouseUp()return false end
function Glass:onMouseMove()return false end
function Glass:onMouseWheel()return false end
function Glass:drawPanes(s)
 local cutaway=s.previewBay and {ready=true,contents=true,outline=true,visible={[0]=false,[1]=true}} or cutaway
 local player=getSpecificPlayer(0)
 if not player or player:getZ()~=0 or not s.layerVisible or not s.layerVisible.Frame then return end
 local zoom=getCore():getZoom(0)
 local function worldPoint(x,y,z)
  return (IsoUtils.XToScreen(s.siteX+x,s.siteY+y,z,0)-IsoCamera.getOffX(0))/zoom,
         (IsoUtils.YToScreen(s.siteX+x,s.siteY+y,z,0)-IsoCamera.getOffY(0))/zoom
 end
 local function point(x,y,z)
  if s.rotated then x,y=3-y,x end
  return worldPoint(x,y,z+(s.levelOffset or 0))
 end
 -- Reflect only the east bay structure across the showroom diagonal.
 -- Keep the vehicle raster and wheel/platform geometry on their accepted rotation.
 local function detailPoint(x,y,z)
  if s.northStructure then return worldPoint(x,3-y,z+(s.levelOffset or 0)) end
  if s.previewBay and s.rotated and not s.westStructure then return worldPoint(y,x,z+(s.levelOffset or 0)) end
  return point(x,y,z)
 end
 local px,py=worldPoint(player:getX()-s.siteX,player:getY()-s.siteY,player:getZ())
 local function glass(x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,alpha,playerInFront)
  local polygon={{x1,y1},{x2,y2},{x3,y3},{x4,y4}}
  -- Keep glass continuous when the player is behind this pane. The UI pass
  -- otherwise punches its standing-body mask through every level and face.
  local pieces=playerInFront and glassMask.outside(polygon,px,py-62/zoom,25/zoom,69/zoom) or {polygon}
  for _,shape in ipairs(pieces) do for i=2,#shape-1 do
   local a,c,d=shape[1],shape[i],shape[i+1]
   self:drawPolygon(nil,a[1],a[2],c[1],c[2],d[1],d[2],d[1],d[2],r,g,b,alpha)
  end end
 end
 local function pane(a,b,low,high,alpha,r,g,blue)
  local x1,y1=point(a[1],a[2],low);local x2,y2=point(b[1],b[2],low)
  local x3,y3=point(b[1],b[2],high);local x4,y4=point(a[1],a[2],high)
  -- Camera-facing depth increases along both world axes. Only ground-level
  -- panes behind the player need foreground-character protection.
  local front=false
  if low<1 then
   if a[1]==b[1] then front=player:getX()-s.siteX>a[1]
   else front=player:getY()-s.siteY>a[2] end
  end
  glass(x1,y1,x2,y2,x3,y3,x4,y4,r,g,blue,alpha,front)
 end
 -- Draw the upper platform and unchanged car artwork before glass and rails.
 if s.stackRevision==1 and cutaway.ready and cutaway.contents and cutaway.visible[1] then
  local texture=getTexture(s.previewTexture or 'media/textures/AstroluxBayBlueSedan.png')
  assert(texture,'Upper vehicle fallback texture missing')
  local sq=getCell():getGridSquare(s.siteX+3,s.siteY+1,1)
  local light=sq and math.max(0,math.min(1,sq:getLightLevel(0))) or 1
  local function floorQuad(x,y)
   local a,b=point(x,y,1);local c,d=point(x+1,y,1)
   local e,f=point(x+1,y+1,1);local g,h=point(x,y+1,1)
   self:drawPolygon(nil,a,b,c,d,e,f,g,h,0.49*light,0.50*light,0.51*light,1)
  end
  if s.platformStyleTest~=false then
   if s.bayDetails~=false then metalPlatform.drawDetails(self,detailPoint,light,s.fixtureLights~=false,(s.previewBay and combinedLights.brightness or fixtureLights.brightness),s.previewBay,s.noGlassRoof) end
   metalPlatform.draw(self,point,light)
  else
  for x=0,5 do for y=0,2 do floorQuad(x,y) end end
  local function seam(x1,y1,x2,y2)
   local a,b=point(x1,y1,1);local c,d=point(x2,y2,1)
   local dx,dy=c-a,d-b;local length=math.sqrt(dx*dx+dy*dy)
   local nx,ny=-dy/length*0.5/zoom,dx/length*0.5/zoom
   self:drawPolygon(nil,a+nx,b+ny,c+nx,d+ny,c-nx,d-ny,a-nx,b-ny,0.36*light,0.37*light,0.38*light,1)
  end
  for x=0,12 do seam(x/2,0,x/2,3) end
  for y=0,6 do seam(0,y/2,6,y/2) end
  end
  -- Original raster is 980x680; its world origin is pixel (460,340).
  local x,y=point(0,s.rotated and 3 or 0,1)
  self:drawTextureScaled(texture,x-460/zoom,y-340/zoom,980/zoom,680/zoom,1,light,light,light)
 end
 local height=s.stackRevision==1 and 2 or 3.2/math.sqrt(6)
 local function sides(low,high)
  if s.glassOverlay==false then return end
  for _,face in ipairs({
   {{0.025,0.025},{5.975,0.025},0.07},
   {{0.025,0.025},{0.025,2.975},0.07},
   {{0.025,2.975},{5.975,2.975},0.16},
   {{5.975,2.975},{5.975,0.025},0.16},
  }) do pane(face[1],face[2],low,high,face[3],0.44,0.57,0.62) end
 end
 if s.stackRevision==1 then
  -- Adjacent panes meet at one plane; no doubled tint or intermediate glass roof.
  if not cutaway.ready then return end
  if cutaway.visible[0] then sides(0.025,1) end
  if cutaway.visible[1] then sides(1,1.975) end

 else sides(0.025,height-0.025) end
 if not s.noGlassRoof and s.glassOverlay~=false and (s.stackRevision~=1 or cutaway.visible[1]) then
 local x1,y1=point(0.025,0.025,height)
 local x2,y2=point(5.975,0.025,height)
 local x3,y3=point(5.975,2.975,height)
 local x4,y4=point(0.025,2.975,height)
 glass(x1,y1,x2,y2,x3,y3,x4,y4,0.53,0.63,0.67,0.09)

 end

 -- Continuous projected frame while native world sprites are cut away outside.
 -- Never add world geometry or shadow casters. Assets remain untouched.
 if s.stackRevision==1 and cutaway.outline then
  local playerX,playerY=worldPoint(player:getX()-s.siteX,player:getY()-s.siteY,player:getZ())
  -- World projection gives feet. Approximate the standing body, with a small margin.
  local maskX,maskY=playerX,playerY-62/zoom
  local function line(a,b,width,r,g,blue)
   local ax,ay=point(a[1],a[2],a[3]);local bx,by=point(b[1],b[2],b[3])
   local dx,dy=bx-ax,by-ay;local length=math.sqrt(dx*dx+dy*dy)
   if length==0 then return end
   local nx,ny=-dy/length*width/(2*zoom),dx/length*width/(2*zoom)
   local ranges=railMask.visible(ax,ay,bx,by,maskX,maskY,(23+width/2)/zoom,(67+width/2)/zoom,a[1]+a[2],b[1]+b[2],player:getX()-s.siteX+player:getY()-s.siteY)
   for _,range in ipairs(ranges) do
    local x1,y1=ax+dx*range[1],ay+dy*range[1]
    local x2,y2=ax+dx*range[2],ay+dy*range[2]
    self:drawPolygon(nil,x1+nx,y1+ny,x2+nx,y2+ny,x2-nx,y2-ny,x1-nx,y1-ny,r,g,blue,1)
   end
  end
  local function rail(a,b)
   line(a,b,5,0.110,0.125,0.135)
   line(a,b,1,0.400,0.435,0.455)
  end
  if cutaway.contents and cutaway.visible[0] and cutaway.visible[1] then
   for _,segment in ipairs(frameSegments) do rail(segment[1],segment[2]) end
  else
  local corners={{0,0},{6,0},{6,3},{0,3}}
  local levels={}
  for level=0,1 do
   if cutaway.visible[level] then
    levels[level]=true;levels[level+1]=true
    for _,v in ipairs(corners) do rail({v[1],v[2],level},{v[1],v[2],level+1}) end
   end
  end
  for z=0,2 do if levels[z] then
   for i=1,4 do local a,b=corners[i],corners[i%4+1];rail({a[1],a[2],z},{b[1],b[2],z}) end
  end end
  end
 end

end
function Glass:render()
 local s=state();if not s or self.failed then return end
 local ok,why=pcall(function()
  self:drawPanes(s)
  local combined=ModData.get('TSBAstroluxCombined12.v1')
  local p=getSpecificPlayer(0)
  if combined and combined.ready and p and p:getZ()==0 then
   local x,y=combined.x,combined.y
   local inside=p:getX()>=x and p:getX()<x+12 and p:getY()>=y and p:getY()<y+12
   if not inside and getCell():getGridSquare(x+10,y+10,1) then
    -- Corner framing is sorted with each car level.
    -- Complete each story from rear bays to front bays before the next story.
    local vehicles={
     {'AstroluxBayPickupSouth','AstroluxBayCompactEast','AstroluxBayBlueSedanEast','AstroluxBayUpperVehicle'},
     {'AstroluxBayLuxuryNorth','AstroluxBayModernWest','AstroluxBayModern02East','AstroluxBaySUVSouth'},
     {'AstroluxBaySportsNorth','AstroluxBaySmall02West','AstroluxBayPickupVanEast','AstroluxBayVanSouth'},
    }
    for level=0,2 do
     roofRim.draw(self,x,y,level,'rear')
    serviceCore.draw(self,x,y,level)
     local names=vehicles[level+1]
     local bays={{3,0,northStructure=true},{0,3,rotated=true,westStructure=true},{9,3,rotated=true},{3,9}}
     for i,b in ipairs(bays) do
      self:drawPanes({siteX=x+b[1],siteY=y+b[2],stackRevision=1,layerVisible={Frame=true},previewBay=true,
       northStructure=b.northStructure,rotated=b.rotated,westStructure=b.westStructure,levelOffset=level,
       noGlassRoof=true,previewTexture='media/textures/'..names[i]..'.png'})
     end
    roofRim.draw(self,x,y,level,'front')
    end
    roofCap.draw(self,x,y)
   end
  end
 end)
 if not ok then self.failed=true;print('[Astrolux Glass Overlay] Disabled after error: '..tostring(why)) end
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%30~=0 then return end
 if not state() then if panel then panel:removeFromUIManager();panel=nil end;return end
 if not panel then
  panel=Glass:new(0,0,getCore():getScreenWidth(),getCore():getScreenHeight())
  panel:initialise();panel:addToUIManager()
  panel.javaObject:setConsumeMouseEvents(false)
  panel.javaObject:backMost()
  print('[Astrolux Glass Overlay] UI panes ready; no world glass objects. Occlusion is experimental.')
 end
 panel:setWidth(getCore():getScreenWidth());panel:setHeight(getCore():getScreenHeight())
end)

Events.OnFillWorldObjectContextMenu.Add(function(player,context,objects,test)
 local s=state();if test or not s or s.stackRevision~=1 then return end
 context:addOption(s.fixtureLights==false and 'Turn Bay Lights On' or 'Turn Bay Lights Off',nil,function()s.fixtureLights=s.fixtureLights==false;fixtureLights.refresh() end)
 context:addOption(s.bayDetails==false and 'Show Bay Details' or 'Hide Bay Details',nil,function()s.bayDetails=s.bayDetails==false end)
 context:addOption(s.platformStyleTest==false and 'Test Metal Platform' or 'Use Original Tiled Platform',nil,function()s.platformStyleTest=s.platformStyleTest==false;cutaway.update() end)
 context:addOption(s.glassOverlay==false and 'Show Stack Glass' or 'Hide Stack Glass',nil,function()s.glassOverlay=s.glassOverlay==false end)
end)

return {Glass=Glass,state=state}




