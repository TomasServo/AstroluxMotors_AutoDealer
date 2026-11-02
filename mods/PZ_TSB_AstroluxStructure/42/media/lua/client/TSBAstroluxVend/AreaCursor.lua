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
function Cursor:point()
    return math.floor(screenToIsoX(self.player,getMouseX(),getMouseY(),0)),math.floor(screenToIsoY(self.player,getMouseX(),getMouseY(),0))
end
function Cursor:onMouseDown()
    self.ax,self.ay=self:point();return true
end
function Cursor:onMouseUp()
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
function Cursor:prerender()
    local x,y=self:point()
    local ax,ay=self.ax or x,self.ay or y
    addAreaHighlightForPlayer(self.player,math.min(ax,x),math.min(ay,y),math.max(ax,x)+1,math.max(ay,y)+1,0,0.1,0.9,0.8,0.5)
    self:drawText('Astrolux spawn area: drag from one corner tile to the opposite corner. Right-click / Escape cancels.',20,20,1,1,1,1,UIFont.Small)
end
Events.OnKeyPressed.Add(function(key) if active and key==Keyboard.KEY_ESCAPE then active:cancel() end end)
return Cursor
