require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'
local A=require 'TSBAstroluxVend/SpawnAreas'
local Cursor=ISPanel:derive('TSBAstroluxSpawnAreaCursor')
local active
function Cursor:start(character,heading,complete,options)
    if active then active:cancel() end
    local index=character:getPlayerNum()
    local o=ISPanel:new(getPlayerScreenLeft(index),getPlayerScreenTop(index),getPlayerScreenWidth(index),getPlayerScreenHeight(index))
    setmetatable(o,self);self.__index=self
    options=options or {};o.gap=options.gap or 0;o.script=options.script
    o.player=index;o.character=character;o.heading=heading;o.complete=complete
    o.backgroundColor={r=0,g=0,b=0,a=0};o.borderColor={r=0,g=0,b=0,a=0}
    o:initialise();o:addToUIManager();o:bringToTop();active=o
    return o
end
-- Read-only viewer: reuse the native area highlight used by selection.
function Cursor:showZone(character,area,script,complete)
    local o=self:start(character,area.heading,nil,{gap=area.gap,script=script})
    o:review(area,complete)
    return o
end
function Cursor:point()
    return math.floor(screenToIsoX(self.player,getMouseX(),getMouseY(),0)),math.floor(screenToIsoY(self.player,getMouseX(),getMouseY(),0))
end
function Cursor:onMouseDown()
    if self.viewArea then return true end
    self.ax,self.ay=self:point();return true
end
function Cursor:onMouseUp()
    if self.viewArea then return true end
    if not self.ax then return true end
    local bx,by=self:point()
    local area,why=A.rectangle(self.ax,self.ay,bx,by,self.heading,self.gap)
    if not area then self.character:Say(why);return true end
    self:review(area,self.complete)
    return true
end
function Cursor:onMouseUpOutside() return self:onMouseUp() end
function Cursor:onRightMouseDown() self:cancel();return true end
function Cursor:cancel() self:removeFromUIManager();if active==self then active=nil end end
function Cursor:drawFacingArrow(a,quiet)
    local d=A.vectors[a.heading];if not d then return end
    local cx,cy=(a.x1+a.x2+1)/2,(a.y1+a.y2+1)/2
    local length=math.min(3,math.min(a.x2-a.x1+1,a.y2-a.y1+1)*0.35)
    local dx,dy=d[1],d[2];local px,py=-dy,dx
    local function screen(x,y)
        return isoToScreenX(self.player,x,y,0)-getPlayerScreenLeft(self.player),isoToScreenY(self.player,x,y,0)-getPlayerScreenTop(self.player)
    end
    local tx,ty=cx+dx*length,cy+dy*length
    local x1,y1=screen(cx-dx*length,cy-dy*length)
    local x2,y2=screen(tx,ty)
    local hx1,hy1=screen(tx-dx*length*0.55+px*length*0.4,ty-dy*length*0.55+py*length*0.4)
    local hx2,hy2=screen(tx-dx*length*0.55-px*length*0.4,ty-dy*length*0.55-py*length*0.4)
    self:drawLine(nil,x1,y1,x2,y2,4,1,1,0.85,0.1)
    self:drawLine(nil,x2,y2,hx1,hy1,4,1,1,0.85,0.1)
    self:drawLine(nil,x2,y2,hx2,hy2,4,1,1,0.85,0.1)
    if not quiet then self:drawText('Vehicles face '..a.heading,x2+12,y2,1,0.9,0.2,1,UIFont.Small)end
end
function Cursor:review(area,complete)
 self.viewArea=area
 if self.saveButton then self:removeChild(self.saveButton);self.saveButton=nil end
 if not complete then return end
 self.saveButton=ISButton:new(20,90,240,30,'Save This Parking Layout',self,function(s)
  local text='Save this delivery zone? <LINE> Vehicles face '..area.heading..'; minimum gap '..tostring(area.gap or 0)..' tiles.'
  local modal=ISModalRichText:new(100,100,620,220,text,true,nil,function(_,button)
   if button.internal=='YES'then s:cancel();complete(area.x1,area.y1,area.x2,area.y2)end
  end,s.player)
  modal:initialise();modal:addToUIManager()
 end)
 self.saveButton:initialise();self:addChild(self.saveButton)
