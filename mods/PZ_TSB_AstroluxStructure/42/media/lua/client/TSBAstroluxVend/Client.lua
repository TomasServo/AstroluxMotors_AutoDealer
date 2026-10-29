require 'TSBAstroluxStructure/ReleaseWorldMenu'
local Menus=require 'TSBAstroluxVend/ContextMenu'
require 'ISUI/ISModalDialog'
require 'ISUI/ISRichTextPanel'
require 'ISUI/ISModalRichText'
require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISComboBox'
require 'ISUI/ISTextEntryBox'
require 'ISUI/ISTickBox'
require 'ISUI/ISTextBox'
require 'Vehicles/ISUI/ISUI3DScene'

require 'ISUI/ISScrollingListBox'
local TradeSelection=require 'TSBAstroluxVend/TradeSelection'
local Access=require 'TSBAstroluxVend/AdminAccess'
local C=require 'TSBAstroluxVend/Config'
local FixtureTargets=require 'TSBAstroluxVend/FixtureTargets'
local Areas=require 'TSBAstroluxVend/SpawnAreas'
TSBAstroluxVendClient={}
local Client=TSBAstroluxVendClient
local Panel=ISPanel:derive('TSBAstroluxVendPanel')
local panel,selectedTerminal,requester
local function send(p,command,args)
    requester=p
    if isClient() then sendClientCommand(p,C.channel,command,args)
    elseif TSBAstroluxVendServer then TSBAstroluxVendServer.handle(p,command,args) end
end
local function argsFor(obj)
    local sq=obj:getSquare()
    return {x=sq:getX(),y=sq:getY(),z=sq:getZ(),index=obj:getObjectIndex(),kioskId=obj:getModData().TSBAstroluxVend}
end
local function request(self,command)
    local a={};for k,v in pairs(self.location) do a[k]=v end
    local offer=self.offers and self.offers[self.selection.selected]
    a.configuration=self:getConfiguration()
    a.equipment=self:getEquipment()
    a.paint=self.paintOptions and self.paintOptions[self.paint.selected] and self.paintOptions[self.paint.selected].id
    a.offer=offer and offer.id;a.token=self.quote and self.quote.token
    a.tradeToken=self.tradeQuote and self.tradeQuote.token
    a.tradeVehicles=TradeSelection.ids(self)
    if command=='zoneNumber'then a.deliveryNumber=self.zoneNumber:isSelected(1)end
    if command=='zoneBorder'then a.deliveryBorder=self.zoneBorder:isSelected(1)end
    if command=='tradeQuote' or command=='tradeAccept'then self.tradeAccept:setEnable(false);self.tradeDecline:setEnable(false)end
    a.search=self.query or '';a.page=self.page or 1
    a.payment=self.paymentIDs and self.paymentIDs[self.payment.selected] or 'cash'
    self.quote=nil;self.confirm:setEnable(false)
    send(self.player,command,a)
end
require('TSBAstroluxVend/TabsUI').install(Panel,request,send,Client)
function Panel:close()
    if self.personalView then self.personalView:save()end
    if self.adminView then self.adminView:stopAudioPreviews()end
    if self.tradePanel then self.tradePanel:removeFromUIManager()end
    if self.preview then self.preview:clear() end
    self:removeFromUIManager();if panel==self then panel=nil end
