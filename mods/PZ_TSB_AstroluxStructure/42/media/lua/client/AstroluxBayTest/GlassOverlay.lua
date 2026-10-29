local showroomLights=require 'AstroluxBayTest/ShowroomLights'
local roofCap=require 'AstroluxBayTest/RoofCap'
local roofRim=require 'AstroluxBayTest/RoofRimOverlay'
local serviceCore=require 'AstroluxBayTest/ServiceCore'
local glassMask=require 'AstroluxBayTest/GlassMask'
local fixtureLights=require 'AstroluxBayTest/FixtureLights'
local combinedLights=require 'AstroluxBayTest/CombinedLights'
local metalPlatform=require 'AstroluxBayTest/MetalPlatform'
local cornerStyle=require 'AstroluxBayTest/CornerCanopyStyle'
local railMask=require 'AstroluxBayTest/RailMask'
local frameSegments=require 'AstroluxBayTest/FrameOcclusion'
local cutaway=require 'AstroluxBayTest/StackCutaway'
local exteriorCutaway=require 'AstroluxBayTest/ExteriorCutaway'
local cutawayRunPerLevel=nil
require 'ISUI/ISUIElement'
require 'ISUI/ISToolTip'
local Glass=ISUIElement:derive('AstroluxTestGlassOverlay')
local panel=nil;local ticks=0;local profile=nil
local function state()
 if isClient() or isServer() or not getWorld() or not require('AstroluxBayTest/TestWorld').enabled() or getNumActivePlayers()~=1 then return nil end
 local s=ModData.get('TSBAstroluxBayTest.v1')
 -- A pasted corner-lab showroom has no legacy scale-study cubes/state.
 -- Render its existing approved tower directly from its registered site.
 -- Keep all geometry and original lab state unchanged.
 if require('AstroluxBayTest/TestWorld').corner() then
  local combined=ModData.get('TSBAstroluxCombined12.v1')
  local site=ModData.get('TSBAstroluxCityPerformance.v1')
  if not combined or not combined.ready or not combined.recordId or not site
   or site.recordId~=combined.recordId or site.x~=combined.x or site.y~=combined.y then return nil end
  s=ModData.getOrCreate('TSBAstroluxCornerTowerPreview.v1')
  s.testCubesRetired=true;s.stackRevision=1
 end
 if s and (s.testCubesRetired or (s.layerRevision==1 and s.nativeFloorRevision==1 and s.siteX and s.siteY)) then return s end
