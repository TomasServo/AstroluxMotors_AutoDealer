local Preview=require 'TSBAstroluxVend/Preview'
local Admin=require 'TSBAstroluxVend/AdminPricing'
local Areas=require 'TSBAstroluxVend/SpawnAreas'
local TradeSelection=require 'TSBAstroluxVend/TradeSelection'
local PersonalAudio=require 'TSBAstroluxVend/PersonalAudioPanel'
local U={}
function U.install(Panel,request,send,Client)
 function Panel:createChildren()
  ISPanel.createChildren(self);self.brandLogo=getTexture('media/textures/TSBAstroluxMenuLogo.png');self.groups={vehicles={},equipment={},trade={},zone={},personal={},common={}};self.equipmentControls={};self.equipmentRows={};self.equipmentSelection={}
  local function widget(group,w)w:initialise();self:addChild(w);self.groups[group][#self.groups[group]+1]=w;return w end
  local function button(group,x,y,w,label,fn)return widget(group,ISButton:new(x,y,w,28,label,self,fn))end
  local function tab(x,label,name,width)local b=ISButton:new(x,60,width or 125,28,label,self,function(s)if name=='admin'then s:updateAdmin(s.adminPricing)end;s:showTab(name)end);b:initialise();if name=='zone' or name=='admin'then b.backgroundColor={r=0,g=136/255,b=240/255,a=1};b.backgroundColorMouseOver={r=0,g=160/255,b=1,a=1};b.borderColor={r=0,g=240/255,b=248/255,a=1}end;self:addChild(b);return b end
  tab(20,'Vehicles','vehicles');tab(155,'Accessories','equipment');tab(290,'Trade-Ins','trade');tab(425,'My Audio','personal',110);tab(545,'Delivery Zone','zone');self.adminButton=tab(680,'Admin','admin');self.adminButton:setVisible(false)
  local cashItem=getScriptManager():getItem('Base.Money')
  self.cashBalanceIcon=cashItem and cashItem:getNormalTexture() or getTexture('Item_Money_Stack')
  self.bankBalanceIcon=getTexture('Item_Money_Stack')
  self.personalView=widget('personal',PersonalAudio.newPanel(self.player))
  self.selection=widget('vehicles',ISComboBox:new(20,105,440,28,self,function(s)s.quote=nil;s.confirm:setEnable(false);s:updateConfiguration();s:updatePaint();s:updatePreview()end))
  self.paint=widget('vehicles',ISComboBox:new(20,150,440,28,self,function(s)s.quote=nil;s.confirm:setEnable(false);s:updateEquipment();s:updatePreview()end));self.paint:addOption('Factory Appearance')
  self.search=widget('vehicles',ISTextEntryBox:new('',20,210,310,28))
  button('vehicles',340,210,120,'Search',function(s)s.query=s.search:getText();s.page=1;request(s,'open')end)
  button('vehicles',20,255,215,'Previous Page',function(s)s.page=math.max(1,(s.page or 1)-1);request(s,'open')end)
  button('vehicles',245,255,215,'Next Page',function(s)s.page=math.min(s.pages or 1,(s.page or 1)+1);request(s,'open')end)
  button('vehicles',20,350,440,'Refresh / Check Order',function(s)request(s,'open')end)
  button('vehicles',20,390,440,'Retry Recorded Delivery',function(s)request(s,'deliver')end)
  TradeSelection.create(self,widget,button,request)
  self.zoneDirection=widget('zone',ISComboBox:new(250,215,260,28,self,nil))
  for _,label in ipairs(Areas.labels)do self.zoneDirection:addOption(label)end
  self.zoneFields={}
  for i,key in ipairs({'x1','y1','x2','y2'})do
   self.zoneFields[key]=widget('zone',ISTextEntryBox:new('',20+(i-1)*235,290,215,28))
  end
  self.zoneGap=widget('zone',ISTextEntryBox:new('0',760,215,200,28))
  self.zoneGap.tooltip='Minimum clearance between vehicle footprints, in tiles. Decimals allowed. Includes diagonal headings; collision checks still apply.'
  self.zoneSave=button('zone',20,350,450,'Save Zone, Direction and Car Spacing',function(s)s:saveZone()end)
  self.zoneSelect=button('zone',490,350,470,'Select Rectangle on the Map',function(s)
   local gap,why=Areas.spacing(tonumber(s.zoneGap:getText()));if not tonumber(s.zoneGap:getText()) or gap==nil then s.message=why or 'Enter car spacing in tiles.';return end
   local p,terminal,heading=s.player,s.zoneTerminal,Areas.directions[s.zoneDirection.selected]
   local selected=s:effectiveOffer()
   require('TSBAstroluxVend/AreaCursor'):start(p,heading,function(ax,ay,bx,by)
    send(p,'areaSet',{terminal=terminal,ax=ax,ay=ay,bx=bx,by=by,heading=heading,gap=gap,confirmed=true})
   end,{gap=gap,script=selected and selected.script})
  end)
  button('zone',20,400,450,'Refresh Delivery Zone',function(s)request(s,'open')end)
  self.zoneShow=button('zone',490,400,470,'Preview Unsaved Parking Layout',function(s)
   s:previewZone()
  end)
  self.zoneBorder=widget('zone',ISTickBox:new(20,515,700,28,'AstroluxVisibleDeliveryBorder',self,function(s)request(s,'zoneBorder')end))
  self.zoneBorder:addOption('Visible Yellow Delivery Border');self.zoneBorder:setSelected(1,false)
  self.equipmentPage=1
  button('equipment',20,475,215,'Previous Accessories',function(s)s.equipmentPage=math.max(1,s.equipmentPage-1);s:showTab('equipment')end)
  button('equipment',245,475,215,'Next Accessories',function(s)s.equipmentPage=math.min(math.max(1,math.ceil(#s.equipmentRows/8)),s.equipmentPage+1);s:showTab('equipment')end)
  self.payment=widget('common',ISComboBox:new(20,510,440,28,self,function(s)s.quote=nil;s.confirm:setEnable(false);s.bankBalance=(s.bankBalances or {})[(s.paymentIDs or {})[s.payment.selected]] or s.bankBalance end));self.payment:addOption('Pay with carried cash');self.paymentIDs={'cash'}
  self.scene=ISUI3DScene:new(500,105,460,340);self.scene:initialise();self.scene:instantiate();self:addChild(self.scene)
  self.preview=Preview.new(self.scene);self.preview.enabled=Client.previewEnabled~=false
  button('common',500,510,220,'Toggle 3D preview',function(s)s.preview.enabled=not s.preview.enabled;Client.previewEnabled=s.preview.enabled;s:updatePreview()end)
  button('common',730,510,230,'Reset Preview / Fit Vehicle',function(s)s.preview:clear();s:updatePreview()end)
  self.getQuote=button('common',20,640,440,'Get Price Quote',function(s)request(s,'quote')end)
  self.confirm=button('common',500,640,460,'Confirm Purchase',function(s)
   -- Local UI feedback only; audio failure must never interrupt purchasing.
   require('TSBAstroluxVend/AudioSettings').playPurchase(s.player)
   request(s,'buy')
  end);self.confirm:setEnable(false)
  local close=ISButton:new(20,700,940,28,'Close',self,function(s)s:close()end);close:initialise();self:addChild(close)
  self:showTab('vehicles')
 end
 function Panel:showTab(tab)
  if self.personalView then if self.activeTab=='personal' and tab~='personal'then self.personalView:save()end;if tab=='personal'then self.personalView:refresh()end end
  if tab=='admin' and not self.adminPricing then tab='vehicles'end
  self.equipmentPage=math.max(1,math.min(self.equipmentPage or 1,math.max(1,math.ceil(#self.equipmentRows/8))))
  self.activeTab=tab
  for name,widgets in pairs(self.groups)do for _,w in ipairs(widgets)do w:setVisible(name==tab or (name=='common' and tab~='admin' and tab~='trade' and tab~='zone' and tab~='personal'))end end
  for i,row in ipairs(self.equipmentRows)do local w=self.equipmentControls[row.id]
   if w then w:setVisible(tab=='equipment' and math.floor((i-1)/8)+1==self.equipmentPage)end
  end
  if self.adminView then if tab~='admin' then self.adminView:stopAudioPreviews()end;self.adminView:setVisible(tab=='admin')end
  self.scene:setVisible(tab~='admin' and tab~='trade' and tab~='zone' and tab~='personal' and self.preview.enabled and self.preview.loaded==true)
 end
 function Panel:updateZone()
  self.zoneBorder:setSelected(1,self.deliveryBorder==true);self.zoneBorder.enable=self.adminPricing~=nil
  local a=self.spawnArea
  self.zoneGap:setText(tostring(a and a.gap or 0));self.zoneGap:setEditable(self.adminPricing~=nil)
  for key,w in pairs(self.zoneFields)do w:setText(tostring(a and a[key] or ''));w:setEditable(self.adminPricing~=nil)end
  for i,d in ipairs(Areas.directions)do if a and d==a.heading then self.zoneDirection.selected=i end end
  self.zoneDirection:setEnabled(self.adminPricing~=nil)
  self.zoneSave:setEnable(self.adminPricing~=nil);self.zoneSelect:setEnable(self.adminPricing~=nil)
 end
 function Panel:previewZone()
  if self.adminPricing then self:saveZone();return end
  if not self.spawnArea then self.message='No delivery zone configured.';return end
  local selected=self:effectiveOffer()
  require('TSBAstroluxVend/AreaCursor'):showZone(self.player,self.spawnArea,selected and selected.script)
 end
 function Panel:saveZone()
  local gap,why=Areas.spacing(tonumber(self.zoneGap:getText()));if not tonumber(self.zoneGap:getText()) or gap==nil then self.message=why or 'Enter car spacing in tiles.';return end
  local f=self.zoneFields
  local a,why=Areas.rectangle(tonumber(f.x1:getText()),tonumber(f.y1:getText()),tonumber(f.x2:getText()),tonumber(f.y2:getText()),Areas.directions[self.zoneDirection.selected],gap)
  if not a then self.message=why;return end
  local selected=self:effectiveOffer()
  require('TSBAstroluxVend/AreaCursor'):showZone(self.player,a,selected and selected.script,function()
  send(self.player,'areaSet',{terminal=self.zoneTerminal,ax=a.x1,ay=a.y1,bx=a.x2,by=a.y2,heading=a.heading,gap=gap,confirmed=true})
  end)
 end
 function Panel:updateConfiguration()
  local offer=self.offers and self.offers[self.selection.selected]
  self.configurationFamily=offer and offer.script;self.configurationRows=offer and offer.configurationOptions or {}
 end
 function Panel:getConfiguration()
  local paint=self.paintOptions and self.paintOptions[self.paint.selected]
  return paint and paint.configuration or nil
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
   local name=row.label:gsub('%S+',function(word)return word:sub(1,1):upper()..word:sub(2) end)
   local label=name..' (+$'..row.price..')'..((row.activeBonus or 0)>0 and ('; (+'..row.activeBonus..' Bed Capacity)') or '')
   local id=row.id
   local w=ISTickBox:new(20,130+((i-1)%8)*40,450,26,'AstroluxEquipment_'..id,self,function(s)
    local selected=s:getEquipment()
    if selected[id] and row.exclusiveGroup then
     for _,other in ipairs(s.equipmentRows)do if other.id~=id and other.exclusiveGroup==row.exclusiveGroup and s.equipmentControls[other.id]then s.equipmentControls[other.id]:setSelected(1,false)end end
     selected=s:getEquipment()
    end
    for _,dependent in ipairs(s.equipmentRows)do if dependent.requiresAny and selected[dependent.id]then
     local found=false;for _,other in ipairs(dependent.requiresAny)do if selected[other]then found=true end end
     if not found then s.equipmentControls[dependent.id]:setSelected(1,false);s.message='Select a supporting accessory before '..dependent.label..'.'end
    end end
    if row.requires and selected[id] and not selected[row.requires]then s.equipmentControls[id]:setSelected(1,false);s.message=row.label..' requires the camper top. Select the camper first.'end
    s.quote=nil;s.confirm:setEnable(false);s:updatePreview()
   end)
   w:initialise();w:addOption(label);w.tooltip=(row.effect or '')..(((row.capacityBonus or 0)>0 and (row.activeBonus or 0)==0) and ' <LINE> Added capacity buff is disabled.' or '');w:setSelected(1,keep[id]==true);self:addChild(w);self.equipmentControls[id]=w
  end
  local selected=self:getEquipment()
  for _,row in ipairs(self.equipmentRows)do if row.requiresAny and selected[row.id]then
   local found=false;for _,id in ipairs(row.requiresAny)do if selected[id]then found=true end end
   if not found then self.equipmentControls[row.id]:setSelected(1,false)end
  end end
  self:showTab(self.activeTab or 'vehicles')
 end
 function Panel:updatePaint()
  local offer=self.offers and self.offers[self.selection.selected]
  local old=self.paintOptions and self.paintOptions[self.paint.selected]
  local keep=old and self.paintScript==(offer and offer.script) and old.menuKey
  self.paintScript=offer and offer.script;self.paintOptions={};self.paint:clear();self.paint.selected=1
  local function addOptions(row,configuration)
   for _,option in ipairs(row.paintOptions or {})do
    local p={};for k,v in pairs(option)do p[k]=v end
    p.configuration=configuration;p.menuKey=(configuration or '')..':'..p.id
    self.paintOptions[#self.paintOptions+1]=p
    local label=p.id=='factory' and 'Factory Color' or p.label
    if configuration then label='Passenger Windows (6 Seats) / '..label end
    self.paint:addOption(label..((p.surcharge or 0)>0 and (' +$'..p.surcharge) or ' - included'))
    if keep==p.menuKey then self.paint.selected=#self.paintOptions end
   end
  end
  if offer then addOptions(offer,nil)end
  for _,row in ipairs(self.configurationRows or {})do addOptions(row,row.script)end
  if #self.paintOptions==0 then self.paint:addOption('Factory Appearance')end
  self:updateEquipment()
 end
 function Panel:updatePreview()
  local offer=self:effectiveOffer();local selected=self:getEquipment()
  local paint=self.paintOptions and self.paintOptions[self.paint.selected]
  if offer and paint and paint.script then local copy={};for k,v in pairs(offer)do copy[k]=v end;copy.script=paint.script;offer=copy end
  self.preview:show(offer,selected.camper,selected)
  self.getQuote:setEnable(offer~=nil and offer.available~=false)
  if self.activeTab=='admin' or self.activeTab=='trade' or self.activeTab=='zone' or self.activeTab=='personal'then self.scene:setVisible(false)end
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
   -- Keep the accepted size/right edge; shift the header down five pixels.
   local w,h=150*62/64,150*40/64
   local x,y=self.width-30-w,9
   -- The neon MOTORS subline loses definition when reduced to a few pixels.
   -- Clip that subline and use native UI glyphs at final display resolution.
   self:setStencilRect(x,y,w,74)
   self:drawTextureScaled(self.brandLogo,x,y,w,h,1,1,1,1)
   self:clearStencilRect()
   local label='M O T O R S'
   local textWidth=getTextManager():MeasureStringX(UIFont.Small,label)
   local bar=math.max(0,(w-textWidth)/2-9)
   self:drawTextCentre(label,x+w/2,y+76,1,0.25,0.12,1,UIFont.Small)
   if bar>0 then
    self:drawRect(x+3,y+83,bar,1,1,1,0.65,0.1)
    self:drawRect(x+w-3-bar,y+83,bar,1,1,1,0.65,0.1)
   end
  end
  self:drawText('Astrolux Motors',20,15,1,1,1,1,UIFont.Medium)
  local function balanceCard(x,label,value,icon)
   local w,h=230,48
   self:drawRect(x,7,w,h,0.9,0.015,0.045,0.065)
   self:drawRectBorder(x,7,w,h,0.8,0,136/255,240/255)
   self:drawRect(x,7,3,h,1,0,240/255,248/255)
   self:drawText(label,x+11,9,0.55,0.85,0.95,1,UIFont.Small)
   if icon then self:drawTextureScaledAspect(icon,x+10,28,24,24,1,1,1,1)end
   local amount=value~=nil and tostring(value) or '?'
   if amount:match('^%d+$')then amount=amount:reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')end
   amount='$'..amount
   local font=UIFont.Large
   if getTextManager():MeasureStringX(font,amount)>w-(icon and 52 or 22) then font=UIFont.Medium end
   self:drawTextRight(amount,x+w-10,25,0.88,0.98,1,1,font)
  end
  local balanceX=(self.width-(self.bankAvailable and 472 or 230))/2
  balanceCard(balanceX,'CASH',self.balance,self.cashBalanceIcon)
  if self.bankAvailable then balanceCard(balanceX+242,'BANK',self.bankBalance,self.bankBalanceIcon)end
  if self.activeTab=='zone'then
   local a=self.spawnArea
   self:drawText('Vehicle Delivery and Trade-In Zone',20,115,1,1,1,1,UIFont.Medium)
   self:drawText(a and ('Saved rectangle: '..a.x1..', '..a.y1..' to '..a.x2..', '..a.y2..' | '..(a.x2-a.x1+1)..' x '..(a.y2-a.y1+1)..' tiles') or 'No delivery zone configured for this kiosk.',20,155,0.9,0.9,0.9,1,UIFont.Small)
   self:drawText(self.adminPricing and 'Choose vehicle direction, then select the area on the map or enter its corners.' or 'An administrator can change this zone.',20,185,0.9,0.9,0.9,1,UIFont.Small)
   self:drawText('Gap between cars (tiles)',525,220,1,1,1,1,UIFont.Small)
   self:drawText('New Vehicles Face',20,220,1,1,1,1,UIFont.Small)
   for i,label in ipairs({'Corner 1 X','Corner 1 Y','Corner 2 X','Corner 2 Y'})do self:drawText(label,20+(i-1)*235,265,1,1,1,1,UIFont.Small)end
   self:drawText('Ground floor only. Changing direction affects future deliveries.',20,455,0.8,0.8,0.8,1,UIFont.Small)
   self:drawText('Resolve outstanding purchases before changing the zone. Unpaid quotes are cancelled.',20,480,0.8,0.8,0.8,1,UIFont.Small)
  elseif self.activeTab=='trade'then
   TradeSelection.render(self)
  elseif self.activeTab~='admin' and self.activeTab~='personal'then
   local offer=self.offers and self.offers[self.selection.selected]
   if self.activeTab=='equipment'then
    self:drawText(offer and offer.name or 'Choose a vehicle in the Vehicles tab.',20,103,1,1,1,1,UIFont.Small)
    if #self.equipmentRows==0 then self:drawText('No compatible optional equipment is offered for this vehicle.',20,145,0.9,0.85,0.6,1,UIFont.Small)end

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
