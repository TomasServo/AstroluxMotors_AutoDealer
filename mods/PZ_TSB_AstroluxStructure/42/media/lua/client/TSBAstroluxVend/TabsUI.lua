local Preview=require 'TSBAstroluxVend/Preview'
local Admin=require 'TSBAstroluxVend/AdminPricing'
local Areas=require 'TSBAstroluxVend/SpawnAreas'
local U={}
function U.install(Panel,request,send,Client)
 function Panel:createChildren()
  ISPanel.createChildren(self);self.brandLogo=getTexture('media/textures/Item_TSBAstroluxMotorsSign.png');self.groups={vehicles={},equipment={},trade={},zone={},common={}};self.equipmentControls={};self.equipmentRows={};self.equipmentSelection={}
  local function widget(group,w)w:initialise();self:addChild(w);self.groups[group][#self.groups[group]+1]=w;return w end
  local function button(group,x,y,w,label,fn)return widget(group,ISButton:new(x,y,w,28,label,self,fn))end
  local function tab(x,label,name)local b=ISButton:new(x,60,125,28,label,self,function(s)if name=='admin'then s:updateAdmin(s.adminPricing)end;s:showTab(name)end);b:initialise();self:addChild(b);return b end
  tab(20,'Vehicles','vehicles');tab(155,'Accessories','equipment');tab(290,'Trade-ins','trade');tab(425,'Delivery Zone','zone');self.adminButton=tab(560,'Admin','admin');self.adminButton:setVisible(false)
  self.selection=widget('vehicles',ISComboBox:new(20,105,440,28,self,function(s)s.quote=nil;s.confirm:setEnable(false);s:updateConfiguration();s:updatePaint();s:updatePreview()end))
  self.paint=widget('vehicles',ISComboBox:new(20,150,440,28,self,function(s)s.quote=nil;s.confirm:setEnable(false);s:updatePreview()end));self.paint:addOption('Factory appearance')
  self.windows=widget('vehicles',ISTickBox:new(20,315,440,26,'AstroluxFactoryWindows',self,function(s)
   s.quote=nil;s.confirm:setEnable(false);s:updatePaint();s:updatePreview()
  end));self.windows:addOption('Passenger windows (native 6-seat model)');self.windows:setSelected(1,false)
  self.search=widget('vehicles',ISTextEntryBox:new('',20,210,310,28))
  button('vehicles',340,210,120,'Search',function(s)s.query=s.search:getText();s.page=1;request(s,'open')end)
  button('vehicles',20,255,215,'Previous page',function(s)s.page=math.max(1,(s.page or 1)-1);request(s,'open')end)
  button('vehicles',245,255,215,'Next page',function(s)s.page=math.min(s.pages or 1,(s.page or 1)+1);request(s,'open')end)
  button('vehicles',20,350,440,'Refresh / check order',function(s)request(s,'open')end)
  button('vehicles',20,390,440,'Retry recorded delivery',function(s)request(s,'deliver')end)
  self.tradeRows=widget('trade',ISScrollingListBox:new(20,255,940,245));self.tradeRows:instantiate()
  self.tradeAppraise=button('trade',20,510,300,'Appraise vehicle in delivery area',function(s)request(s,'tradeQuote')end)
  self.tradeAccept=button('trade',340,510,300,'Accept trade-in for cash',function(s)
   request(s,'tradeAccept');s.tradeQuote=nil;s.tradeAccept:setEnable(false);s.tradeDecline:setEnable(false)
  end)
  self.tradeDecline=button('trade',660,510,300,'Keep my car',function(s)request(s,'tradeDecline')end)
  self.tradeAccept:setEnable(false);self.tradeDecline:setEnable(false)
  self.zoneDirection=widget('zone',ISComboBox:new(250,215,260,28,self,nil))
  for _,label in ipairs({'North','East','South','West'})do self.zoneDirection:addOption(label)end
  self.zoneFields={}
  for i,key in ipairs({'x1','y1','x2','y2'})do
   self.zoneFields[key]=widget('zone',ISTextEntryBox:new('',20+(i-1)*235,290,215,28))
  end
  self.zoneSave=button('zone',20,350,450,'Save rectangle and vehicle direction',function(s)s:saveZone()end)
  self.zoneSelect=button('zone',490,350,470,'Select rectangle on the map',function(s)
   local p,terminal,heading=s.player,s.zoneTerminal,Areas.directions[s.zoneDirection.selected]
   s:close()
   require('TSBAstroluxVend/AreaCursor'):start(p,heading,function(ax,ay,bx,by)
    send(p,'areaSet',{terminal=terminal,ax=ax,ay=ay,bx=bx,by=by,heading=heading,confirmed=true})
   end)
  end)
  button('zone',20,400,450,'Refresh delivery zone',function(s)request(s,'open')end)
  self.zoneShow=button('zone',490,400,470,'Show delivery zone',function(s)
   if not s.spawnArea then s.message='No delivery zone configured for this kiosk.';return end
   local area={};for k,v in pairs(s.spawnArea)do area[k]=v end
   require('TSBAstroluxVend/AreaCursor'):showZone(s.player,area)
  end)
  self.equipmentPage=1
  button('equipment',20,475,215,'Previous accessories',function(s)s.equipmentPage=math.max(1,s.equipmentPage-1);s:showTab('equipment')end)
  button('equipment',245,475,215,'Next accessories',function(s)s.equipmentPage=math.min(math.max(1,math.ceil(#s.equipmentRows/8)),s.equipmentPage+1);s:showTab('equipment')end)
  self.payment=widget('common',ISComboBox:new(20,510,440,28,self,function(s)s.quote=nil;s.confirm:setEnable(false)end));self.payment:addOption('Pay with carried cash');self.paymentIDs={'cash'}
  self.scene=ISUI3DScene:new(500,105,460,340);self.scene:initialise();self.scene:instantiate();self:addChild(self.scene)
  self.preview=Preview.new(self.scene);self.preview.enabled=Client.previewEnabled~=false
  button('common',500,510,220,'Toggle 3D preview',function(s)s.preview.enabled=not s.preview.enabled;Client.previewEnabled=s.preview.enabled;s:updatePreview()end)
  button('common',730,510,230,'Reset preview / fit vehicle',function(s)s.preview:clear();s:updatePreview()end)
  self.getQuote=button('common',20,640,440,'Get price quote',function(s)request(s,'quote')end)
  self.confirm=button('common',500,640,460,'Confirm purchase',function(s)
   -- Local UI feedback only; audio failure must never interrupt purchasing.
   require('TSBAstroluxVend/AudioSettings').playPurchase()
   request(s,'buy')
  end);self.confirm:setEnable(false)
  local close=ISButton:new(20,700,940,28,'Close',self,function(s)s:close()end);close:initialise();self:addChild(close)
  self:showTab('vehicles')
 end
 function Panel:showTab(tab)
  if tab=='admin' and not self.adminPricing then tab='vehicles'end
  self.equipmentPage=math.max(1,math.min(self.equipmentPage or 1,math.max(1,math.ceil(#self.equipmentRows/8))))
  self.activeTab=tab
  for name,widgets in pairs(self.groups)do for _,w in ipairs(widgets)do w:setVisible(name==tab or (name=='common' and tab~='admin' and tab~='trade' and tab~='zone'))end end
  for i,row in ipairs(self.equipmentRows)do local w=self.equipmentControls[row.id]
   if w then w:setVisible(tab=='equipment' and math.floor((i-1)/8)+1==self.equipmentPage)end
  end
  if self.adminView then if tab~='admin' then self.adminView:stopAudioPreviews()end;self.adminView:setVisible(tab=='admin')end
  self.windows:setVisible(tab=='vehicles' and #(self.configurationRows or {})>0)
  self.scene:setVisible(tab~='admin' and tab~='trade' and tab~='zone' and self.preview.enabled and self.preview.loaded==true)
 end
 function Panel:updateZone()
  local a=self.spawnArea
  for key,w in pairs(self.zoneFields)do w:setText(tostring(a and a[key] or ''));w:setEditable(self.adminPricing~=nil)end
  for i,d in ipairs(Areas.directions)do if a and d==a.heading then self.zoneDirection.selected=i end end
  self.zoneDirection:setEnabled(self.adminPricing~=nil)
  self.zoneSave:setEnable(self.adminPricing~=nil);self.zoneSelect:setEnable(self.adminPricing~=nil)
 end
 function Panel:saveZone()
  local f=self.zoneFields
  local a,why=Areas.rectangle(tonumber(f.x1:getText()),tonumber(f.y1:getText()),tonumber(f.x2:getText()),tonumber(f.y2:getText()),Areas.directions[self.zoneDirection.selected])
  if not a then self.message=why;return end
  send(self.player,'areaSet',{terminal=self.zoneTerminal,ax=a.x1,ay=a.y1,bx=a.x2,by=a.y2,heading=a.heading,confirmed=true})
 end
 function Panel:updateConfiguration()
  local offer=self.offers and self.offers[self.selection.selected]
  if self.configurationFamily~=(offer and offer.script)then self.windows:setSelected(1,false)end
  self.configurationFamily=offer and offer.script;self.configurationRows=offer and offer.configurationOptions or {}
  if #self.configurationRows==0 then self.windows:setSelected(1,false)end
 end
 function Panel:getConfiguration()
  return self.windows:isSelected(1) and self.configurationRows[1] and self.configurationRows[1].script or nil
 end
 function Panel:effectiveOffer()
  local offer=self.offers and self.offers[self.selection.selected]
  return self:getConfiguration() and self.configurationRows[1] or offer
 end
 function Panel:getEquipment()
  local out={};for id,w in pairs(self.equipmentControls)do if w:isSelected(1)then out[id]=true end end;return out
 end
 function Panel:updateEquipment()
  local offer=self:effectiveOffer()
  local keep=self.equipmentScript==(offer and offer.script) and self:getEquipment() or {}
  if self.equipmentScript~=(offer and offer.script)then self.equipmentPage=1 end
  self.equipmentScript=offer and offer.script
  for _,w in pairs(self.equipmentControls)do self:removeChild(w)end
  self.equipmentControls={};self.equipmentRows=offer and offer.equipmentOptions or {}
  for i,row in ipairs(self.equipmentRows)do
   local label=row.label..' (+$'..row.price..')'..(row.activeBonus>0 and ('; +'..row.activeBonus..' bed capacity') or (row.capacityBonus>0 and '; added buff off' or ''))
   local id=row.id
   local w=ISTickBox:new(20,130+((i-1)%8)*40,450,26,'AstroluxEquipment_'..id,self,function(s)
    local selected=s:getEquipment()
    if id=='camper' and not selected.camper and s.equipmentControls.roofRack then s.equipmentControls.roofRack:setSelected(1,false)end
    if row.requires and selected[id] and not selected[row.requires]then s.equipmentControls[id]:setSelected(1,false);s.message=row.label..' requires the camper top. Select the camper first.'end
    s.quote=nil;s.confirm:setEnable(false);s:updatePreview()
   end)
   w:initialise();w:addOption(label);w:setSelected(1,keep[id]==true);self:addChild(w);self.equipmentControls[id]=w
  end
  -- Changes to owner availability may remove a dependency from the buyer list.
  if self.equipmentControls.roofRack and not (self.equipmentControls.camper and self.equipmentControls.camper:isSelected(1))then self.equipmentControls.roofRack:setSelected(1,false)end
  self:showTab(self.activeTab or 'vehicles')
 end
 function Panel:updatePaint()
  local offer=self:effectiveOffer()
  local old=self.paintOptions and self.paintOptions[self.paint.selected]
  local keep=old and self.paintScript==(offer and offer.script) and old.id
  self.paintScript=offer and offer.script;self.paintOptions=offer and offer.paintOptions;self.paint:clear()
  for i,o in ipairs(self.paintOptions or {})do
   self.paint:addOption(o.id=='factory' and 'Factory color' or (o.label..(o.surcharge>0 and (' +$'..o.surcharge) or ' - included')))
   if keep==o.id then self.paint.selected=i end
  end
  if not self.paintOptions then self.paint:addOption('Factory appearance')end
  self:updateEquipment()
 end
 function Panel:updatePreview()
  local offer=self:effectiveOffer();local selected=self:getEquipment()
  local paint=self.paintOptions and self.paintOptions[self.paint.selected]
  if offer and paint and paint.script then local copy={};for k,v in pairs(offer)do copy[k]=v end;copy.script=paint.script;offer=copy end
  self.preview:show(offer,selected.camper,selected)
  self.getQuote:setEnable(offer~=nil and offer.available~=false)
  if self.activeTab=='admin' or self.activeTab=='trade' or self.activeTab=='zone'then self.scene:setVisible(false)end
 end
 function Panel:updateAdmin(settings)
  self.adminPricing=settings;local previous=self.adminView
  if previous then previous:stopAudioPreviews();self:removeChild(previous)end
  self.adminView=nil
  if settings then
   local offer=self.offers and self.offers[self.selection.selected]
   self.adminView=Admin.embed(settings,offer,function(args)
    for k,v in pairs(self.location)do args[k]=v end
    args.search=self.query or '';args.page=self.page or 1
    self.quote=nil;self.confirm:setEnable(false);send(self.player,'setPrices',args)
   end,self,previous)
  end
  self:showTab(self.activeTab or 'vehicles')
 end
 function Panel:prerender()
  ISPanel.prerender(self)
  if self.brandLogo then
   -- The 64px icon artwork occupies x=1..63, y=11..51. Align its
   -- visible right edge with the controls' 20px inner menu margin.
   local size=150
   self:drawTextureScaled(self.brandLogo,self.width-20-size*63/64,4-size*11/64,size,size,1,1,1,1)
  end
  self:drawText('Astrolux Motors',20,15,1,1,1,1,UIFont.Medium)
  self:drawText('Cash: $'..tostring(self.balance or '?')..(self.bankAvailable and (' | Bank: $'..tostring(self.bankBalance)) or ''),300,22,1,1,1,1,UIFont.Small)
  if self.activeTab=='zone'then
   local a=self.spawnArea
   self:drawText('Vehicle delivery and trade-in zone',20,115,1,1,1,1,UIFont.Medium)
   self:drawText(a and ('Saved rectangle: '..a.x1..', '..a.y1..' to '..a.x2..', '..a.y2..' | '..(a.x2-a.x1+1)..' x '..(a.y2-a.y1+1)..' tiles') or 'No delivery zone configured for this kiosk.',20,155,0.9,0.9,0.9,1,UIFont.Small)
   self:drawText(self.adminPricing and 'Choose vehicle direction, then select the area on the map or enter its corners.' or 'An administrator can change this zone.',20,185,0.9,0.9,0.9,1,UIFont.Small)
   self:drawText('New vehicles face',20,220,1,1,1,1,UIFont.Small)
   for i,label in ipairs({'Corner 1 X','Corner 1 Y','Corner 2 X','Corner 2 Y'})do self:drawText(label,20+(i-1)*235,265,1,1,1,1,UIFont.Small)end
   self:drawText('Ground floor only. Changing direction affects future deliveries.',20,455,0.8,0.8,0.8,1,UIFont.Small)
   self:drawText('Resolve outstanding purchases before changing the zone. Unpaid quotes are cancelled.',20,480,0.8,0.8,0.8,1,UIFont.Small)
  elseif self.activeTab=='trade'then
   local rules=self.tradeRules or {};local q=self.tradeQuote
   self:drawText(self.tradeEnabled and 'Vehicle buybacks are enabled.' or 'Buybacks are disabled. An administrator can enable them in Admin > Buybacks.',20,110,1,1,1,1,UIFont.Small)
   self:drawText('Park exactly one loaded vehicle in this kiosk delivery area; empty it, stop the engine and exit.',20,135,0.85,0.85,0.85,1,UIFont.Small)
   self:drawText('Base: '..tostring(rules.buybackPercent or 50)..'% | Damage strength: '..tostring(rules.damagePercent or 100)..'% | Minimum parts: '..tostring(rules.minimumBuybackParts or 75)..'%',20,160,1,1,1,1,UIFont.Small)
   self:drawText('Key: '..(rules.requireBuybackKey~=false and 'matching carried key required (player-made accepted)' or 'not required')..' | Hotwired: '..(rules.allowHotwiredBuybacks~=false and 'allowed' or 'blocked'),20,185,0.85,0.85,0.85,1,UIFont.Small)
   self:drawText(q and ('Cash offer: $'..q.amount..' | Retail: $'..q.retail..' | Maximum: $'..q.maximum..' | Expires in 60 seconds') or 'Request an appraisal to see each standard part and its value.',20,210,1,0.9,0.7,1,UIFont.Small)
   self:drawText('Part | Condition | Cash value / full value. Accepting permanently removes the vehicle.',20,235,1,0.8,0.5,1,UIFont.Small)
   if not q then
    local a=self.spawnArea
    self:drawText('No appraisal yet. Click Appraise vehicle in delivery area below.',40,300,1,1,1,1,UIFont.Medium)
    self:drawText(a and ('Delivery rectangle: '..a.x1..', '..a.y1..' to '..a.x2..', '..a.y2..' (ground floor).') or 'An administrator must configure this kiosk delivery area first.',40,340,0.9,0.9,0.9,1,UIFont.Small)
    self:drawText('The vehicle must be inside that rectangle, which may be away from this building.',40,370,0.9,0.9,0.9,1,UIFont.Small)
   end
  elseif self.activeTab~='admin'then
   local offer=self.offers and self.offers[self.selection.selected]
   if self.activeTab=='equipment'then
    self:drawText(offer and offer.name or 'Choose a vehicle in the Vehicles tab.',20,103,1,1,1,1,UIFont.Small)
    if #self.equipmentRows==0 then self:drawText('No compatible optional equipment is offered for this vehicle.',20,145,0.9,0.85,0.6,1,UIFont.Small)end
    for i,row in ipairs(self.equipmentRows)do if math.floor((i-1)/8)+1==self.equipmentPage then self:drawText(row.effect,45,153+((i-1)%8)*40,0.75,0.75,0.75,1,UIFont.Small)end end
   else
    self:drawText('Page '..tostring(self.page or 1)..' / '..tostring(self.pages or 1)..' | '..tostring(self.total or 0)..' vehicles',20,292,0.8,0.8,0.8,1,UIFont.Small)
    local configuration=(self.configurationRows or {})[1]
    if configuration then self:drawText('With passenger windows: $'..configuration.price..' before paint/accessories',20,435,0.8,0.8,0.8,1,UIFont.Small)end
   end
   self:drawText(self.preview.status or '',500,455,0.8,0.8,0.8,1,UIFont.Small)
   self:drawText('Equipment preview uses factory paint.',500,478,0.8,0.8,0.8,1,UIFont.Small)
  end
  local line,y='',565
  for word in tostring(self.message or ''):gmatch('%S+')do
   local nextLine=line=='' and word or line..' '..word
   if getTextManager():MeasureStringX(UIFont.Small,nextLine)>930 then self:drawText(line,20,y,1,0.9,0.7,1,UIFont.Small);line=word;y=y+16 else line=nextLine end
   if y>615 then break end
  end
  self:drawText(line,20,y,1,0.9,0.7,1,UIFont.Small)
  self:drawText('Keep the designated vehicle delivery area clear.',20,675,0.85,0.85,0.7,1,UIFont.Small)
 end
end
return U
