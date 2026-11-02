-- Extend the native furniture pipeline only for Astrolux kiosks.
require 'Moveables/ISMoveableSpriteProps'
local F={}
function F.isKiosk(name) return type(name)=='string' and name:match('^TSBAstroluxKiosk_[0-3]$')~=nil end
local function blocked(obj)
    if not obj then return false end
    if not isClient() and TSBAstroluxVendServer then return TSBAstroluxVendServer.kioskPending(obj) end
    return obj:getModData().TSBAstroluxPending==true
end
local P=ISMoveableSpriteProps
local canPickup=P.canPickUpMoveable
function P:canPickUpMoveable(p,sq,obj)
    if F.isKiosk(self.spriteName) and blocked(obj) then return false end
    return canPickup(self,p,sq,obj)
end
local pickup=P.pickUpMoveableInternal
function P:pickUpMoveableInternal(p,sq,obj,instance,name,create,rotating)
    if not F.isKiosk(name) then return pickup(self,p,sq,obj,instance,name,create,rotating) end
    if blocked(obj) then if p then p:Say('Resolve the pending Astrolux delivery before picking up this kiosk.') end;return end
    local id=obj:getModData().TSBAstroluxVend
    local result=pickup(self,p,sq,obj,instance,name,create,rotating)
    if not isClient() and obj:getObjectIndex()<0 and TSBAstroluxVendServer then TSBAstroluxVendServer.kioskPacked(id) end
    return result
end
local place=P.placeMoveableInternal
function P:placeMoveableInternal(p,sq,item,name)
    if not F.isKiosk(name) then return place(self,p,sq,item,name) end
    if not isClient() then TSBAstroluxVendServer.kioskPreplace(item,sq) end
    local obj=place(self,p,sq,item,name)
    if obj and not isClient() then TSBAstroluxVendServer.kioskPlaced(obj) end
    return obj
end
-- A terminal must survive ordinary moves; never roll furniture breakage.
local breakTest=P.doBreakTest
function P:doBreakTest(p) if F.isKiosk(self.spriteName) then return false end;return breakTest(self,p) end
local scrap=P.canScrapObject
function P:canScrapObject(p) if F.isKiosk(self.spriteName) then return false end;return scrap(self,p) end
local scrapActual=P.scrapObject
function P:scrapObject(p) if F.isKiosk(self.spriteName) then return end;return scrapActual(self,p) end
local rotate=P.rotateMoveableInternal
function P:rotateMoveableInternal(p,sq,name)
    local result=rotate(self,p,sq,name)
    if F.isKiosk(name) and not isClient() then
        local list=sq:getObjects()
        for i=0,list:size()-1 do local obj=list:get(i)
            if obj:getModData().TSBAstroluxVend then TSBAstroluxVendServer.kioskPlaced(obj) end
        end
    end
    return result
end
-- The cursor uses rotateMoveable (pickup + replacement), including forced pickup.
local rotateCursor=P.rotateMoveable
function P:rotateMoveable(p,sq,name)
    if F.isKiosk(name) then
        local obj=self:findOnSquare(sq,name)
        if blocked(obj) then if p then p:Say('Resolve the pending Astrolux delivery before rotating this kiosk.') end;return end
    end
    return rotateCursor(self,p,sq,name)
end
return F
