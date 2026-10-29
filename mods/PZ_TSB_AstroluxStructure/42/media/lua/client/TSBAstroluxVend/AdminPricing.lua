require 'ISUI/ISPanel'
require 'ISUI/ISButton'
require 'ISUI/ISTextEntryBox'
require 'ISUI/ISComboBox'
require 'ISUI/ISTickBox'
require 'RadioCom/ISUIRadio/ISSliderPanel'
require 'Vehicles/ISUI/ISUI3DScene'
local VehiclePreview=require 'TSBAstroluxVend/Preview'
local Groups=require 'TSBAstroluxVend/AdminVehicleGroups'
local PreviewAudio=require 'TSBAstroluxVend/AudioPreview'
local AudioAutosave=require 'TSBAstroluxVend/AudioAutosave'
local A=ISPanel:derive('AstroluxPriceAdmin')
function A:addControl(page,w)
 w:initialise();self:addChild(w);self.groups[page][#self.groups[page]+1]=w;return w
end
function A:refreshDisplayLocks()
 if not self.displayLocks then return end
 local D=require 'TSBAstroluxStructure/SettingsDisplays'
 local selected,message,enabled=D.status(self.player)
 self.displayLocks:setSelected(1,selected);self.displayLocks.enable=enabled;self.displayLockStatus=message
end
function A:refreshShowroomSettings()
 if not self.entranceToggles then return end
 local S=require 'TSBAstroluxStructure/ShowroomSettings'
 local r,why=S.record(self.player)
 for edge,t in pairs(self.entranceToggles)do
  t:setSelected(1,r and not (r.closedEntrances and r.closedEntrances[edge]==true) or false)
  t.enable=r~=nil
 end
 self.coffeeRestock:setSelected(1,r and r.coffeeRestockEnabled~=false or false)
 self.coffeeRestock.enable=r~=nil
 self.showroomSettingStatus=why or 'Unchecked entrances become windows; nearby entrance rugs are stored until reopened.'
 if self.automaticDoors then
  local autoRecord,autoWhy=S.autoDoorRecord(self.player)
  self.automaticDoors:setSelected(1,autoRecord and autoRecord.automaticDoorsEnabled==true or false)
  self.automaticDoors.enable=autoRecord~=nil
  self.automaticDoorStatus=autoWhy or 'Opens within 2 tiles; closes after 2 seconds clear.'
 end
end
function A:stopAudioPreviews()
 PreviewAudio.stopAll()
 if self.vehiclePreview then self.vehiclePreview:clear();self.vehicleScene:setVisible(false)end
end
function A:refreshVehiclePreview()
 if not self.vehiclePreview then return end
 if self.page~='vehiclePrices' then self.vehiclePreview:clear();self.vehicleScene:setVisible(false);return end
 local script=self.priceScriptIDs and self.priceScriptIDs[self.scriptVariations.selected]
 self.vehiclePreview:show(script and {script=script} or nil)
end
function A:setVisible(visible)
 ISPanel.setVisible(self,visible)
 if not visible and self.vehiclePreview then self.vehiclePreview:clear();self.vehicleScene:setVisible(false)
 elseif visible then self:refreshVehiclePreview()end
end
function A:showPage(page)
 if page~='sounds'then self:stopAudioPreviews()end
 self.page=page
 if page=='sounds' then self:refreshDisplayLocks();self:refreshShowroomSettings()end
 for key,items in pairs(self.groups)do for _,w in ipairs(items)do w:setVisible(key==page)end end
 self:refreshVehiclePreview()
end
function A:createChildren()
 ISPanel.createChildren(self);self.groups={prices={},vehiclePrices={},equipment={},buybacks={},sounds={},colorPrices={}};self.fields={}
 local function button(page,x,y,w,label,fn)return self:addControl(page,ISButton:new(x,y,w,28,label,self,fn))end
 local function field(page,x,y,text)return self:addControl(page,ISTextEntryBox:new(tostring(text),x,y,160,26))end
 local function tick(page,x,y,name,label,fn)local t=self:addControl(page,ISTickBox:new(x,y,400,28,name,self,fn));t:addOption(label);return t end
 local prices=ISButton:new(10,5,180,28,'Prices & Catalog',self,function(s)s:showPage('prices')end);prices:initialise();self:addChild(prices)
 local equipment=ISButton:new(200,5,220,28,'Accessory Settings',self,function(s)s:showPage('equipment')end);equipment:initialise();self:addChild(equipment)
 local buybacks=ISButton:new(430,5,180,28,'Buybacks',self,function(s)s:showPage('buybacks')end);buybacks:initialise();self:addChild(buybacks)
 local sounds=ISButton:new(810,5,110,28,'Settings',self,function(s)s:showPage('sounds')end);sounds:initialise();self:addChild(sounds)
 local colors=ISButton:new(620,5,180,28,'Color Prices',self,function(p)p:showPage('colorPrices')end);colors:initialise();self:addChild(colors)
 require('TSBAstroluxVend/AppraisalPartPanel').create(self,button)
 local audio=self.settings.audio or {}
 self.purchaseSound=tick('sounds',10,70,'AstroluxPurchaseSound','Purchase Button / Trade-In Sound',function(p)AudioAutosave.save(p)end);self.purchaseSound:setSelected(1,audio.purchaseSound~=false)
 self.showroomMusic=tick('sounds',10,120,'AstroluxShowroomMusic','Showroom Music',function(p)AudioAutosave.save(p)end);self.showroomMusic:setSelected(1,audio.showroomMusic~=false)
 self.purchaseVolume=self:addControl('sounds',ISSliderPanel:new(410,70,270,28,self,function(_,value)PreviewAudio.level('purchase',value)end));self.purchaseVolume:setValues(0,100,1,10);self.purchaseVolume:setCurrentValue(audio.purchaseVolume or 100,true)
 self.musicVolume=self:addControl('sounds',ISSliderPanel:new(410,120,270,28,self,function(_,value)PreviewAudio.level('music',value)end));self.musicVolume:setValues(0,100,1,10);self.musicVolume:setCurrentValue(audio.musicVolume or 50,true)
 button('sounds',745,70,75,'Play',function(s)PreviewAudio.play('purchase',s.purchaseVolume:getCurrentValue())end)
 button('sounds',830,70,75,'Pause',function()PreviewAudio.pause('purchase')end)
 button('sounds',745,120,75,'Play',function(s)PreviewAudio.play('music',s.musicVolume:getCurrentValue())end)
 button('sounds',830,120,75,'Pause',function()PreviewAudio.pause('music')end)
 self.doorSound=tick('sounds',10,170,'AstroluxDoorSound','Sliding Doors',function(p)AudioAutosave.save(p)end);self.doorSound:setSelected(1,audio.doorSound~=false)
 self.doorVolume=self:addControl('sounds',ISSliderPanel:new(410,170,270,28,self,function(_,value)PreviewAudio.level('door',value)end));self.doorVolume:setValues(0,100,1,10);self.doorVolume:setCurrentValue(audio.doorVolume or 100,true)
 button('sounds',745,170,75,'Play',function()PreviewAudio.play('door')end)
 button('sounds',830,170,75,'Pause',function()PreviewAudio.pause('door')end)
 self.musicTrack=self:addControl('sounds',ISComboBox:new(410,202,270,28,self,function(p)AudioAutosave.save(p)end));self.musicTrack:addOption('Lounge');self.musicTrack:addOption('Elevator');self.musicTrack.selected=audio.musicTrack==1 and 1 or 2
 self.musicTrack.tooltip='Default showroom track. Players can choose either track in Settings.'
 self.displayLocks=tick('sounds',10,235,'AstroluxDisplayLocks','Lock showroom mannequin outfits',function(p)
  local D=require 'TSBAstroluxStructure/SettingsDisplays'
  local ok,reason=D.set(p.player,p.displayLocks:isSelected(1))
  p:refreshDisplayLocks();if not ok then p.displayLockStatus=reason end
 end)
 self:refreshDisplayLocks()
 self.entranceToggles={}
 for i,edgeName in ipairs({'north','south','east','west'})do
  local edge=edgeName
  local t=tick('sounds',10+(i-1)*225,325,'AstroluxEntrance_'..edge,edge:sub(1,1):upper()..edge:sub(2)..' entrance',function(p)
   local S=require 'TSBAstroluxStructure/ShowroomSettings'
   local ok,why=S.entrance(p.player,edge,p.entranceToggles[edge]:isSelected(1))
   p:refreshShowroomSettings();if not ok then p.showroomSettingStatus=why end
  end)
  t:setWidth(215);self.entranceToggles[edge]=t
 end
 self.coffeeRestock=tick('sounds',10,385,'AstroluxCoffeeRestock','Enable coffee-supply restocking',function(p)
  local S=require 'TSBAstroluxStructure/ShowroomSettings'
  local ok,why=S.coffee(p.player,p.coffeeRestock:isSelected(1))
  p:refreshShowroomSettings();if not ok then p.showroomSettingStatus=why end
 end)
 self.automaticDoors=tick('sounds',470,235,'AstroluxAutomaticDoors','Automatic doors (safe zones)',function(p)
  local S=require 'TSBAstroluxStructure/ShowroomSettings'
  local ok,why=S.autoDoors(p.player,p.automaticDoors:isSelected(1))
  p:refreshShowroomSettings();if not ok then p.automaticDoorStatus=why end
 end)
 self.automaticDoors:setWidth(435)
 self.automaticDoors.tooltip='Opt in for this safe-zone showroom. Players on either side open unlocked sliding doors within 2 tiles. Doors close 2 seconds after everyone leaves; occupied doorways stay open. Does not create or change a safe zone.'
 self:refreshShowroomSettings()
 button('sounds',470,385,435,'Inspect / Recover Orders',function(p)p:showPage('orders')end).tooltip='Inspect outstanding orders at this kiosk. Cancel only unpaid queues or verified cash rollbacks; no automatic refunds or vehicle deletion.'
 require('TSBAstroluxVend/OrderRecoveryPanel').create(self,button)
 button('sounds',470,425,435,'Inspect / Recover Trade-Ins',function(p)p:showPage('tradeRecovery')end)
 require('TSBAstroluxVend/TradeRecoveryPanel').create(self,button)
 AudioAutosave.install(self)
 self.buybacksEnabled=tick('buybacks',10,55,'AstroluxBuybacks','Enable Vehicle Buybacks',nil);self.buybacksEnabled:setSelected(1,self.settings.buybacksEnabled==true)
 self.buybackPercent=field('buybacks',400,110,self.settings.buybackPercent)
 self.damagePercent=field('buybacks',400,160,self.settings.damagePercent)
 self.minimumBuybackParts=field('buybacks',400,210,self.settings.minimumBuybackParts)
 self.requireBuybackKey=tick('buybacks',10,255,'AstroluxBuybackKey','Require Matching Carried Key',nil);self.requireBuybackKey:setSelected(1,self.settings.requireBuybackKey~=false)
 self.excludeBuybackBattery=tick('buybacks',10,290,'AstroluxBuybackBattery','Exclude Battery from Installed-Parts Count',nil);self.excludeBuybackBattery:setSelected(1,self.settings.excludeBuybackBattery~=false)
 self.allowHotwiredBuybacks=tick('buybacks',470,255,'AstroluxHotwiredBuybacks','Allow Hotwired Vehicle Trade-Ins',nil);self.allowHotwiredBuybacks:setSelected(1,self.settings.allowHotwiredBuybacks~=false)
 button('buybacks',10,340,550,'Save Buyback Policy',function(s)s:submit('buybacks')end)
 local vehiclePrices=ISButton:new(620,5,180,28,'Vehicles & Prices',self,function(s)s:showPage('vehiclePrices')end);vehiclePrices:initialise();self:addChild(vehiclePrices)
 for i,key in ipairs({'normal','heavy','sports'})do
  local value=self.settings[key];if key=='price'then value=self.offer and (self.offer.basePrice or self.offer.price) or ''end
  self.fields[key]=field('prices',190,55+(i-1)*38,value)
 end
 button('prices',10,215,340,'Save Class Prices',function(s)s:submit('classes')end)
 self.staticPricing=tick('prices',10,325,'AstroluxPricingMode','Static Pricing (Unchecked: Demand)',function(s)s:submit('mode')end);self.staticPricing:setSelected(1,self.settings.dynamic==false)
 self.paintPrice=field('prices',650,55,self.settings.specialPaint)
 button('prices',440,95,370,'Save Special Paint Surcharge',function(s)s:submit('paint')end)
 self.addonBuffs=tick('prices',440,140,'AstroluxAddonBuffs','Enable Added Accessory Buffs',function(s)s:submit('buffs')end);self.addonBuffs:setSelected(1,self.settings.addonBuffs~=false)
 self.demandIncrease=field('prices',700,245,self.settings.demandIncrease or 2)
 self.demandRecovery=field('prices',700,285,self.settings.demandRecovery or 2)
 button('prices',440,330,420,'Save Demand Rates',function(s)s:submit('demand')end)
 for i,row in ipairs({{'normal','Reset Normal Demand'},{'heavy','Reset Heavy Duty Demand'},{'sports','Reset Sports Demand'},{'all','Reset All Demand'}})do
  local scope=row[1]
  button('prices',10+(i-1)*230,410,220,row[2],function(s)s:submit('resetDemand',scope)end)
 end
 self.vehicleGroups=Groups.build(self.settings.scripts,self.settings.scriptLabels)
 self.scripts=self:addControl('vehiclePrices',ISComboBox:new(10,65,420,28,self,function(s)s:refreshPriceVariations()end))
 self.scriptVariations=self:addControl('vehiclePrices',ISComboBox:new(450,65,440,28,self,function(s)s:refreshVehicleAvailability()end))
 for _,group in ipairs(self.vehicleGroups)do self.scripts:addOption(group.label)end
 self:refreshPriceVariations(self.keepPriceScript or (self.offer and self.offer.script))
 self.vehicleScene=self:addControl('vehiclePrices',ISUI3DScene:new(450,105,440,240))
 self.vehiclePreview=VehiclePreview.new(self.vehicleScene)
 self.addPrice=field('vehiclePrices',10,232,'')
 self.modelPrice=field('vehiclePrices',10,132,'')
 local add=button('vehiclePrices',10,268,420,'Set Price for This Variation',function(s)s:submit('variantPrice')end);add:setEnable(#(self.settings.scripts or {})>0)
 button('vehiclePrices',10,166,420,'Apply to All Variants / Reset Overrides',function(s)s:submit('modelPrice')end)
 button('vehiclePrices',10,304,420,'Clear Variant Override / Use Model Price',function(s)s:submit('resetVariant')end)
 self.offerVehicle=tick('vehiclePrices',10,340,'AstroluxVehicleAvailability','Offer This Vehicle Variation',function(s)s:submit('availability')end)
 self:refreshVehicleAvailability()
 local resetModelDemand=button('vehiclePrices',10,378,420,'Reset Selected Model Demand',function(s)s:submit('resetModelDemand')end);resetModelDemand:setEnable(#(self.settings.scripts or {})>0)
 button('vehiclePrices',450,378,440,'Reset All Demand',function(s)s:submit('resetDemand','all')end)
 self.equipmentScripts=self:addControl('equipment',ISComboBox:new(10,65,420,28,self,function(s)s:refreshEquipmentVariations()end))
 self.equipmentVariations=self:addControl('equipment',ISComboBox:new(450,65,440,28,self,function(s)s:refreshEquipment()end))
 for _,group in ipairs(self.vehicleGroups)do self.equipmentScripts:addOption(group.label)end
 self.equipmentScriptIDs=Groups.select(self.vehicleGroups,self.equipmentScripts,self.equipmentVariations,self.keepScript or (self.offer and self.offer.script))
 self.equipmentChoice=self:addControl('equipment',ISComboBox:new(10,120,420,28,self,function(s)s:refreshPolicy()end))
 self.equipmentEnabled=tick('equipment',10,170,'AstroluxEquipmentAvailability','Offer This Accessory for This Vehicle',nil)
 self.equipmentPrice=field('equipment',650,170,0)
 self.equipmentBuff=tick('equipment',10,220,'AstroluxEquipmentBuff','Enable Added Storage Bonus',nil)
 self.equipmentBonus=field('equipment',650,220,0)
 self.protectionOverride=tick('equipment',10,260,'AstroluxProtectionOverride','Override Native Armor / Bull Bar Behavior',nil)
 self.durabilityPercent=field('equipment',650,300,0)
 self.protectionPercent=field('equipment',650,340,100)
 self.saveEquipment=button('equipment',10,430,800,'Save Accessory Price, Buffs & Protection',function(s)s:submit('accessory')end)
 self.colorModels=self:addControl('colorPrices',ISComboBox:new(10,65,420,28,self,function(p)p:refreshColorVariants()end))
 self.colorVariants=self:addControl('colorPrices',ISComboBox:new(450,65,440,28,self,function(p)p:refreshColors()end))
 self.colorChoices=self:addControl('colorPrices',ISComboBox:new(10,120,880,28,self,function(p)p:refreshColorPrice()end))
 self.colorPrice=field('colorPrices',450,175,0)
 button('colorPrices',10,225,420,'Save Color / Design Surcharge',function(p)p:submit('colorPrice')end)
 button('colorPrices',450,225,440,'Reset Color / Design to Default',function(p)p:submit('resetColorPrice')end)
 for _,group in ipairs(self.vehicleGroups)do self.colorModels:addOption(group.label)end
 self:refreshColorVariants()
 self:refreshEquipment();self:showPage(self.keepPage or 'prices')
end
function A:refreshColorVariants()
 self.colorIDs=Groups.select(self.vehicleGroups,self.colorModels,self.colorVariants);self:refreshColors()
end
function A:refreshColors()
 local script=self.colorIDs[self.colorVariants.selected]
 self.colorRows=(self.settings.colorOptions or {})[script] or {};self.colorChoices:clear();self.colorChoices.selected=1
 for _,row in ipairs(self.colorRows)do self.colorChoices:addOption(row.label..' (+$'..row.surcharge..')')end
 self:refreshColorPrice()
end
function A:refreshColorPrice()
 local row=self.colorRows[self.colorChoices.selected];self.colorPrice:setText(tostring(row and row.surcharge or 0))
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
 self:refreshVehiclePreview()
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
 local protection=row~=nil and row.protectionSupported==true
 self.protectionOverride.enable=protection
 self.protectionOverride:setSelected(1,protection and row.protectionOverride==true)
 self.durabilityPercent:setEditable(protection);self.protectionPercent:setEditable(protection)
 self.durabilityPercent:setText(tostring(row and row.durabilityPercent or 0))
 self.protectionPercent:setText(tostring(row and row.protectionPercent or 100))
 self.equipmentBuff.enable=row~=nil and row.capacitySupported~=false
 self.equipmentBonus:setEditable(row~=nil and row.capacitySupported~=false)
 self.equipmentEnabled:setSelected(1,row~=nil and row.enabled==true);self.equipmentBuff:setSelected(1,row~=nil and row.buffEnabled==true)
 self.equipmentPrice:setText(tostring(row and row.price or 0));self.equipmentBonus:setText(tostring(row and row.capacityBonus or 0));self.saveEquipment:setEnable(row~=nil)
end
function A:submit(action,demandClass)
 local args={action=action,revision=self.settings.revision,offer=self.offer and self.offer.id}
 for key,field in pairs(self.fields)do args[key]=tonumber(field:getText())end
 if action=='buybacks'then args.allowHotwiredBuybacks=self.allowHotwiredBuybacks:isSelected(1);args.minimumBuybackParts=tonumber(self.minimumBuybackParts:getText());args.requireBuybackKey=self.requireBuybackKey:isSelected(1);args.excludeBuybackBattery=self.excludeBuybackBattery:isSelected(1);args.buybacksEnabled=self.buybacksEnabled:isSelected(1);args.buybackPercent=tonumber(self.buybackPercent:getText());args.damagePercent=tonumber(self.damagePercent:getText())end
 if action=='audio'then args.musicTrack=self.musicTrack.selected;args.doorVolume=self.doorVolume:getCurrentValue();args.doorSound=self.doorSound:isSelected(1);args.purchaseVolume=self.purchaseVolume:getCurrentValue();args.musicVolume=self.musicVolume:getCurrentValue(); args.purchaseSound=self.purchaseSound:isSelected(1);args.showroomMusic=self.showroomMusic:isSelected(1)end
 if action=='resetModelDemand'then args.script=self.priceScriptIDs[self.scriptVariations.selected]end
 if action=='resetDemand'then args.demandClass=demandClass end
 if action=='demand'then args.demandIncrease=tonumber(self.demandIncrease:getText());args.demandRecovery=tonumber(self.demandRecovery:getText())end
 if action=='mode'then args.dynamic=not self.staticPricing:isSelected(1)end
 if action=='buffs'then args.addonBuffs=self.addonBuffs:isSelected(1)end
 if action=='colorPrice' or action=='resetColorPrice'then local row=self.colorRows[self.colorChoices.selected];if not row then return end;args.script=self.colorIDs[self.colorVariants.selected];args.paint=row.id;args.price=tonumber(self.colorPrice:getText())end
 if action=='paint'then args.specialPaint=tonumber(self.paintPrice:getText())end
 if action=='modelPrice' or action=='variantPrice' or action=='resetVariant'then args.script=self.priceScriptIDs[self.scriptVariations.selected];args.price=tonumber((action=='modelPrice' and self.modelPrice or self.addPrice):getText())end
 if action=='availability'then args.script=self.priceScriptIDs[self.scriptVariations.selected];args.enabled=self.offerVehicle:isSelected(1)end
 if action=='addVehicle'then args.script=self.priceScriptIDs[self.scriptVariations.selected];args.price=tonumber(self.addPrice:getText())end
 if action=='accessory'then local row=self.equipmentRows[self.equipmentChoice.selected];if not row then return end
  args.script=self.equipmentScriptIDs[self.equipmentVariations.selected];args.accessory=row.id
  args.protectionOverride=self.protectionOverride:isSelected(1);args.durabilityPercent=tonumber(self.durabilityPercent:getText());args.protectionPercent=tonumber(self.protectionPercent:getText())
  args.enabled=self.equipmentEnabled:isSelected(1);args.accessoryPrice=tonumber(self.equipmentPrice:getText());args.buffEnabled=self.equipmentBuff:isSelected(1);args.capacityBonus=tonumber(self.equipmentBonus:getText())
 end
 self.send(args)
end
function A:prerender()
 if isClient()and self.page=='sounds'and (not self.lastDisplayLockRefresh or getTimestampMs()-self.lastDisplayLockRefresh>500)then
  self.lastDisplayLockRefresh=getTimestampMs();self:refreshDisplayLocks()
 end
 if self.page=='sounds'and require('TSBAstroluxStructure/ReleaseSites').near(self.player)then
  local now=getTimestampMs();if not self.releaseRefresh or now-self.releaseRefresh>1000 then self.releaseRefresh=now;self:refreshShowroomSettings()end
 end
 ISPanel.prerender(self)
 if self.page=='orders' or self.page=='partRoles'then return end
 if self.page=='tradeRecovery'then self:tradeRecoveryLabels();return end
 if self.page=='colorPrices'then
  self:drawText('Vehicle Model (A-Z)',10,42,1,1,1,1,UIFont.Small);self:drawText('Body / Vehicle Variation',450,42,1,1,1,1,UIFont.Small)
  self:drawText('Color / Design',10,100,1,1,1,1,UIFont.Small);self:drawText('Extra Price ($)',10,180,1,1,1,1,UIFont.Small)
  self:drawText('Color/design charge is added to this variation price. Zero means included.',10,280,1,1,1,1,UIFont.Small)end
 if self.page=='sounds'then
  self:drawText(self.showroomSettingStatus or '',10,358,.8,.8,.8,1,UIFont.Small)
  self:drawText('Saved quantities stay unchanged. Re-enabling waits 10 real minutes.',10,419,.8,.8,.8,1,UIFont.Small)
  self:drawText(self.displayLockStatus or '',10,273,.8,.8,.8,1,UIFont.Small)
  self:drawText(self.automaticDoorStatus or '',470,273,.8,.8,.8,1,UIFont.Small)
  self:drawText('This showroom only. Off by default.',470,298,.8,.8,.8,1,UIFont.Small)
  self:drawText('Unlock to change outfits. Applies to this showroom only.',10,298,.8,.8,.8,1,UIFont.Small)
  self:drawText(tostring(self.doorVolume:getCurrentValue())..'%',690,175,1,1,1,1,UIFont.Small)
  self:drawText(tostring(self.purchaseVolume:getCurrentValue())..'%',690,75,1,1,1,1,UIFont.Small)
  self:drawText('Default Showroom Track',10,207,1,1,1,1,UIFont.Small)
  self:drawText(tostring(self.musicVolume:getCurrentValue())..'%',690,125,1,1,1,1,UIFont.Small)
 elseif self.page=='vehiclePrices'then
  self:drawText('Vehicle Model (A-Z)',10,42,1,1,1,1,UIFont.Small);self:drawText('Variation',450,42,1,1,1,1,UIFont.Small)
  self:drawText(self.vehiclePreview and self.vehiclePreview.status or 'Select a variation.',450,350,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Blanket Price for All Model Variants ($)',10,110,1,1,1,1,UIFont.Small)
  self:drawText('Selected Variation Override ($)',10,210,1,1,1,1,UIFont.Small)
  self:drawText('Apply blanket first, then set exceptions per variant. Clear an override to inherit.',10,410,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Paint and accessories remain extra. Static/demand pricing still applies.',10,432,0.8,0.8,0.8,1,UIFont.Small)
 elseif self.page=='buybacks'then
  self:drawText('Base Buyback (% of Current Retail)',10,115,1,1,1,1,UIFont.Small)
  self:drawText('Damage Deduction Strength (%)',10,165,1,1,1,1,UIFont.Small)
  self:drawText('100%: full condition loss. 50%: half the loss. 0%: ignore damage.',10,385,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Minimum Standard Parts Installed (%)',10,215,1,1,1,1,UIFont.Small)
  self:drawText('Missing parts pay zero. Player-made matching keys are accepted.',10,410,0.8,0.8,0.8,1,UIFont.Small)
 elseif self.page=='prices'then
  for i,label in ipairs({'Normal Base','Heavy Duty Base','Sports Base'})do self:drawText(label,10,60+(i-1)*38,1,1,1,1,UIFont.Small)end
  self:drawText('Special Paint Extra ($)',440,60,1,1,1,1,UIFont.Small);self:drawText('Open Vehicles & Prices for model-wide prices and variant overrides.',440,200,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Increase per Purchase (%)',440,250,1,1,1,1,UIFont.Small)
  self:drawText('Recovery per Game Day (%)',440,290,1,1,1,1,UIFont.Small)
  self:drawText('Base vehicle prices exclude chosen paint and accessories.',10,380,0.8,0.8,0.8,1,UIFont.Small)
 else
  self:drawText('Vehicle Model (A-Z) / Variation',10,42,1,1,1,1,UIFont.Small);self:drawText('Compatible Accessory',10,100,1,1,1,1,UIFont.Small)
  self:drawText('Extra Price ($)',440,175,1,1,1,1,UIFont.Small);self:drawText('Added Bed Capacity',440,225,1,1,1,1,UIFont.Small)
  self:drawText('Native Accessory Wear Reduction (%)',10,305,1,1,1,1,UIFont.Small)
  self:drawText('Native Protection Strength (%)',10,345,1,1,1,1,UIFont.Small)
  self:drawText('Unchecked: native behavior. Wear: 0 = native, 100 = no provider wear.',10,380,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Protection: 100 = native, 0 = none. Requires a reviewed armor adapter.',10,405,0.8,0.8,0.8,1,UIFont.Small)
  self:drawText('Availability affects new purchases. Buff changes also affect installed equipment.',10,475,0.8,0.8,0.8,1,UIFont.Small)
  local script=self.equipmentScriptIDs[self.equipmentVariations.selected]
  local issues=(self.settings.accessoryIssues or {})[script] or {}
  if #issues>0 then self:drawText(tostring(#issues)..' other slots need compatibility mappings: '..tostring(issues[1]):sub(1,75),10,500,1,0.8,0.5,1,UIFont.Small)end
  if #self.equipmentRows==0 then self:drawText('No compatible optional equipment is registered for this vehicle.',10,375,1,0.8,0.5,1,UIFont.Small)end
 end
end
function A.embed(settings,offer,send,parent,previous)
 local p=A:new(20,100,940,540);p.settings=settings;p.offer=offer;p.send=send;p.player=parent.player
 if previous and previous.vehiclePreview then previous.vehiclePreview:clear()end
 if previous then p.partAppraisalSelection=previous.partAppraisalSelection;p.keepPage=previous.page;p.keepPriceScript=previous.priceScriptIDs[previous.scriptVariations.selected];p.keepScript=previous.equipmentScriptIDs[previous.equipmentVariations.selected];local row=previous.equipmentRows[previous.equipmentChoice.selected];p.keepAccessory=row and row.id end
 p:initialise();parent:addChild(p);return p
end
return A
