function isoToScreenX(_,x,y)return (x-y)*32 end
function isoToScreenY(_,x,y)return (x+y)*16 end
ModData={getOrCreate=function()return {}end,add=function()end}
package.preload['RadioCom/ISUIRadio/ISSliderPanel']=function()end
package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;'..package.path
local function class()
    local c={}
    function c:derive() local child={};child.__index=child;setmetatable(child,{__index=self});return child end
    function c:new(...) local o={};setmetatable(o,{__index=self});return o end
    function c:setVisible(v)self.visible=v end
    function c:setCapture()end
    function c:addChild()end
    function c:initialise() end
    function c:addToUIManager() self.visible=true end
    function c:removeFromUIManager() self.visible=false end
    function c:bringToTop() end
    function c:drawText() end
    function c:drawLine() end
    return c
end
ISPanel=class()
for _,name in ipairs({'ISScrollingListBox','ISModalDialog','ISRichTextPanel','ISPanel','ISButton','ISComboBox','ISTextEntryBox','ISTextBox','ISTickBox'}) do
    package.preload['ISUI/'..name]=function() end
    _G[name]=_G[name] or class()
end
local confirmation
ISModalRichText=class()
function ISModalRichText:new(x,y,w,h,text,yesno,target,callback,player)
    local o=class().new(self);o.callback=callback;confirmation=o;return o
end
package.preload['ISUI/ISModalRichText']=function() end
package.preload['Vehicles/ISUI/ISUI3DScene']=function() end
local callbacks={}
Events=setmetatable({},{__index=function(t,k) local e={Add=function(fn) callbacks[k]=callbacks[k] or {};table.insert(callbacks[k],fn) end};t[k]=e;return e end})
function isClient() return false end
function isServer() return false end
function getSpecificPlayer()return nil end
-- Native server click handler is deliberately absent during client file load.
ISObjectClickHandler=nil
require 'TSBAstroluxVend/Client'
require 'TSBAstroluxVend/KioskClient'
local Cursor=require 'TSBAstroluxVend/AreaCursor'
assert(TSBAstroluxVendClient and TSBAstroluxKioskClient)
local original=function() return false end
ISObjectClickHandler={doClickSpecificObject=original}
for _,callback in ipairs(callbacks.OnGameStart) do callback() end
assert(ISObjectClickHandler.doClickSpecificObject~=original,'Kiosk click hook must attach after native load')
local sx,sy=0,0
function getTexture()return nil end
function getMouseX() return sx end
function getMouseY() return sy end
function screenToIsoX(_,x) return x end
function screenToIsoY(_,x,y) return y end
function getPlayerScreenLeft() return 0 end
function getPlayerScreenTop() return 0 end
function getPlayerScreenWidth() return 1920 end
function getPlayerScreenHeight() return 1080 end
Keyboard={KEY_ESCAPE=27};UIFont={Small=1}
function addAreaHighlightForPlayer() end
local player={getPlayerNum=function() return 0 end,Say=function() end}
local completed
local cursor=Cursor:start(player,'E',function(...) completed={...} end)
sx,sy=50,70;assert(cursor:onMouseDown())
sx,sy=10,20;cursor:prerender();assert(cursor:onMouseUp())
assert(not completed and cursor.pendingReview,'Mouse dispatch queues confirmation without mutation');cursor:update()
assert(not cursor.visible,'Selector closes before confirmation')
confirmation.callback(nil,{internal='YES'})
assert(completed[1]==10 and completed[2]==20 and completed[3]==50 and completed[4]==70)
completed=nil;cursor=Cursor:start(player,'N',function() completed=true end)
cursor:onMouseDown();cursor:onRightMouseDown();assert(not cursor.visible and not completed)
cursor=Cursor:start(player,'N',function() completed=true end)
for _,callback in ipairs(callbacks.OnKeyPressed) do callback(27) end
assert(not cursor.visible and not completed)
print('PASS: client modules load before native handlers, kiosk hook attaches later, reverse drag confirms corners, right-click/Escape cancel')