end
function Cursor:drawParking(a)
 if not self.script then
  self:drawText('Choose a vehicle in Vehicles to preview parking spaces.',20,65,1,.85,.3,1,UIFont.Small);return
 end
 local cx,cy=math.floor(self.character:getX()),math.floor(self.character:getY())
 local key=table.concat({a.x1,a.y1,a.x2,a.y2,a.heading,a.gap or 0,cx,cy,self.script},':')
 if self.planKey~=key then
  self.planKey=key
  local ok,slots,limited=pcall(function()
   local script=getScriptManager():getVehicle(self.script)
   local region={x1=cx-25,y1=cy-25,x2=cx+25,y2=cy+25}
   return require('TSBAstroluxVend/ParkingPreview').build(A,a,script,region,40)
  end)
  self.parking=ok and slots or {};self.limited=limited;self.planError=not ok
 end
 for _,p in ipairs(self.parking)do
  for i,v in ipairs(p.footprint)do
   local w=p.footprint[i%#p.footprint+1]
   local x1=isoToScreenX(self.player,v.x,v.y,0)-getPlayerScreenLeft(self.player)
   local y1=isoToScreenY(self.player,v.x,v.y,0)-getPlayerScreenTop(self.player)
   local x2=isoToScreenX(self.player,w.x,w.y,0)-getPlayerScreenLeft(self.player)
   local y2=isoToScreenY(self.player,w.x,w.y,0)-getPlayerScreenTop(self.player)
   self:drawLine(nil,x1,y1,x2,y2,2,1,.25,1,.65)
  end
  self:drawFacingArrow({x1=p.x-1,y1=p.y-1,x2=p.x+1,y2=p.y+1,heading=a.heading},true)
 end
 local text=self.planError and 'Vehicle geometry unavailable.' or ('Parking preview: '..self.script..' | gap '..tostring(a.gap or 0)..' tiles | '..#self.parking..' nearby spaces')
 self:drawText(text,20,45,1,1,1,1,UIFont.Small)
 self:drawText('Illustrative layout near you; actual deliveries recheck vehicles and obstructions. Right-click / Escape cancels.',20,65,1,.85,.3,1,UIFont.Small)
end

function Cursor:prerender()
    if self.viewArea then
        local a=self.viewArea
        addAreaHighlightForPlayer(self.player,a.x1,a.y1,a.x2+1,a.y2+1,0,0.1,0.9,0.8,0.5)
        self:drawFacingArrow(a)
        self:drawParking(a)
        self:drawText('Delivery Zone: '..a.x1..', '..a.y1..' to '..a.x2..', '..a.y2..' | Vehicles face '..tostring(a.heading),20,20,1,1,1,1,UIFont.Small)

        return
    end
    local x,y=self:point()
    local ax,ay=self.ax or x,self.ay or y
    addAreaHighlightForPlayer(self.player,math.min(ax,x),math.min(ay,y),math.max(ax,x)+1,math.max(ay,y)+1,0,0.1,0.9,0.8,0.5)
    local area={x1=math.min(ax,x),y1=math.min(ay,y),x2=math.max(ax,x),y2=math.max(ay,y),heading=self.heading,gap=self.gap}
    self:drawFacingArrow(area);self:drawParking(area)
    self:drawText('Astrolux spawn area: drag from one corner tile to the opposite corner. Right-click / Escape cancels.',20,20,1,1,1,1,UIFont.Small)
end
Events.OnKeyPressed.Add(function(key) if active and key==Keyboard.KEY_ESCAPE then active:cancel() end end)
return Cursor