end
function Client.receive(data)
    if data.ok and data.tradeSuccess and data.tradeSuccess~=Client.lastTradeSound then
        Client.lastTradeSound=data.tradeSuccess;require('TSBAstroluxVend/AudioSettings').playPurchase(panel and panel.player or requester)
    end
    if data.areaSaved then
        if panel then
            panel.displayNumber=data.displayNumber or panel.displayNumber;panel.deliveryNumber=data.deliveryNumber~=false;panel.spawnArea=data.spawnArea;panel.deliveryBorder=data.deliveryBorder==true;panel.message=data.message;panel.quote=nil;panel.confirm:setEnable(false)
            panel.tradeQuote=nil;panel.tradeRows:clear();panel.tradeAccept:setEnable(false);panel.tradeDecline:setEnable(false)
            panel:updateZone()
        elseif requester then requester:Say(data.message)end
        return
    end
    if not panel then if requester and data.message then requester:Say(data.message)end;return end
    panel.message=data.message
    if data.quote then
        for _,offer in ipairs(data.offers or {})do
            if offer.id==data.quote.offer and offer.pricing and offer.pricing.details~='' then
                panel.message=(panel.message or '')..' Included: '..offer.pricing.details
            end
        end
    end
    if data.quote and data.quote.paint then
        panel.message=(panel.message or '')..' Paint: '..data.quote.paint.label..
            (data.quote.paint.surcharge>0 and (' (+$'..data.quote.paint.surcharge..').') or ' (included).')
    end
    if data.quote and data.quote.configurationLabel then panel.message=(panel.message or '')..' Configuration: '..data.quote.configurationLabel end
    if data.quote and data.quote.equipmentLabel and data.quote.equipmentLabel~='' then panel.message=(panel.message or '')..' Accessories: '..data.quote.equipmentLabel end
    panel.quote=data.quote
    panel.confirm:setEnable(data.ok and data.quote~=nil)
    if data.quote then panel.confirm:setTitle('Confirm Purchase â€” $'..data.quote.price)
    else panel.confirm:setTitle('Confirm Purchase') end
    if not data.ok then TradeSelection.invalidate(panel);return end
    if not Access.allowed(panel.player)or data.adminAllowed==false then data.adminPricing=nil end
    panel.adminPricing=data.adminPricing
    panel.adminButton:setVisible(data.adminPricing~=nil)
    panel.zoneButton:setVisible(data.adminPricing~=nil)
    panel.simple=data.simple;panel.bankAvailable=data.bankAvailable;panel.bankBalance=data.bankBalance;panel.bankBalances=data.bankBalances or {}
    local selected=panel.paymentIDs[panel.payment.selected]
    panel.paymentIDs=data.paymentMethods or {'cash'};panel.payment:clear()
    for i,id in ipairs(panel.paymentIDs)do
        panel.payment:addOption((data.paymentLabels or {})[id] or (id~='cash' and 'Pay from bank account' or 'Pay with carried cash'))
        if id==selected then panel.payment.selected=i end
    end
    panel.bankBalance=panel.bankBalances[panel.paymentIDs[panel.payment.selected]] or panel.bankBalance
    if panel.tradePanel then panel.tradePanel:removeFromUIManager();panel.tradePanel=nil end
    TradeSelection.receive(panel,data)
    selectedTerminal=data.terminal
    panel.balance=data.balance
    panel.page=data.page or 1;panel.pages=data.pages or 1;panel.total=data.total or 0
    local area=data.spawnArea
    panel.adminPricing=data.adminPricing
    panel.displayNumber=data.displayNumber or panel.displayNumber;panel.deliveryNumber=data.deliveryNumber~=false;panel.spawnArea=area;panel.deliveryBorder=data.deliveryBorder==true;panel.zoneTerminal=data.terminal;panel:updateZone()
    panel.areaRotation=area and (area.heading=='E' or area.heading=='W') and 1 or 0
    panel.areaText=area and ('Spawn area: '..area.x1..', '..area.y1..' to '..area.x2..', '..area.y2..' | Faces '..area.heading) or 'Spawn area: not configured'
    local old=panel.offers and panel.offers[panel.selection.selected]
    panel.offers=data.offers;panel.selection:clear()
    for i,o in ipairs(data.offers) do
        local model=o.modelScript or o.script
        local translated=model and getTextOrNull('IGUI_VehicleName'..(model:match('%.(.+)$') or model))
        panel.selection:addOption((translated or o.name)..' - $'..o.price..(o.available==false and ' (too large)' or ''))
        if old and old.id==o.id then panel.selection.selected=i end
    end
    panel:updateConfiguration();panel:updatePaint();panel:updatePreview();panel:updateAdmin(data.adminPricing)
    if data.order and data.order.status~='delivered' then
        panel.message=panel.message..' Order '..data.order.id..': '..data.order.status..'.'
    end
