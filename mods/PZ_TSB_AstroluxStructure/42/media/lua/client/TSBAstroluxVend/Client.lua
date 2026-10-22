require 'ISUI/ISModalDialog'
require 'ISUI/ISRichTextPanel'
require 'ISUI/ISModalRichText'
require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISComboBox'
require 'ISUI/ISTextEntryBox'
require 'ISUI/ISTextBox'
require 'Vehicles/ISUI/ISUI3DScene'
local Preview=require 'TSBAstroluxVend/Preview'
local AdminPricing=require 'TSBAstroluxVend/AdminPricing'

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
    return {x=sq:getX(),y=sq:getY(),z=sq:getZ(),index=obj:getObjectIndex()}
end
local function request(self,command)
    local a={};for k,v in pairs(self.location) do a[k]=v end
    local offer=self.offers and self.offers[self.selection.selected]
    a.paint=self.paintOptions and self.paintOptions[self.paint.selected] and self.paintOptions[self.paint.selected].id
    a.offer=offer and offer.id;a.token=self.quote and self.quote.token
    a.search=self.query or '';a.page=self.page or 1
    a.payment=self.paymentIDs and self.paymentIDs[self.payment.selected] or 'cash'
    self.quote=nil;self.confirm:setEnable(false)
    send(self.player,command,a)
end
function Panel:createChildren()
    ISPanel.createChildren(self)
    self.adminButton=ISButton:new(300,12,205,26,'Admin pricing',self,function(s)
        if not s.adminPricing then return end
        if s.pricePanel then s.pricePanel:removeFromUIManager()end
        local offer=s.offers and s.offers[s.selection.selected]
        s.pricePanel=AdminPricing.open(s.adminPricing,offer,function(a)
            for k,v in pairs(s.location)do a[k]=v end
            a.search=s.query or '';a.page=s.page or 1
            s.quote=nil;s.confirm:setEnable(false)
            send(s.player,'setPrices',a)
        end)
    end)
    self.adminButton:initialise();self.adminButton:setVisible(false);self:addChild(self.adminButton)
    self.search=ISTextEntryBox:new('',15,85,370,28);self.search:initialise();self:addChild(self.search)
    local searchButton=ISButton:new(390,85,115,28,'Search',self,function(s)
        s.query=s.search:getText();s.page=1;request(s,'open')
    end);searchButton:initialise();self:addChild(searchButton)
    self.selection=ISComboBox:new(15,120,490,28,self,function(s)
        s.quote=nil;s.confirm:setEnable(false)
        if s.preview then s:updatePaint();s:updatePreview() end
    end)
    self.selection:initialise();self:addChild(self.selection)
    local function button(y,label,callback)
        local b=ISButton:new(15,y,490,28,label,self,callback);b:initialise();self:addChild(b);return b
    end
    self.getQuote=button(200,'Get price quote',function(s)request(s,'quote')end)
    self.confirm=button(235,'Confirm purchase',function(s)request(s,'buy')end)
    self.confirm:setEnable(false)
    button(270,'Refresh / check order',function(s)request(s,'open')end)
    button(305,'Retry recorded delivery (after clearing/loading area)',function(s)request(s,'deliver')end)
    button(425,'Close',function(s)s:close()end)
    self.payment=ISComboBox:new(15,550,490,28,self,function(s)s.quote=nil;s.confirm:setEnable(false)end)
    self.payment:initialise();self.payment:addOption('Pay with carried cash');self.paymentIDs={'cash'};self:addChild(self.payment)
    self.paint=ISComboBox:new(15,160,490,28,self,function(s)
        s.quote=nil;s.confirm:setEnable(false);s:updatePreview()
    end)
    self.paint:initialise();self.paint:addOption('Factory appearance');self:addChild(self.paint)
    self.scene=ISUI3DScene:new(530,85,320,250);self.scene:initialise();self.scene:instantiate();self:addChild(self.scene)
    self.preview=Preview.new(self.scene);self.preview.enabled=Client.previewEnabled~=false
    local toggle=ISButton:new(530,370,320,28,'Toggle 3D preview',self,function(s)
        s.preview.enabled=not s.preview.enabled;Client.previewEnabled=s.preview.enabled;s:updatePreview()
    end);toggle:initialise();self:addChild(toggle)
    local prev=ISButton:new(530,425,155,28,'Previous page',self,function(s)s.page=math.max(1,(s.page or 1)-1);request(s,'open')end)
    prev:initialise();self:addChild(prev)
    local nextPage=ISButton:new(695,425,155,28,'Next page',self,function(s)s.page=math.min(s.pages or 1,(s.page or 1)+1);request(s,'open')end)
    nextPage:initialise();self:addChild(nextPage)
