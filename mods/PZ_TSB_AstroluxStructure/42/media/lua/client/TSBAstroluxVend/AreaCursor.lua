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
    options=options or {};o.gap=options.gap or 0;o.rowGap=options.rowGap;o.script=options.script
    o.player=index;o.character=character;o.heading=heading;o.complete=complete
    o.finish=options.finish;o.editArea=options.initialArea;o.moveWithMouse=false
    o.backgroundColor={r=0,g=0,b=0,a=0};o.borderColor={r=0,g=0,b=0,a=0}
    o:initialise();o:addToUIManager();o:bringToTop();active=o
    o.cancelButton=ISButton:new(280,90,180,30,'Cancel Selection',o,function(s)s:cancel()end)
    o.cancelButton:initialise();o:addChild(o.cancelButton)
    return o
end
-- Read-only viewer: reuse the native area highlight used by selection.
function Cursor:showZone(character,area,script,complete)
    local o=self:start(character,area.heading,nil,{gap=area.gap,rowGap=area.rowGap,script=script})
    o:review(area,complete)
    return o
end
function Cursor:point()
    return math.floor(screenToIsoX(self.player,getMouseX(),getMouseY(),0)),math.floor(screenToIsoY(self.player,getMouseX(),getMouseY(),0))
end
function Cursor:onMouseDown()
    if self.closed or self.pendingReview then return true end
    if self.viewArea then return true end
    local x,y=self:point();local a=self.editArea
    self.dragStartX,self.dragStartY=x,y;self.dragMove=false
    if a then
     local corners={{a.x1,a.y1,a.x2,a.y2},{a.x2,a.y1,a.x1,a.y2},{a.x1,a.y2,a.x2,a.y1},{a.x2,a.y2,a.x1,a.y1}}
     for _,v in ipairs(corners)do
      if math.abs(x-v[1])<=1 and math.abs(y-v[2])<=1 then
       self.ax,self.ay=v[3],v[4];self:setCapture(true);return true
      end
     end
     if x>=a.x1 and x<=a.x2 and y>=a.y1 and y<=a.y2 then self.dragMove=true end
    end
    self.ax,self.ay=x,y;self:setCapture(true);return true
end
function Cursor:onMouseUp()
    if self.closed or self.pendingReview then return true end
    if self.viewArea then return true end
    if not self.ax then return true end
    local bx,by=self:point()
    self:setCapture(false)
    local area,why=self:draft(bx,by)
    if not area then self.character:Say(why);return true end
    self:review(area,self.complete)
    return true
end
function Cursor:draft(x,y)
 if self.dragMove and self.editArea then
  local a=self.editArea;local dx,dy=x-self.dragStartX,y-self.dragStartY
  return A.rectangle(a.x1+dx,a.y1+dy,a.x2+dx,a.y2+dy,self.heading,self.gap,self.rowGap)
 end
 return A.rectangle(self.ax or x,self.ay or y,x,y,self.heading,self.gap,self.rowGap)
end
function Cursor:onMouseMove()return true end
function Cursor:onMouseMoveOutside()return true end
function Cursor:finishSelection()
 local callback=self.finish;self.finish=nil
 if callback then callback()end
end
function Cursor:onMouseUpOutside() return self:onMouseUp() end
function Cursor:onRightMouseDown() self:cancel();return true end
function Cursor:cancel(review)
 self.closed=true;self.pendingReview=nil
 self:setCapture(false);self:setVisible(false);self:removeFromUIManager()
 if active==self then active=nil end
 if not review then self:finishSelection()end
end
function Cursor:drawFacingArrow(a,quiet)
    local d=A.vectors[a.heading];if not d then return end
    local cx,cy=(a.x1+a.x2+1)/2,(a.y1+a.y2+1)/2
    local x=isoToScreenX(self.player,cx,cy,0)-getPlayerScreenLeft(self.player)
    local y=isoToScreenY(self.player,cx,cy,0)-getPlayerScreenTop(self.player)
    local texture=getTexture('media/textures/TSBAstroluxFacing'..a.heading..'.png')
    local size=quiet and 64 or 88
    if texture then self:drawTextureScaled(texture,x-size/2,y-size/2,size,size,1,1,1,1)end
    if not quiet then self:drawText('Vehicles face '..a.heading,x+size/2,y,1,.9,.2,1,UIFont.Small)end