end
function Glass:onMouseDown()return false end
function Glass:onMouseUp()return false end
function Glass:onRightMouseDown()return false end
function Glass:onRightMouseUp()return false end
function Glass:onMouseMove()return false end
function Glass:onMouseWheel()return false end
function Glass:drawPanes(s)
 local cutaway=s.previewBay and {ready=true,contents=not s.northFrameOnly,outline=true,visible={[0]=false,[1]=true}} or cutaway
 local player=getSpecificPlayer(0)
 if not player or player:getZ()~=0 or not s.layerVisible or not s.layerVisible.Frame then return end
 local zoom=getCore():getZoom(0)
 -- Native IsoUtils projection is affine. Sample the origin and unit axes once
 -- per bay instead of repeating four Java calls for every projected vertex.
 local ox=(IsoUtils.XToScreen(s.siteX,s.siteY,0,0)-IsoCamera.getOffX(0))/zoom
 local oy=(IsoUtils.YToScreen(s.siteX,s.siteY,0,0)-IsoCamera.getOffY(0))/zoom
 local xx=IsoUtils.XToScreen(1,0,0,0)/zoom
 local xy=IsoUtils.YToScreen(1,0,0,0)/zoom
 local yx=IsoUtils.XToScreen(0,1,0,0)/zoom
 local yy=IsoUtils.YToScreen(0,1,0,0)/zoom
 local zx=IsoUtils.XToScreen(0,0,1,0)/zoom
 local zy=IsoUtils.YToScreen(0,0,1,0)/zoom
 local function worldPoint(x,y,z)
  return ox+x*xx+y*yx+z*zx,oy+x*xy+y*yy+z*zy
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
  -- Intact panes already form a convex quad. Submit once instead of creating
  -- tables and crossing into Java twice for two degenerate triangle quads.
  -- Keep silhouette-clipped panes on the existing triangulation path.
  if not playerInFront then
   self:drawPolygon(nil,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,alpha)
   return
  end
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
 local function drawFrame(pass)
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
   if s.previewBay and not s.northFrameOnly then
    local ax,ay,bx,by=a[1],a[2],b[1],b[2]
    if s.rotated then ax,ay,bx,by=3-ay,ax,3-by,bx end
    local rear=(ax==0 and bx==0) or (ay==0 and by==0)
    if rear~=(pass=='rear') then return end
   elseif pass=='rear' then return end
   line(a,b,5,0.110,0.125,0.135)
   line(a,b,1,0.400,0.435,0.455)
  end
  if s.northFrameOnly then
   -- Retain only the exposed north frame of the culled middle-tier bay.
   rail({0,0,1},{6,0,1});rail({0,0,2},{6,0,2})
   rail({0,0,1},{0,0,2});rail({6,0,1},{6,0,2})
  elseif cutaway.contents and cutaway.visible[0] and cutaway.visible[1] then
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
 drawFrame('rear')
 -- Draw the upper platform and unchanged car artwork before glass and rails.
 if s.stackRevision==1 and cutaway.ready and cutaway.contents and cutaway.visible[1] then

  -- Rotated platforms occupy 3x6 rather than 6x3 tiles.
  -- Sample their lit interior, not the missing square beyond the outer edge.
  -- Upper display stories intentionally share the native first-level lighting.
  local sampleX,sampleY=3,1
  if s.rotated then sampleX,sampleY=1,3 end
  local sq=getCell():getGridSquare(s.siteX+sampleX,s.siteY+sampleY,1)
  local light=sq and math.max(0,math.min(1,sq:getLightLevel(0))) or 1
  -- Decorative upper stories have no native model lighting of their own.
  -- Supply fixture-driven fill as dusk rises; retain brighter native daylight.
  if s.previewBay and s.fixtureLights~=false and s.bayDetails~=false and s.platformStyleTest~=false then
   local strength=math.max(0,math.min(1,combinedLights.brightness or 0))
   light=math.max(light,0.88*strength)
  end
  local function floorQuad(x,y)
   local a,b=point(x,y,1);local c,d=point(x+1,y,1)
   local e,f=point(x+1,y+1,1);local g,h=point(x,y+1,1)
   self:drawPolygon(nil,a,b,c,d,e,f,g,h,0.49*light,0.50*light,0.51*light,1)
  end
  if s.platformStyleTest~=false then
   if s.bayDetails~=false then metalPlatform.drawDetails(self,detailPoint,light,s.fixtureLights~=false and ((s.previewBay and combinedLights.brightness or fixtureLights.brightness)or 0)>0,(s.previewBay and combinedLights.brightness or fixtureLights.brightness),s.previewBay,s.noGlassRoof,s.previewBay and s.levelOffset==0 and cornerStyle.active()) end
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
  if s.vehicleImages~=false then
   local texture=getTexture(s.previewTexture or 'media/textures/AstroluxBayBlueSedan.png')
   assert(texture,'Upper vehicle fallback texture missing')
   self:drawTextureScaled(texture,x-460/zoom,y-340/zoom,980/zoom,680/zoom,1,light,light,light)
  end
 end
 local height=s.stackRevision==1 and 2 or 3.2/math.sqrt(6)
 local function sides(low,high)
  if s.northFrameOnly or s.glassOverlay==false then return end
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

 drawFrame('front')
end
local function measured(name,fn,...)
 if not profile then return fn(...) end
 local started=getTimestampMs()
 fn(...)
 profile[name]=(profile[name] or 0)+(getTimestampMs()-started)
end
local function prototypeView()
 local sample=rawget(_G,'TSBAstroluxDiagonalPrototypeView')
 return sample and sample.active and sample.active() and sample or nil