end
function Panel:updatePaint()
    local offer=self.offers and self.offers[self.selection.selected]
    local old=self.paintOptions and self.paintOptions[self.paint.selected]
    local keep=old and self.paintScript== (offer and offer.script) and old.id
    self.paintScript=offer and offer.script
    self.paintOptions=offer and offer.paintOptions
    self.paint:clear()
    for i,o in ipairs(self.paintOptions or {})do
        self.paint:addOption(o.id=='factory' and 'Factory Color' or (o.label..(o.surcharge>0 and (' - special +$'..o.surcharge) or ' - included')))
        if keep==o.id then self.paint.selected=i end
    end
    if not self.paintOptions then self.paint:addOption('Factory appearance')end
end
function Panel:updatePreview()
    local offer=self.offers and self.offers[self.selection.selected]
    local paint=self.paintOptions and self.paintOptions[self.paint.selected]
    self.preview:show(offer)
    -- Keep geometry visible while being explicit about unsupported paint rendering.
    if offer and paint and paint.id~='factory' and self.preview.enabled and self.preview.script==offer.script then
        self.preview.status='Factory appearance shown. Selected paint: '..paint.label..'.'
    end
    self.getQuote:setEnable(offer~=nil and offer.available~=false)
    self.priceInfo=offer and offer.pricing
    local rx,ry=offer and offer.rx or 0,offer and offer.ry or 0
    if (self.areaRotation or 0)%2==1 then rx,ry=ry,rx end
    self.requiredArea=offer and ('Clear area: '..(rx*2+1)..' x '..(ry*2+1)..' tiles') or ''
end
function Panel:close()
    if self.tradePanel then self.tradePanel:removeFromUIManager()end
    if self.pricePanel then self.pricePanel:removeFromUIManager()end
    if self.preview then self.preview:clear() end
    self:removeFromUIManager();if panel==self then panel=nil end
end
function Panel:prerender()
    ISPanel.prerender(self)
    self:drawText('Astrolux Motors',15,12,1,1,1,1,UIFont.Medium)
    self:drawText('Cash: $'..tostring(self.balance or '?')..(self.simple and (' | Bank: '..(self.bankAvailable and ('$'..tostring(self.bankBalance)) or 'unavailable')) or ''),15,43,1,1,1,1,UIFont.Small)
    self:drawText(self.areaText or 'Spawn area: not configured',15,63,0.8,0.8,0.8,1,UIFont.Small)
    -- Wrap messages to the actual panel width, including long native errors.
    self:drawText('Vehicles: '..tostring(self.total or 0)..' | Page '..tostring(self.page or 1)..' / '..tostring(self.pages or 1),530,15,1,1,1,1,UIFont.Small)
    self:drawText(self.requiredArea or '',530,45,0.8,0.8,0.8,1,UIFont.Small)
    self:drawText(self.preview.status or '',530,345,0.8,0.8,0.8,1,UIFont.Small)
    local price=self.priceInfo
    if price then
        self:drawText(price.class..' | '..(price.dynamic==false and 'Static' or 'Demand')..' | 100% condition',530,65,0.8,0.8,0.8,1,UIFont.Small)
        self:drawText(price.baseTotal and ('Base $'..price.baseTotal..' + demand $'..price.demandMarkup) or (price.fixed and ('Fixed total $'..price.total) or ('Base $'..price.base..' + equipment $'..price.addons)),530,402,0.8,0.8,0.8,1,UIFont.Small)
    end
    local line,y='',345
    for word in tostring(self.message or ''):gmatch('%S+') do
        local nextLine=line=='' and word or line..' '..word
        if getTextManager():MeasureStringX(UIFont.Small,nextLine)>485 then
            self:drawText(line,15,y,1,0.9,0.7,1,UIFont.Small);y=y+16;line=word
        else line=nextLine end
    end
    self:drawText(line,15,y,1,0.9,0.7,1,UIFont.Small)
    self:drawText('VEHICLE SPAWN AREA - KEEP A FITTING SPACE CLEAR',15,595,1,0.85,0.35,1,UIFont.Small)
    self:drawText('Owners: keep the displayed clear area outdoors and free of buildings, furniture and parked cars.',15,613,1,0.9,0.7,1,UIFont.Small)
    self:drawText('Move purchased vehicles out of the spawn area to make room for later deliveries.',15,631,1,0.9,0.7,1,UIFont.Small)
