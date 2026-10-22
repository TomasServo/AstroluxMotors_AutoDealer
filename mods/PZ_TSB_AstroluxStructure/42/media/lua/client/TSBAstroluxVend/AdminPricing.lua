require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISTextEntryBox'
require 'ISUI/ISComboBox'
require 'ISUI/ISTickBox'
local A=ISPanel:derive('AstroluxPriceAdmin')
function A:createChildren()
    ISPanel.createChildren(self)
    self.fields={}
    for i,key in ipairs({'normal','heavy','sports','price'})do
        local value=self.settings[key]
        if key=='price' then value=self.offer and (self.offer.basePrice or self.offer.price) or '' end
        local field=ISTextEntryBox:new(tostring(value),235,45+(i-1)*36,170,26)
        field:initialise();self:addChild(field);self.fields[key]=field
    end
    local function button(y,label,fn)
        local b=ISButton:new(15,y,390,28,label,self,fn);b:initialise();self:addChild(b);return b
    end
    button(235,'Save class prices',function(s)s:submit('classes')end)
    self.saveVehicle=button(270,'Set selected vehicle total',function(s)s:submit('vehicle')end)
    self.resetVehicle=button(305,'Remove selected vehicle override',function(s)s:submit('resetVehicle')end)
    self.saveVehicle:setEnable(self.offer~=nil);self.resetVehicle:setEnable(self.offer~=nil)
    self.staticPricing=ISTickBox:new(15,340,390,28,'AstroluxPricingMode',self,function(s)s:submit('mode')end)
    self.staticPricing:initialise();self.staticPricing:addOption('Static pricing (unchecked: demand)')
    self.staticPricing:setSelected(1,self.settings.dynamic==false);self:addChild(self.staticPricing)
    self.scripts=ISComboBox:new(15,435,390,28,self,nil)
    self.scripts:initialise();self:addChild(self.scripts)
    for _,script in ipairs(self.settings.scripts or {})do self.scripts:addOption(script)end
    local add=button(470,'Add / price installed vehicle',function(s)s:submit('addVehicle')end)
    add:setEnable(#(self.settings.scripts or {})>0)
    self.paintPrice=ISTextEntryBox:new(tostring(self.settings.specialPaint),235,510,170,26)
    self.paintPrice:initialise();self:addChild(self.paintPrice)
    button(545,'Save special paint surcharge',function(s)s:submit('paint')end)
    button(580,'Close' ,function(s)s:removeFromUIManager()end)
end
function A:submit(action)
    local args={action=action,revision=self.settings.revision,offer=self.offer and self.offer.id}
    for key,field in pairs(self.fields)do args[key]=tonumber(field:getText())end
    if action=='mode' then args.dynamic=not self.staticPricing:isSelected(1)end
    if action=='paint' then args.specialPaint=tonumber(self.paintPrice:getText())end
    if action=='addVehicle' then args.script=(self.settings.scripts or {})[self.scripts.selected]end
    self.send(args)
    self:removeFromUIManager()
end
function A:prerender()
    ISPanel.prerender(self)
    self:drawText('Astrolux Motors - Admin Pricing',15,12,1,1,1,1,UIFont.Medium)
    for i,label in ipairs({'Normal base','Heavy Duty base','Sports base','Selected vehicle total'})do
        self:drawText(label,15,49+(i-1)*36,1,1,1,1,UIFont.Small)
    end
    local name=self.offer and self.offer.script or 'Select a vehicle in the terminal first'
    self:drawText(string.sub(name,1,58),15,213,0.8,0.8,0.8,1,UIFont.Small)
    self:drawText('Installed vehicle: uses the total-price field above',15,410,1,1,1,1,UIFont.Small)
    self:drawText('Special paint extra ($)',15,514,1,1,1,1,UIFont.Small)
    self:drawText('World-wide prices. Vehicle totals override base + addons.',15,385,0.8,0.8,0.8,1,UIFont.Small)
end
function A.open(settings,offer,send)
    local p=A:new(80,30,430,625);p.settings=settings;p.offer=offer;p.send=send
    p:initialise();p:addToUIManager();p.moveWithMouse=true;return p
end
return A

