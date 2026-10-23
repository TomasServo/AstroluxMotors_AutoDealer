require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISTextEntryBox'
require 'ISUI/ISComboBox'
require 'ISUI/ISTickBox'
require 'RadioCom/ISUIRadio/ISSliderPanel'
local Groups=require 'TSBAstroluxVend/AdminVehicleGroups'
local PreviewAudio=require 'TSBAstroluxVend/AudioPreview'
local A=ISPanel:derive('AstroluxPriceAdmin')
function A:addControl(page,w)
 w:initialise();self:addChild(w);self.groups[page][#self.groups[page]+1]=w;return w
end
function A:stopAudioPreviews() PreviewAudio.stopAll()end
function A:showPage(page)
 if page~='sounds'then self:stopAudioPreviews()end
 self.page=page
 for key,items in pairs(self.groups)do for _,w in ipairs(items)do w:setVisible(key==page)end end
end
function A:createChildren()
 ISPanel.createChildren(self);self.groups={prices={},vehiclePrices={},equipment={},buybacks={},sounds={}};self.fields={}
 local function button(page,x,y,w,label,fn)return self:addControl(page,ISButton:new(x,y,w,28,label,self,fn))end
 local function field(page,x,y,text)return self:addControl(page,ISTextEntryBox:new(tostring(text),x,y,160,26))end
 local function tick(page,x,y,name,label,fn)local t=self:addControl(page,ISTickBox:new(x,y,400,28,name,self,fn));t:addOption(label);return t end
 local prices=ISButton:new(10,5,180,28,'Prices and catalog',self,function(s)s:showPage('prices')end);prices:initialise();self:addChild(prices)
 local equipment=ISButton:new(200,5,220,28,'Accessory settings',self,function(s)s:showPage('equipment')end);equipment:initialise();self:addChild(equipment)
 local buybacks=ISButton:new(430,5,180,28,'Buybacks',self,function(s)s:showPage('buybacks')end);buybacks:initialise();self:addChild(buybacks)
 local sounds=ISButton:new(810,5,110,28,'Sounds',self,function(s)s:showPage('sounds')end);sounds:initialise();self:addChild(sounds)
 local audio=self.settings.audio or {}
 self.purchaseSound=tick('sounds',10,70,'AstroluxPurchaseSound','Purchase button / trade-in sound',nil);self.purchaseSound:setSelected(1,audio.purchaseSound~=false)
 self.showroomMusic=tick('sounds',10,120,'AstroluxShowroomMusic','Showroom music',nil);self.showroomMusic:setSelected(1,audio.showroomMusic~=false)
 self.purchaseVolume=self:addControl('sounds',ISSliderPanel:new(410,70,270,28,self,function(_,value)PreviewAudio.level('purchase',value)end));self.purchaseVolume:setValues(0,100,1,10);self.purchaseVolume:setCurrentValue(audio.purchaseVolume or 50,true)
 self.musicVolume=self:addControl('sounds',ISSliderPanel:new(410,120,270,28,self,function(_,value)PreviewAudio.level('music',value)end));self.musicVolume:setValues(0,100,1,10);self.musicVolume:setCurrentValue(audio.musicVolume or 10,true)
 button('sounds',745,70,75,'Play',function(s)PreviewAudio.play('purchase',s.purchaseVolume:getCurrentValue())end)
 button('sounds',830,70,75,'Pause',function()PreviewAudio.pause('purchase')end)
 button('sounds',745,120,75,'Play',function(s)PreviewAudio.play('music',s.musicVolume:getCurrentValue())end)
 button('sounds',830,120,75,'Pause',function()PreviewAudio.pause('music')end)
 button('sounds',10,185,550,'Save sound settings',function(s)s:submit('audio')end)
 self.buybacksEnabled=tick('buybacks',10,55,'AstroluxBuybacks','Enable vehicle buybacks',nil);self.buybacksEnabled:setSelected(1,self.settings.buybacksEnabled==true)
 self.buybackPercent=field('buybacks',400,110,self.settings.buybackPercent)
 self.damagePercent=field('buybacks',400,160,self.settings.damagePercent)
 self.minimumBuybackParts=field('buybacks',400,210,self.settings.minimumBuybackParts)
 self.requireBuybackKey=tick('buybacks',10,255,'AstroluxBuybackKey','Require matching carried key',nil);self.requireBuybackKey:setSelected(1,self.settings.requireBuybackKey~=false)
 self.excludeBuybackBattery=tick('buybacks',10,290,'AstroluxBuybackBattery','Exclude battery from installed-parts count',nil);self.excludeBuybackBattery:setSelected(1,self.settings.excludeBuybackBattery~=false)
 self.allowHotwiredBuybacks=tick('buybacks',470,255,'AstroluxHotwiredBuybacks','Allow hotwired vehicle trade-ins',nil);self.allowHotwiredBuybacks:setSelected(1,self.settings.allowHotwiredBuybacks~=false)
 button('buybacks',10,340,550,'Save buyback policy',function(s)s:submit('buybacks')end)
 local vehiclePrices=ISButton:new(620,5,180,28,'Vehicle prices',self,function(s)s:showPage('vehiclePrices')end);vehiclePrices:initialise();self:addChild(vehiclePrices)
 for i,key in ipairs({'normal','heavy','sports','price'})do
  local value=self.settings[key];if key=='price'then value=self.offer and (self.offer.basePrice or self.offer.price) or ''end
  self.fields[key]=field('prices',190,55+(i-1)*38,value)
 end
 button('prices',10,215,340,'Save class prices',function(s)s:submit('classes')end)
 local selected=button('prices',10,250,340,'Set selected vehicle price',function(s)s:submit('vehicle')end);selected:setEnable(self.offer~=nil)
 local reset=button('prices',10,285,340,'Remove selected price override',function(s)s:submit('resetVehicle')end);reset:setEnable(self.offer~=nil)
 self.staticPricing=tick('prices',10,325,'AstroluxPricingMode','Static pricing (unchecked: demand)',function(s)s:submit('mode')end);self.staticPricing:setSelected(1,self.settings.dynamic==false)
 self.paintPrice=field('prices',650,55,self.settings.specialPaint)
 button('prices',440,95,370,'Save special paint surcharge',function(s)s:submit('paint')end)
 self.addonBuffs=tick('prices',440,140,'AstroluxAddonBuffs','Enable added accessory buffs',function(s)s:submit('buffs')end);self.addonBuffs:setSelected(1,self.settings.addonBuffs~=false)
 self.vehicleGroups=Groups.build(self.settings.scripts,self.settings.scriptLabels)
 self.scripts=self:addControl('vehiclePrices',ISComboBox:new(10,65,420,28,self,function(s)s:refreshPriceVariations()end))
 self.scriptVariations=self:addControl('vehiclePrices',ISComboBox:new(450,65,440,28,self,function(s)s:refreshVehicleAvailability()end))
 for _,group in ipairs(self.vehicleGroups)do self.scripts:addOption(group.label)end
 self:refreshPriceVariations(self.keepPriceScript or (self.offer and self.offer.script))
 self.addPrice=field('vehiclePrices',450,240,'')
 self.modelPrice=field('vehiclePrices',450,130,'')
 local add=button('vehiclePrices',10,280,420,'Set price for this variation',function(s)s:submit('variantPrice')end);add:setEnable(#(self.settings.scripts or {})>0)
 button('vehiclePrices',10,170,880,'Apply blanket price to ALL variants (resets variant overrides)',function(s)s:submit('modelPrice')end)
 button('vehiclePrices',450,280,440,'Clear variant override / use model price',function(s)s:submit('resetVariant')end)
 self.offerVehicle=tick('vehiclePrices',10,330,'AstroluxVehicleAvailability','Offer this vehicle variation',function(s)s:submit('availability')end)
 self:refreshVehicleAvailability()
 self.equipmentScripts=self:addControl('equipment',ISComboBox:new(10,65,420,28,self,function(s)s:refreshEquipmentVariations()end))
 self.equipmentVariations=self:addControl('equipment',ISComboBox:new(450,65,440,28,self,function(s)s:refreshEquipment()end))
 for _,group in ipairs(self.vehicleGroups)do self.equipmentScripts:addOption(group.label)end
 self.equipmentScriptIDs=Groups.select(self.vehicleGroups,self.equipmentScripts,self.equipmentVariations,self.keepScript or (self.offer and self.offer.script))
 self.equipmentChoice=self:addControl('equipment',ISComboBox:new(10,120,420,28,self,function(s)s:refreshPolicy()end))
 self.equipmentEnabled=tick('equipment',10,170,'AstroluxEquipmentAvailability','Offer this accessory for this vehicle',nil)
 self.equipmentPrice=field('equipment',650,170,0)
 self.equipmentBuff=tick('equipment',10,220,'AstroluxEquipmentBuff','Enable added storage bonus',nil)
 self.equipmentBonus=field('equipment',650,220,0)
 self.saveEquipment=button('equipment',10,330,800,'Save accessory availability, price and added buff',function(s)s:submit('accessory')end)
 self:refreshEquipment();self:showPage(self.keepPage or 'prices')
end
function A:refreshPriceVariations(wanted)
 self.priceScriptIDs=Groups.select(self.vehicleGroups,self.scripts,self.scriptVariations,wanted)
 if self.offerVehicle then self:refreshVehicleAvailability()end
end
function A:refreshVehicleAvailability()
 local script=self.priceScriptIDs[self.scriptVariations.selected]
 self.offerVehicle.enable=script~=nil
 self.offerVehicle:setSelected(1,script~=nil and (self.settings.vehicleAvailability or {})[script]==true)
 if self.modelPrice then self.modelPrice:setText(tostring(script and (self.settings.modelPrices or {})[script] or ''))end
 if self.addPrice then self.addPrice:setText(tostring(script and (self.settings.vehicles or {})[script] or ''))end
end
function A:refreshEquipmentVariations()
 self.equipmentScriptIDs=Groups.select(self.vehicleGroups,self.equipmentScripts,self.equipmentVariations)
 self.keepAccessory=nil;self:refreshEquipment()
end
function A:refreshEquipment()
 local script=self.equipmentScriptIDs[self.equipmentVariations.selected];self.equipmentRows=(self.settings.accessoryOptions or {})[script] or {};self.equipmentChoice:clear()
 for i,row in ipairs(self.equipmentRows)do self.equipmentChoice:addOption(row.label..(row.discovered and ' [discovered]' or ''));if row.id==self.keepAccessory then self.equipmentChoice.selected=i end end
 self:refreshPolicy()
end
function A:refreshPolicy()
 local row=self.equipmentRows[self.equipmentChoice.selected]
 self.equipmentBuff.enable=row~=nil and row.capacitySupported~=false
 self.equipmentBonus:setEditable(row~=nil and row.capacitySupported~=false)
 self.equipmentEnabled:setSelected(1,row~=nil and row.enabled==true);self.equipmentBuff:setSelected(1,row~=nil and row.buffEnabled==true)
 self.equipmentPrice:setText(tostring(row and row.price or 0));self.equipmentBonus:setText(tostring(row and row.capacityBonus or 0));self.saveEquipment:setEnable(row~=nil)
end
function A:submit(action)
 local args={action=action,revision=self.settings.revision,offer=self.offer and self.offer.id}
 for key,field in pairs(self.fields)do args[key]=tonumber(field:getText())end
 if action=='buybacks'then args.allowHotwiredBuybacks=self.allowHotwiredBuybacks:isSelected(1);args.minimumBuybackParts=tonumber(self.minimumBuybackParts:getText());args.requireBuybackKey=self.requireBuybackKey:isSelected(1);args.excludeBuybackBattery=self.excludeBuybackBattery:isSelected(1);args.buybacksEnabled=self.buybacksEnabled:isSelected(1);args.buybackPercent=tonumber(self.buybackPercent:getText());args.damagePercent=tonumber(self.damagePercent:getText())end
 if action=='audio'then args.purchaseVolume=self.purchaseVolume:getCurrentValue();args.musicVolume=self.musicVolume:getCurrentValue(); args.purchaseSound=self.purchaseSound:isSelected(1);args.showroomMusic=self.showroomMusic:isSelected(1)end
 if action=='mode'then args.dynamic=not self.staticPricing:isSelected(1)end
 if action=='buffs'then args.addonBuffs=self.addonBuffs:isSelected(1)end
 if action=='paint'then args.specialPaint=tonumber(self.paintPrice:getText())end
 if action=='modelPrice' or action=='variantPrice' or action=='resetVariant'then args.script=self.priceScriptIDs[self.scriptVariations.selected];args.price=tonumber((action=='modelPrice' and self.modelPrice or self.addPrice):getText())end
 if action=='availability'then args.script=self.priceScriptIDs[self.scriptVariations.selected];args.enabled=self.offerVehicle:isSelected(1)end
 if action=='addVehicle'then args.script=self.priceScriptIDs[self.scriptVariations.selected];args.price=tonumber(self.addPrice:getText())end
 if action=='accessory'then local row=self.equipmentRows[self.equipmentChoice.selected];if not row then return end
  args.script=self.equipmentScriptIDs[self.equipmentVariations.selected];args.accessory=row.id
  args.enabled=self.equipmentEnabled:isSelected(1);args.accessoryPrice=tonumber(self.equipmentPrice:getText());args.buffEnabled=self.equipmentBuff:isSelected(1);args.capacityBonus=tonumber(self.equipmentBonus:getText())
 end
 self.send(args)
end
function A:prerender()
 ISPanel.prerender(self)
 if self.page=='sounds'then
  self:drawText(tostring(self.purchaseVolume:getCurrentValue())..'%',690,75,1,1,1,1,UIFont.Small)
  self:drawText(tostring(self.musicVolume:getCurrentValue())..'%',690,125,1,1,1,1,UIFont.Small)
  self:drawText('Applies to all Astrolux showrooms in this world.',10,240,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Play restarts actual playback. Pause stops it until Play. Save slider levels to apply.',10,270,0.8,0.8,0.8,1,UIFont.Small)
 elseif self.page=='vehiclePrices'then
  self:drawText('Vehicle model (A-Z)',10,42,1,1,1,1,UIFont.Small);self:drawText('Variation',450,42,1,1,1,1,UIFont.Small)
  self:drawText('Blanket price for all model variants ($)',10,135,1,1,1,1,UIFont.Small)
  self:drawText('Selected variation override ($)',10,245,1,1,1,1,UIFont.Small)
  self:drawText('Apply blanket first, then set exceptions per variant. Clear an override to inherit.',10,385,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Paint and accessories remain extra. Static/demand pricing still applies.',10,410,0.8,0.8,0.8,1,UIFont.Small)
 elseif self.page=='buybacks'then
  self:drawText('Base buyback (% of current retail)',10,115,1,1,1,1,UIFont.Small)
  self:drawText('Damage deduction strength (%)',10,165,1,1,1,1,UIFont.Small)
  self:drawText('100%: full condition loss. 50%: half the loss. 0%: ignore damage.',10,385,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Minimum standard parts installed (%)',10,215,1,1,1,1,UIFont.Small)
  self:drawText('Missing parts pay zero. Player-made matching keys are accepted.',10,410,0.8,0.8,0.8,1,UIFont.Small)
 elseif self.page=='prices'then
  for i,label in ipairs({'Normal base','Heavy Duty base','Sports base','Selected vehicle price'})do self:drawText(label,10,60+(i-1)*38,1,1,1,1,UIFont.Small)end
  self:drawText('Special paint extra ($)',440,60,1,1,1,1,UIFont.Small);self:drawText('Open Vehicle prices for model-wide prices and variant overrides.',440,200,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Base vehicle prices exclude chosen paint and accessories.',10,380,0.8,0.8,0.8,1,UIFont.Small)
 else
  self:drawText('Vehicle model (A-Z) / variation',10,42,1,1,1,1,UIFont.Small);self:drawText('Compatible accessory',10,100,1,1,1,1,UIFont.Small)
  self:drawText('Extra price ($)',440,175,1,1,1,1,UIFont.Small);self:drawText('Added bed capacity',440,225,1,1,1,1,UIFont.Small)
  self:drawText('Native protection/storage stays intact. Added buffs are optional extras.',10,275,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Availability affects new purchases. Buff changes also affect installed equipment.',10,300,0.8,0.8,0.8,1,UIFont.Small)
  local script=self.equipmentScriptIDs[self.equipmentVariations.selected]
  local issues=(self.settings.accessoryIssues or {})[script] or {}
  if #issues>0 then self:drawText(tostring(#issues)..' other slots need compatibility mappings: '..tostring(issues[1]):sub(1,75),10,400,1,0.8,0.5,1,UIFont.Small)end
  if #self.equipmentRows==0 then self:drawText('No compatible optional equipment is registered for this vehicle.',10,375,1,0.8,0.5,1,UIFont.Small)end
 end
end
function A.embed(settings,offer,send,parent,previous)
 local p=A:new(20,100,940,450);p.settings=settings;p.offer=offer;p.send=send
 if previous then p.keepPage=previous.page;p.keepPriceScript=previous.priceScriptIDs[previous.scriptVariations.selected];p.keepScript=previous.equipmentScriptIDs[previous.equipmentVariations.selected];local row=previous.equipmentRows[previous.equipmentChoice.selected];p.keepAccessory=row and row.id end
 p:initialise();parent:addChild(p);return p
end
return A
