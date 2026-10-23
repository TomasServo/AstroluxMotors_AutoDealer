require 'ISUI/ISPanel'
require 'ISUI/ISModalRichText'
local A=require 'TSBAstroluxVend/SpawnAreas'
local Cursor=ISPanel:derive('TSBAstroluxSpawnAreaCursor')
local active
function Cursor:start(character,heading,complete)
    if active then active:cancel() end
    local index=character:getPlayerNum()
    local o=ISPanel:new(getPlayerScreenLeft(index),getPlayerScreenTop(index),getPlayerScreenWidth(index),getPlayerScreenHeight(index))
    setmetatable(o,self);self.__index=self
    o.player=index;o.character=character;o.heading=heading;o.complete=complete
    o.backgroundColor={r=0,g=0,b=0,a=0};o.borderColor={r=0,g=0,b=0,a=0}
    o:initialise();o:addToUIManager();o:bringToTop();active=o
    return o
end
-- Read-only viewer: reuse the native area highlight used by selection.
function Cursor:showZone(character,area)
    local o=self:start(character,area.heading,nil)
    o.viewArea=area
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
    local area,why=A.rectangle(self.ax,self.ay,bx,by,self.heading)
    if not area then self.character:Say(why);return true end
    local ax,ay=self.ax,self.ay;local complete=self.complete;local player=self.player
    self:cancel()
    local text='Use this vehicle spawn area? <LINE> Corners: '..area.x1..', '..area.y1..' to '..area.x2..', '..area.y2..
        '. <LINE> Size: '..(area.x2-area.x1+1)..' x '..(area.y2-area.y1+1)..' tiles. Vehicles face '..area.heading..
        '. <LINE> The area may be anywhere. Remote purchases queue until a clear space is loaded.'
    local modal=ISModalRichText:new(100,100,620,260,text,true,nil,function(_,button)
        if button.internal=='YES' then complete(ax,ay,bx,by) end
    end,player)
    modal:initialise();modal:addToUIManager()
    return true
end
function Cursor:onMouseUpOutside() return self:onMouseUp() end
function Cursor:onRightMouseDown() self:cancel();return true end
function Cursor:cancel() self:removeFromUIManager();if active==self then active=nil end end
function Cursor:drawFacingArrow(a)
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
    self:drawText('Vehicles face '..a.heading,x2+12,y2,1,0.9,0.2,1,UIFont.Small)
end
function Cursor:prerender()
    if self.viewArea then
        local a=self.viewArea
        addAreaHighlightForPlayer(self.player,a.x1,a.y1,a.x2+1,a.y2+1,0,0.1,0.9,0.8,0.5)
        self:drawFacingArrow(a)
        self:drawText('Delivery Zone: '..a.x1..', '..a.y1..' to '..a.x2..', '..a.y2..' | Vehicles face '..tostring(a.heading),20,20,1,1,1,1,UIFont.Small)
        self:drawText('Ground floor highlight. Remote zones are visible when nearby. Right-click / Escape closes.',20,45,1,1,1,1,UIFont.Small)
        return
    end
    local x,y=self:point()
    local ax,ay=self.ax or x,self.ay or y
    addAreaHighlightForPlayer(self.player,math.min(ax,x),math.min(ay,y),math.max(ax,x)+1,math.max(ay,y)+1,0,0.1,0.9,0.8,0.5)
    self:drawFacingArrow({x1=math.min(ax,x),y1=math.min(ay,y),x2=math.max(ax,x),y2=math.max(ay,y),heading=self.heading})
    self:drawText('Astrolux spawn area: drag from one corner tile to the opposite corner. Right-click / Escape cancels.',20,20,1,1,1,1,UIFont.Small)
end
Events.OnKeyPressed.Add(function(key) if active and key==Keyboard.KEY_ESCAPE then active:cancel() end end)
return Cursor
