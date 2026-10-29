local NativeNumbers=require 'TSBAstroluxVend/NativeKioskNumbers'
require 'ISUI/ISUIElement'
local Geometry=require 'TSBAstroluxVend/NumberGeometry'
local Overlay=ISUIElement:derive('TSBAstroluxNumberOverlay')
-- Java UIElement treats a nil Lua right-click result as consumed, even when
-- consumeMouseEvents=false. Every visual-only input handler must return false.
function Overlay:onMouseDown()return false end
function Overlay:onMouseUp()return false end
function Overlay:onRightMouseDown()return false end
function Overlay:onRightMouseUp()return false end
function Overlay:onMouseMove()return false end
function Overlay:onMouseWheel()return false end
local panel;local rows={};local ticks=0
Events.OnServerCommand.Add(function(module,command,data)
 if module=='TSBAstroluxLabels'and command=='snapshot'and type(data)=='table'then rows=data.rows or {}end
end)
local function request()
 if isClient()then local p=getSpecificPlayer(0);if p then sendClientCommand(p,'TSBAstroluxLabels','snapshot',{})end end
end
Events.OnGameStart.Add(request)
local function screen(x,y,z,zoom)
 return (IsoUtils.XToScreen(x,y,z,0)-IsoCamera.getOffX(0))/zoom,(IsoUtils.YToScreen(x,y,z,0)-IsoCamera.getOffY(0))/zoom
end
local function paint(self,quads,project,r,g,b,alpha)
 for _,q in ipairs(quads)do
  local a,c=project(q[1][1],q[1][2]);local d,e=project(q[2][1],q[2][2])
  local f,h=project(q[3][1],q[3][2]);local i,j=project(q[4][1],q[4][2])
  self:drawPolygon(nil,a,c,d,e,f,h,i,j,r,g,b,alpha)
 end
end
function Overlay:render()
 local p=getSpecificPlayer(0);local cell=getCell();if not p or not cell then return end
 local zoom=getCore():getZoom(0)
 for _,row in ipairs(isClient()and rows or TSBAstroluxPresentationLabels or {})do
  local quads=Geometry.quads(row.number);local a=row.area
  if a and p:getZ()==0 then
   local cx,cy=Geometry.zone(a,.5,.5);local sq=cell:getGridSquare(math.floor(cx),math.floor(cy),0)
   if sq and sq:isCanSee(0)and(p:getX()-cx)^2+(p:getY()-cy)^2<1600 then
    paint(self,quads,function(u,v)local x,y=Geometry.zone(a,u,v);return screen(x,y,0,zoom)end,1,.9,.08,.95)
   end
  end

 end
end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%30~=0 then return end
 local data=isClient()and rows or TSBAstroluxPresentationLabels or {}
 NativeNumbers.update(data)
 if #data==0 then
  if panel then panel:removeFromUIManager();panel=nil end
  return
 end
 if not panel then
  panel=Overlay:new(0,0,getCore():getScreenWidth(),getCore():getScreenHeight());panel:initialise();panel:addToUIManager()
  panel.javaObject:setConsumeMouseEvents(false);panel.javaObject:backMost();request()
 end
 panel:setWidth(getCore():getScreenWidth());panel:setHeight(getCore():getScreenHeight())
end)
return {Overlay=Overlay}