end
function Glass:render()
 local s=state();local sample=prototypeView()
 if (not s and not sample) or self.failed then return end
 local ok,why=pcall(function()
  -- One owner, fixed order: distant prototype glass, then the complete tower.
  -- The standalone test stays visible when there is no pasted showroom yet.
  if sample then sample.draw(self)end
  if not s then return end
  -- Keep the private ground-glass pass below every upper story/canopy/roof.
  -- One UI owner fixes ordering without moving any world object or geometry.
  local ground=rawget(_G,'TSBAstroluxShowroomDiagonalPreview')
  if ground and ground.draw then ground.draw(self)end
  showroomLights.draw(self)
  if not s.testCubesRetired then self:drawPanes(s) end
  local combined=ModData.get('TSBAstroluxCombined12.v1')
  local p=getSpecificPlayer(0)
  if combined and combined.ready and p and p:getZ()==0 then
   local x,y=combined.x,combined.y
   if not cutawayRunPerLevel then
    local origin=IsoUtils.YToScreen(0,0,0,0)
    local rise=origin-IsoUtils.YToScreen(0,0,1,0)
    local diagonal=IsoUtils.YToScreen(1,1,0,0)-origin
    assert(diagonal>0 and rise>0,'Unsupported tower cutaway projection')
    cutawayRunPerLevel=rise/diagonal
   end
   local obscured=exteriorCutaway.hidesPlayer(p:getX(),p:getY(),p:getZ(),x,y,12,cutawayRunPerLevel)
   if obscured and p:getX()>=x and p:getX()<x+12 and p:getY()>=y and p:getY()<y+12 then
    roofRim.draw(self,x,y,0,'rear',true)
    roofRim.draw(self,x,y,0,'front',true)
   end
   -- Corner ceilings are intentionally absent; their upper squares may unload.
   -- Gate the decorative tower on the permanent ground footprint instead.
   if not obscured and getCell():getGridSquare(x+10,y+10,0) then
    -- Corner framing is sorted with each car level.
    -- Complete each story from rear bays to front bays before the next story.
    local vehicles={
     {'AstroluxBayPickupSouth','AstroluxBayCompactEast','AstroluxBayBlueSedanEast','AstroluxBayUpperVehicle'},
     {'AstroluxBayLuxuryNorth','AstroluxBayModernWest','AstroluxBayModern02East','AstroluxBaySUVSouth'},
     {'AstroluxBaySportsNorth','AstroluxBaySmall02West','AstroluxBayPickupVanEast','AstroluxBayVanSouth'},
    }
    for level=0,2 do
     measured('canopies',roofRim.draw,self,x,y,level,'rear')
    measured('core',serviceCore.draw,self,x,y,level)
     local names=vehicles[level+1]
     local bays={{3,0,northStructure=true},{0,3,rotated=true,westStructure=true},{9,3,rotated=true},{3,9}}
     for i,b in ipairs(bays) do
      -- Lab comparison: omit the rear pair before optimizing retained geometry.
      -- Keep restoration available until fixed-view occlusion is live-verified.
      local northFrameOnly=i==1 and level==1 and s.showRearTowerBays~=true
      if i>2 or s.showRearTowerBays==true or northFrameOnly then
      measured('bays',self.drawPanes,self,{siteX=x+b[1],siteY=y+b[2],stackRevision=1,layerVisible={Frame=true},previewBay=true,
       vehicleImages=s.vehicleImages,northFrameOnly=northFrameOnly,glassOverlay=s.glassOverlay,bayDetails=s.bayDetails,fixtureLights=s.fixtureLights,platformStyleTest=s.platformStyleTest,
       northStructure=b.northStructure,rotated=b.rotated,westStructure=b.westStructure,levelOffset=level,
       noGlassRoof=true,previewTexture='media/textures/'..names[i]..'.png'})
      end
     end
    measured('canopies',roofRim.draw,self,x,y,level,'front')
    end
    measured('roof',roofCap.draw,self,x,y)
    if profile then
     profile.frames=profile.frames+1
     if profile.frames>=120 then
      for _,name in ipairs({'canopies','core','bays','roof'})do
       print('[Astrolux Profile] '..name..' CPU submission ms/frame='..string.format('%.3f',(profile[name] or 0)/profile.frames))
      end
      print('[Astrolux Profile] Complete: 120 exterior frames. CPU timings exclude asynchronous GPU work.')
      profile=nil
     end
    end
   end
  end
 end)
 if not ok then self.failed=true;print('[Astrolux Glass Overlay] Disabled after error: '..tostring(why)) end
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%30~=0 then return end
 if not state() and not prototypeView() then if panel then panel:removeFromUIManager();panel=nil end;return end
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
 context:addOption('Measure Tower Drawing (120 frames)',nil,function()profile={frames=0};print('[Astrolux Profile] Started; remain outside at the same position and zoom.')end)
 context:addOption(s.fixtureLights==false and 'Turn Bay Lights On' or 'Turn Bay Lights Off',nil,function()s.fixtureLights=s.fixtureLights==false;fixtureLights.refresh() end)
 context:addOption(s.bayDetails==false and 'Show Bay Details' or 'Hide Bay Details',nil,function()s.bayDetails=s.bayDetails==false end)
 context:addOption(s.platformStyleTest==false and 'Test Metal Platform' or 'Use Original Tiled Platform',nil,function()s.platformStyleTest=s.platformStyleTest==false;cutaway.update() end)
 context:addOption(s.glassOverlay==false and 'Show Stack Glass' or 'Hide Stack Glass',nil,function()s.glassOverlay=s.glassOverlay==false end)
 local imageOption=context:addOption(s.vehicleImages==false and 'Show Tower Vehicle Images' or 'Hide Tower Vehicle Images',nil,function()s.vehicleImages=s.vehicleImages==false end)
 imageOption.toolTip=ISToolTip:new();imageOption.toolTip:initialise();imageOption.toolTip.description='Performance comparison: toggles decorative vehicle images only. Frames, platforms and glass stay visible.'
 context:addOption(s.showRearTowerBays==true and 'Hide Rear Tower Bays' or 'Show Rear Tower Bays',nil,function()s.showRearTowerBays=not s.showRearTowerBays end)
end)

return {Glass=Glass,state=state}




