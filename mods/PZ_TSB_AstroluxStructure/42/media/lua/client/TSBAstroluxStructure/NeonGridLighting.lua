local Visibility=require 'TSBAstroluxStructure/FixtureVisibility'
require 'ISUI/ISUIElement'
local Power=require 'TSBAstroluxStructure/FixturePower'
local M={};local tracked=setmetatable({},{__mode='k'});local active={};local ticks=0;local panel
local Overlay=ISUIElement:derive('TSBAstroluxNeonPowerOverlay')
function Overlay:onMouseDown()return false end
function Overlay:onMouseUp()return false end
function Overlay:onRightMouseDown()return false end
function Overlay:onRightMouseUp()return false end
function Overlay:onMouseMove()return false end
function Overlay:onMouseWheel()return false end
function M.isSign(o)
 if not Power.supported(o)then return false end
 return o:getSprite():getName():match('^TSBAstroluxMotorsSign_[0-3]$')~=nil
end
function M.needsLight(o)
 if not M.isSign(o)or not o:isActivated()or o:canSwitchLight()or not Power.available(o)then return false end
 local s=o:getSquare();return getCell():getGridSquare(s:getX(),s:getY(),s:getZ())==s
end
local function clear(o)
 local a=active[o];if a then a.cell:removeLamppost(a.light);active[o]=nil end
end
function M.refresh(o)
 if not M.needsLight(o)then clear(o);return end
 local cell=getCell();local s=o:getSquare();local a=active[o]
 if a and(a.cell~=cell or a.square~=s)then clear(o);a=nil end
 if not a then
  local light=cell:addLamppost(s:getX(),s:getY(),s:getZ(),o:getPrimaryR(),o:getPrimaryG(),o:getPrimaryB(),4)
  if light then active[o]={cell=cell,square=s,light=light}end
 end
end
function Overlay:render()
 local p=getSpecificPlayer(0);if not p then return end
 local zoom=getCore():getZoom(0)
 for o in pairs(active)do
  local s=o:getSquare()
  if M.needsLight(o)and p:getZ()==s:getZ()and Visibility.visible(s,p)and o:getDoRender()and o:getAlpha(0)>.1 then
   local index=o:getSprite():getName():match('_(%d+)$')
   local texture=getTexture('TSBAstroluxMotorsSign_on_'..index)
   if texture then
    local x=(IsoUtils.XToScreen(s:getX(),s:getY(),s:getZ(),0)-IsoCamera.getOffX(0)-o:getOffsetX()+texture:getOffsetX())/zoom
    local y=(IsoUtils.YToScreen(s:getX(),s:getY(),s:getZ(),0)-IsoCamera.getOffY(0)-o:getOffsetY()-o:getRenderYOffset()*2+texture:getOffsetY())/zoom
    self:drawSubTexture(texture,0,0,texture:getWidth(),texture:getHeight(),x-texture:getOffsetX(),y-texture:getOffsetY(),texture:getWidth()/zoom,texture:getHeight()/zoom,o:getAlpha(0),1,1,1)
   end
  end
 end
end
local function visit(s)
 if not s then return end
 local list=s:getObjects();for i=0,list:size()-1 do local o=list:get(i);if M.isSign(o)then tracked[o]=true end end
end
Events.LoadGridsquare.Add(visit)
Events.OnObjectAdded.Add(function(o)if M.isSign(o)then tracked[o]=true end end)
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%30~=0 then return end
 local cell=getCell();local p=getSpecificPlayer(0)
 if cell and p then for x=-15,15 do for y=-15,15 do visit(cell:getGridSquare(math.floor(p:getX())+x,math.floor(p:getY())+y,p:getZ()))end end end
 for o in pairs(tracked)do M.refresh(o);if o:getObjectIndex()<0 then tracked[o]=nil end end
 local hasActive=false;for _ in pairs(active)do hasActive=true;break end
 if hasActive and not panel then
  panel=Overlay:new(0,0,getCore():getScreenWidth(),getCore():getScreenHeight());panel:initialise();panel:addToUIManager();panel.javaObject:setConsumeMouseEvents(false);panel.javaObject:backMost()
 elseif not hasActive and panel then panel:removeFromUIManager();panel=nil end
 if panel then panel:setWidth(getCore():getScreenWidth());panel:setHeight(getCore():getScreenHeight())end
end)
return M