end
function Client.receive(data)
    if data.areaSaved then if requester then requester:Say(data.message) end;return end
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
    panel.quote=data.quote
    panel.confirm:setEnable(data.ok and data.quote~=nil)
    if data.quote then panel.confirm:setTitle('Confirm purchase — $'..data.quote.price)
    else panel.confirm:setTitle('Confirm purchase') end
    if not data.ok then return end
    panel.adminPricing=data.adminPricing
    panel.adminButton:setVisible(data.adminPricing~=nil)
    panel.simple=data.simple;panel.bankAvailable=data.bankAvailable;panel.bankBalance=data.bankBalance
    local selected=panel.paymentIDs[panel.payment.selected]
    panel.paymentIDs=data.paymentMethods or {'cash'};panel.payment:clear()
    for i,id in ipairs(panel.paymentIDs)do
        panel.payment:addOption(id=='bank' and 'Pay from server bank account' or 'Pay with carried cash')
        if id==selected then panel.payment.selected=i end
    end
    if panel.tradePanel then panel.tradePanel:removeFromUIManager();panel.tradePanel=nil end
    selectedTerminal=data.terminal
    panel.balance=data.balance
    panel.page=data.page or 1;panel.pages=data.pages or 1;panel.total=data.total or 0
    local area=data.spawnArea
    panel.spawnArea=area
    panel.areaRotation=area and (area.heading=='E' or area.heading=='W') and 1 or 0
    panel.areaText=area and ('Spawn area: '..area.x1..', '..area.y1..' to '..area.x2..', '..area.y2..' | Faces '..area.heading) or 'Spawn area: not configured'
    local old=panel.offers and panel.offers[panel.selection.selected]
    panel.offers=data.offers;panel.selection:clear()
    for i,o in ipairs(data.offers) do
        local translated=o.script and getTextOrNull('IGUI_VehicleName'..(o.script:match('%.(.+)$') or o.script))
        panel.selection:addOption((translated or o.name)..' - $'..o.price..(o.available==false and ' (too large)' or ''))
        if old and old.id==o.id then panel.selection.selected=i end
    end
    panel:updatePaint();panel:updatePreview()
    if data.order and data.order.status~='delivered' then
        panel.message=panel.message..' Order '..data.order.id..': '..data.order.status..'.'
    end
end
local function open(p,obj,command)
    if panel then panel:close() end
    panel=Panel:new(30,20,870,660)
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
    local isAdmin=not isClient() or tostring(p:getAccessLevel()):lower()=='admin'
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
                context:addOption('Astrolux Motors',p,function()open(p,obj,'open')end)
            end
        end
    end
    -- Native hit tests can return glass/floor instead of the fixture behind it.
    for _,candidate in ipairs(candidates)do
        local target=candidate
        if not seen[target] and FixtureTargets.isKiosk(target)then
            seen[target]=true
            if target:getModData().TSBAstroluxVend then
                context:addOption('Astrolux Motors',p,function()open(p,target,'open')end)
            else
                local option=context:addOption('Astrolux Motors kiosk: administrator setup required')
                option.notAvailable=true
            end
        end
    end
    if isAdmin and ground and selectedTerminal then
        local option=context:addOption('Astrolux Motors admin: drag vehicle spawn area')
        local sub=ISContextMenu:getNew(context);context:addSubMenu(option,sub)
        local terminalID=selectedTerminal
        for _,heading in ipairs(Areas.directions) do
            local direction=heading
            sub:addOption('Vehicles face '..direction,p,function()
                local Cursor=require 'TSBAstroluxVend/AreaCursor'
                requester=p
                if panel then panel:close();panel=nil end
                Cursor:start(p,direction,function(ax,ay,bx,by)
                    send(p,'areaSet',{terminal=terminalID,ax=ax,ay=ay,bx=bx,by=by,heading=direction,confirmed=true})
                end)
            end)
            sub:addOption('Enter remote corners; face '..direction,p,function()
                requester=p
                local modal=ISTextBox:new(100,100,620,230,
                    'Enter two opposite corner tiles: x1, y1, x2, y2. No size or kiosk-distance limit. Vehicles face '..direction,
                    '',nil,function(_,button)
                        if button.internal~='OK' then return end
                        local text=button.parent.entry:getText()
                        local values={}
                        for value in text:gmatch('[^,%s]+') do values[#values+1]=tonumber(value) or false end
                        if #values~=4 then p:Say('Enter four whole tile coordinates separated by commas.');return end
                        local area,why=Areas.rectangle(values[1],values[2],values[3],values[4],direction)
                        if not area then p:Say(why);return end
                        send(p,'areaSet',{terminal=terminalID,ax=values[1],ay=values[2],bx=values[3],by=values[4],heading=direction,confirmed=true})
                    end,p:getPlayerNum())
                modal:initialise();modal:addToUIManager()
            end)
        end
    end
end)