end
-- Finish the mouse dispatch before removing the full-screen selector.
function Cursor:review(area,complete)
 if self.closed then return end
 self.viewArea=area
 if complete then self.pendingReview={area=area,complete=complete} end
end
function Cursor:update()
 local pending=self.pendingReview
 if not pending or self.closed then return end
 local area,complete=pending.area,pending.complete
 self:cancel(true)
 local text='Save this delivery zone? <LINE> From '..area.x1..', '..area.y1..' to '..area.x2..', '..area.y2..
  ' <LINE> Vehicles face '..area.heading..'; minimum gap '..tostring(area.gap or 0)..' tiles; between rows '..tostring(area.rowGap or area.gap or 0)..' tiles.'
 local submitted=false
 local modal=ISModalRichText:new(100,100,620,220,text,true,nil,function(_,button)
  if button.internal=='YES' and not submitted then
   submitted=true;self:finishSelection();complete(area.x1,area.y1,area.x2,area.y2)
  else self:finishSelection() end
 end,self.player)
 modal:initialise();modal:addToUIManager();modal:bringToTop()
end
function Cursor:drawParking(a)
 if not self.script then
  self:drawText('Choose a vehicle in Vehicles to preview parking spaces.',20,65,1,.85,.3,1,UIFont.Small);return
 end
 local cx,cy=math.floor(self.character:getX()),math.floor(self.character:getY())
 local key=table.concat({a.x1,a.y1,a.x2,a.y2,a.heading,a.gap or 0,a.rowGap or a.gap or 0,cx,cy,self.script},':')
 if self.planKey~=key then
  self.planKey=key
  local ok,slots,limited=pcall(function()
   local script=getScriptManager():getVehicle(self.script)
   local region={x1=a.x1,y1=a.y1,x2=a.x2,y2=a.y2}
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
 local text=self.planError and 'Vehicle geometry unavailable.' or ('Parking preview: '..self.script..' | gap '..tostring(a.gap or 0)..' tiles | '..#self.parking..' spaces')
 if self.limited then text=text..' (preview limit)' end
 self:drawText(text,20,45,1,1,1,1,UIFont.Small)
 self:drawText('Illustrative layout; actual deliveries recheck vehicles and obstructions. Right-click / Escape cancels.',20,65,1,.85,.3,1,UIFont.Small)
end

function Cursor.drawEmbedded(panel,area,script)
 local index=panel.player:getPlayerNum()
 local ox=panel:getAbsoluteX()-getPlayerScreenLeft(index)
 local oy=panel:getAbsoluteY()-getPlayerScreenTop(index)
 local view=panel.zoneParkingPreview or {};panel.zoneParkingPreview=view
 view.player=index;view.character=panel.player;view.script=script
 view.drawText=function()end
 view.drawLine=function(_,texture,x1,y1,x2,y2,...)panel:drawLine(texture,x1-ox,y1-oy,x2-ox,y2-oy,...)end
 view.drawTextureScaled=function(_,texture,x,y,w,h,...)panel:drawTextureScaled(texture,x-ox,y-oy,w,h,...)end
 view.drawFacingArrow=Cursor.drawFacingArrow
 Cursor.drawParking(view,area)
 Cursor.drawFacingArrow(view,area,true)
 return view.planError,view.parking and #view.parking or 0,view.limited
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
    local area=self.editArea and not self.ax and self.editArea or self:draft(x,y)
    if not area then return end
    addAreaHighlightForPlayer(self.player,area.x1,area.y1,area.x2+1,area.y2+1,0,0.1,0.9,0.8,0.5)
    self:drawFacingArrow(area);self:drawParking(area)
    self:drawText(self.editArea and 'Edit saved zone: drag a corner to resize, inside to move, or outside to redraw. Release to review; Escape cancels.' or 'Drag between opposite corner tiles. Release to review; Escape cancels.',20,20,1,1,1,1,UIFont.Small)
end
Events.OnKeyPressed.Add(function(key) if active and key==Keyboard.KEY_ESCAPE then active:cancel() end end)
return Cursor