end
local function open(p,obj,command)
    if panel then panel:close() end
    panel=Panel:new(30,20,990,755)
    panel.player=p;panel.location=argsFor(obj)
    panel:initialise();panel:addToUIManager();panel.moveWithMouse=true
    send(p,command,panel.location)
end
-- Use the native object-click route so selecting a kiosk consumes the world click.
local function installKioskLeftClick()
    if not ISObjectClickHandler or ISObjectClickHandler.TSBAstroluxKioskLeftClick then return end
    local previous=ISObjectClickHandler.doClickSpecificObject
    ISObjectClickHandler.doClickSpecificObject=function(obj,playerNum,p,...)
        local sprite=obj and obj:getSprite();local name=sprite and sprite:getName()
        if type(name)=='string' and name:match('^TSBAstroluxKiosk_[0-3]$')then
            local controls=UIManager.getSpeedControls()
            if p and not p:isDead() and p:getCurrentSquare() and not p:isAiming() and not p:isIgnoreContextKey()
                and not (controls and controls:getCurrentGameSpeed()==0)then
                if not obj:getModData().TSBAstroluxVend then
                    p:Say('This Astrolux Motors kiosk needs administrator setup. Right-click to designate a vehicle vendor.')
                    return true
                end
                local sq=obj:getSquare()
                if sq and p:getZ()==sq:getZ() and (p:getX()-sq:getX())^2+(p:getY()-sq:getY())^2<=9 then
                    open(p,obj,'open');return true
                end
                if p then p:Say('Stand within three tiles of the Astrolux Motors kiosk.')end
                return true
            end
        end
        return previous(obj,playerNum,p,...)
    end
    ISObjectClickHandler.TSBAstroluxKioskLeftClick=true
end
installKioskLeftClick()
Events.OnGameStart.Add(installKioskLeftClick)

Events.OnServerCommand.Add(function(module,command,data)
    if module==C.channel and command=='view' then Client.receive(data) end
end)
Events.OnFillWorldObjectContextMenu.Add(function(playerNum,context,objects,test)
    if test then return end
    local p=getSpecificPlayer(playerNum)
    if not p then return end
    local isAdmin=Access.allowed(p)
    local salesAdded=false
    local seen={};local candidates=FixtureTargets.collect(objects,getCell());local ground
    for _,obj in ipairs(objects) do
        local sq=obj:getSquare()
        if sq then
            ground=ground or sq
            if obj~=sq:getFloor() and obj:getSprite() and obj:getSprite():getName() and not seen[obj] then
                -- Candidate discovery includes nearby desktop fixtures.
            end
            if obj:getModData().TSBAstroluxVend and not seen[obj] then
                seen[obj]=true
                if not salesAdded then local menu=Menus.root(context);menu:addOption('Browse vehicles',p,function()open(p,obj,'open')end);salesAdded=true end
            end
        end
    end
    -- Native hit tests can return glass/floor instead of the fixture behind it.
    for _,candidate in ipairs(candidates)do
        local target=candidate
        if not seen[target] and FixtureTargets.isKiosk(target)then
            seen[target]=true
            if target:getModData().TSBAstroluxVend then
                if not salesAdded then local menu=Menus.root(context);menu:addOption('Browse vehicles',p,function()open(p,target,'open')end);salesAdded=true end
            else
                local option=Menus.root(context):addOption('Kiosk needs administrator setup')
                option.notAvailable=true
            end
        end
    end
    -- Delivery-zone creation/editing is available in the kiosk only.

end)
