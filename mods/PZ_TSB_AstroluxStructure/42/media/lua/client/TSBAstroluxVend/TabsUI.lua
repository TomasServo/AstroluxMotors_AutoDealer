local Access=require 'TSBAstroluxVend/AdminAccess'
require 'RadioCom/ISUIRadio/ISSliderPanel'
local Preview=require 'TSBAstroluxVend/Preview'
local Admin=require 'TSBAstroluxVend/AdminPricing'
local Areas=require 'TSBAstroluxVend/SpawnAreas'
local TradeSelection=require 'TSBAstroluxVend/TradeSelection'
local PersonalAudio=require 'TSBAstroluxVend/PersonalAudioPanel'
local U={}
function U.install(Panel,request,send,Client)
 function Panel:selectZone(editSaved)
  local s=self
  if not s.adminPricing or not Access.allowed(s.player)then s.message='Administrator access required.';return end
   local gap,why=Areas.spacing(tonumber(s.zoneGap:getText()));if not tonumber(s.zoneGap:getText()) or gap==nil then s.message=why or 'Enter car spacing in tiles.';return end
   local rows=tonumber(s.zoneRowGap:getText());if not rows or Areas.spacing(rows)==nil then s.message='Enter a non-negative row gap.';return end
   local p,terminal,heading=s.player,s.zoneTerminal,Areas.directions[s.zoneDirection.selected]
   local selected=s:effectiveOffer()
   if editSaved and not s.spawnArea then s.message='No saved delivery zone to edit.';return end
   s:setVisible(false)
   require('TSBAstroluxVend/AreaCursor'):start(p,heading,function(ax,ay,bx,by)
    send(p,'areaSet',{terminal=terminal,ax=ax,ay=ay,bx=bx,by=by,heading=heading,gap=gap,rowGap=rows,confirmed=true})
   end,{gap=gap,rowGap=rows,script=selected and selected.script,initialArea=editSaved and s.spawnArea or nil,
    finish=function()s:setVisible(true);s:bringToTop()end})
 end
 function Panel:createChildren()
  ISPanel.createChildren(self);self.brandLogo=getTexture('media/textures/TSBAstroluxMenuLogo.png');self.groups={vehicles={},equipment={},trade={},zone={},personal={},common={}};self.equipmentControls={};self.equipmentRows={};self.equipmentSelection={}
  local function widget(group,w)w:initialise();self:addChild(w);self.groups[group][#self.groups[group]+1]=w;return w end
  local function button(group,x,y,w,label,fn)return widget(group,ISButton:new(x,y,w,28,label,self,fn))end
  local function tab(x,label,name,width)local b=ISButton:new(x,60,width or 125,28,label,self,function(s)if name=='admin'then s:updateAdmin(s.adminPricing)end;s:showTab(name)end);b:initialise();if name=='zone' or name=='admin'then b.backgroundColor={r=0,g=136/255,b=240/255,a=1};b.backgroundColorMouseOver={r=0,g=160/255,b=1,a=1};b.borderColor={r=0,g=240/255,b=248/255,a=1}end;self:addChild(b);return b end
  tab(20,'Vehicles','vehicles');tab(155,'Accessories','equipment');tab(290,'Trade-Ins','trade');tab(425,'Settings','personal',110);self.zoneButton=tab(545,'Delivery Zone','zone');self.zoneButton:setVisible(false);self.zoneButton:setVisible(false);self.adminButton=tab(680,'Admin','admin');self.adminButton:setVisible(false)
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
  -- Immediate purchases only; there is no queued-delivery retry control.
  TradeSelection.create(self,widget,button,request)
  self.zoneDirection=widget('zone',ISComboBox:new(250,215,260,28,self,function(s)if s.zoneView and s.zoneView:isSelected(1) then s:previewZone()end end))
  for _,label in ipairs(Areas.labels)do self.zoneDirection:addOption(label)end
  self.zoneFields={}
  for i,key in ipairs({'x1','y1','x2','y2'})do
   self.zoneFields[key]=widget('zone',ISTextEntryBox:new('',20+(i-1)*235,310,215,28))
  end
  self.zoneGap=widget('zone',ISTextEntryBox:new('0',850,245,110,28))
  self.zoneGap.target=self
  self.zoneGap.onTextChangeFunction=function(s,entry)
   local gap=tonumber(entry:getText())
   if gap and Areas.spacing(gap)~=nil and s.zoneGapSlider then
    s.zoneGapSlider:setValues(0,math.max(10,gap),0.1,1,true);s.zoneGapSlider:setCurrentValue(gap,true)
   end
   if s.activeTab=='zone' and s.adminPricing and s.zoneView and s.zoneView:isSelected(1)
      and gap and Areas.spacing(gap)~=nil then s:previewZone()end
  end
  self.zoneGapSlider=widget('zone',ISSliderPanel:new(525,245,310,28,self,function(p,value)
   if not p.adminPricing then return end
   p.zoneGap:setText(string.format('%.1f',value));p.zoneGap:onTextChange()
  end))
  self.zoneGapSlider:setValues(0,10,0.1,1,true)
  for _,method in ipairs({'onMouseDown','onMouseMove','onMouseWheel','onJoypadDirLeft','onJoypadDirRight'})do
   local original=self.zoneGapSlider[method]
   if original then self.zoneGapSlider[method]=function(w,...)if self.adminPricing then return original(w,...)end end end
  end
  self.zoneApplyGap=button('zone',490,610,470,'Apply Spacing',function(p)
   if not p.adminPricing or not p.spawnArea then return end
   local gap,why=Areas.spacing(tonumber(p.zoneGap:getText()))
   if not tonumber(p.zoneGap:getText()) or gap==nil then p.message=why or 'Enter car spacing in tiles.';return end
   local rows=tonumber(p.zoneRowGap:getText());if not rows or Areas.spacing(rows)==nil then p.message='Enter a non-negative row gap.';return end
   local args={gap=gap,rowGap=rows,revision=p.spawnArea.revision or 0}
   for k,v in pairs(p.location)do args[k]=v end
   send(p.player,'areaGap',args)
  end)
  self.zoneRowGap=widget('zone',ISTextEntryBox:new('0',450,245,60,28))
  self.zoneRowGap.target=self
  self.zoneRowGap.onTextChangeFunction=function(p,entry)
   local n=tonumber(entry:getText());if not n or Areas.spacing(n)==nil then return end
   p.zoneRowSlider:setValues(0,math.max(10,n),0.1,1,true);p.zoneRowSlider:setCurrentValue(n,true)
   if p.activeTab=='zone' and p.adminPricing and p.zoneView and p.zoneView:isSelected(1)then p:previewZone()end
  end
  self.zoneRowSlider=widget('zone',ISSliderPanel:new(180,245,260,28,self,function(p,value)
   if not p.adminPricing then return end
   p.zoneRowGap:setText(string.format('%.1f',value));p.zoneRowGap:onTextChange()
  end))
  self.zoneRowSlider:setValues(0,10,0.1,1,true)
  for _,method in ipairs({'onMouseDown','onMouseMove','onMouseWheel','onJoypadDirLeft','onJoypadDirRight'})do
   local original=self.zoneRowSlider[method]
   if original then self.zoneRowSlider[method]=function(w,...)if self.adminPricing then return original(w,...)end end end
  end
  self.zoneRowGap.tooltip='Minimum bumper-to-bumper clearance between rows, in tiles. Apply Spacing saves both gaps.'
  self.zoneGap.tooltip='Minimum side-to-side clearance between cars, in tiles. Apply Spacing saves both gaps.'
  self.zoneSave=button('zone',20,350,450,'Save Zone, Direction & Car Spacing',function(s)s:saveZone()end)
  self.zoneSelect=button('zone',490,350,470,'Select Rectangle on the Map',function(s)s:selectZone()end)
  button('zone',20,400,450,'Refresh Delivery Zone',function(s)request(s,'open')end)
  self.zoneShow=button('zone',490,400,470,'Preview Unsaved Parking Layout',function(s)
   s:previewZone()
  end)
  self.zoneBorder=widget('zone',ISTickBox:new(20,515,450,28,'AstroluxVisibleDeliveryBorder',self,function(s)request(s,'zoneBorder')end))
  self.zoneBorder:addOption('Visible Yellow Delivery Border');self.zoneBorder:setSelected(1,false)
  self.zoneNumber=widget('zone',ISTickBox:new(490,515,470,28,'AstroluxVisibleDeliveryNumber',self,function(s)request(s,'zoneNumber')end))
  self.zoneNumber:addOption('Visible Yellow Delivery Number');self.zoneNumber:setSelected(1,true)
  self.zoneEdit=button('zone',20,550,450,'Edit Saved Zone',function(s)
   s.message='Edit the saved rectangle, then confirm to replace it.'
   s:selectZone(true)
  end)
  self.zoneView=widget('zone',ISTickBox:new(490,550,470,28,'AstroluxViewDeliveryZone',self,function(s)
   s.zoneViewArea=s.spawnArea
  end))
  self.zoneView:addOption('View Delivery Zone');self.zoneView:setSelected(1,false)
  self.zoneDelete=button('zone',20,610,450,'Delete Delivery Zone',function(s)
   if not s.spawnArea or not s.adminPricing then return end
   require 'ISUI/ISModalRichText'
   local args={confirmed=true,revision=s.spawnArea.revision or 0}
   for k,v in pairs(s.location)do args[k]=v end
   local submitted=false
   local modal=ISModalRichText:new(100,100,620,220,'Delete this kiosk delivery zone? <LINE> The yellow border will be removed. Vehicles stay where they are. New purchases require a new zone. Outstanding orders must be resolved first.',true,nil,function(_,b)
    if b.internal=='YES' and not submitted then submitted=true;send(s.player,'areaDelete',args)end
   end,s.player:getPlayerNum())
   modal:initialise();modal:addToUIManager();modal:bringToTop()
  end)
  self.zoneView.tooltip='Local saved-zone overlay while this tab is open. Does not change the yellow border or save edits.'
  self.equipmentPage=1
  button('equipment',20,475,215,'Previous Accessories',function(s)s.equipmentPage=math.max(1,s.equipmentPage-1);s:showTab('equipment')end)
  button('equipment',245,475,215,'Next Accessories',function(s)s.equipmentPage=math.min(math.max(1,math.ceil(#s.equipmentRows/8)),s.equipmentPage+1);s:showTab('equipment')end)
  self.payment=widget('common',ISComboBox:new(20,510,440,28,self,function(s)s.quote=nil;s.confirm:setEnable(false);s.bankBalance=(s.bankBalances or {})[(s.paymentIDs or {})[s.payment.selected]] or s.bankBalance end));self.payment:addOption('Pay with carried cash');self.paymentIDs={'cash'}
  self.scene=ISUI3DScene:new(500,105,460,340);self.scene:initialise();self.scene:instantiate();self:addChild(self.scene)
  self.preview=Preview.new(self.scene);self.preview.enabled=Client.previewEnabled~=false
  button('common',500,510,220,'Toggle 3D Preview',function(s)s.preview.enabled=not s.preview.enabled;Client.previewEnabled=s.preview.enabled;s:updatePreview()end)
  button('common',730,510,230,'Reset Preview / Fit Vehicle',function(s)s.preview:clear();s:updatePreview()end)
  self.getQuote=button('common',20,640,440,'Get Price Quote',function(s)request(s,'quote')end)
  self.confirm=button('common',500,640,460,'Confirm Purchase',function(s)
   -- Local UI feedback only; audio failure must never interrupt purchasing.
   require('TSBAstroluxVend/AudioSettings').playPurchase(s.player)
   request(s,'buy')
  end)
  self.confirm:setBackgroundRGBA(0.08,0.38,0.12,1)
  self.confirm:setBackgroundColorMouseOverRGBA(0.12,0.52,0.18,1)
  self.confirm:setBorderRGBA(0.25,0.75,0.32,1)
  self.confirm:setEnable(false)
  local close=ISButton:new(20,700,940,28,'Close',self,function(s)s:close()end);close:initialise();self:addChild(close)
  self:showTab('vehicles')
 end
 function Panel:showTab(tab)
  if self.personalView then if self.activeTab=='personal' and tab~='personal'then self.personalView:save()end;if tab=='personal'then self.personalView:refresh()end end
  if (tab=='admin'or tab=='zone')and (not self.adminPricing or not Access.allowed(self.player))then tab='vehicles'end
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
  self.zoneView.enable=self.spawnArea~=nil
  self.zoneViewArea=self.spawnArea
  if not self.spawnArea then self.zoneView:setSelected(1,false)end
  self.zoneEdit:setEnable(self.adminPricing~=nil and self.spawnArea~=nil)
  self.zoneNumber:setSelected(1,self.deliveryNumber~=false);self.zoneNumber.enable=self.adminPricing~=nil and self.spawnArea~=nil
  self.zoneBorder:setSelected(1,self.deliveryBorder==true);self.zoneBorder.enable=self.adminPricing~=nil and self.spawnArea~=nil
  self.zoneBorder.tooltip=self.spawnArea and 'Show the saved delivery zone border.' or 'Save a delivery zone before enabling its border.'
  local a=self.spawnArea
  self.zoneRowGap:setText(tostring(a and (a.rowGap or a.gap) or 0));self.zoneRowGap:setEditable(self.adminPricing~=nil)
  local rows=a and (a.rowGap or a.gap) or 0;self.zoneRowSlider:setValues(0,math.max(10,rows),0.1,1,true);self.zoneRowSlider:setCurrentValue(rows,true)
  self.zoneGap:setText(tostring(a and a.gap or 0));self.zoneGap:setEditable(self.adminPricing~=nil)
  for key,w in pairs(self.zoneFields)do w:setText(tostring(a and a[key] or ''));w:setEditable(self.adminPricing~=nil)end
  for i,d in ipairs(Areas.directions)do if a and d==a.heading then self.zoneDirection.selected=i end end
  self.zoneDirection:setEnabled(self.adminPricing~=nil)
  self.zoneSave:setEnable(self.adminPricing~=nil);self.zoneSelect:setEnable(self.adminPricing~=nil)
  self.zoneDelete:setEnable(self.adminPricing~=nil and a~=nil)
  self.zoneApplyGap:setEnable(self.adminPricing~=nil and a~=nil)
  local gap=a and a.gap or 0;self.zoneGapSlider:setValues(0,math.max(10,gap),0.1,1,true);self.zoneGapSlider:setCurrentValue(gap,true)
 end
 function Panel:previewZone()
  local a=self.spawnArea
  if self.adminPricing then
   local f=self.zoneFields
   local why
   a,why=Areas.rectangle(tonumber(f.x1:getText()),tonumber(f.y1:getText()),tonumber(f.x2:getText()),tonumber(f.y2:getText()),Areas.directions[self.zoneDirection.selected],tonumber(self.zoneGap:getText()),tonumber(self.zoneRowGap:getText()))
   if not tonumber(self.zoneGap:getText()) or not tonumber(self.zoneRowGap:getText()) then a=nil;why='Enter both spacing values in tiles.'end
   if not a then self.message=why;return end
  end
  if not a then self.message='No delivery zone configured.';return end
  self.zoneViewArea=a;self.zoneView:setSelected(1,true)
  self.message='Viewing layout only; nothing saved. Vehicles face '..a.heading..'; gap '..tostring(a.gap or 0)..' tiles.'
 end
 function Panel:saveZone()
  local rows=tonumber(self.zoneRowGap:getText());if not rows or Areas.spacing(rows)==nil then self.message='Enter a non-negative row gap.';return end
  local gap,why=Areas.spacing(tonumber(self.zoneGap:getText()));if not tonumber(self.zoneGap:getText()) or gap==nil then self.message=why or 'Enter car spacing in tiles.';return end
  local f=self.zoneFields
  local a,why=Areas.rectangle(tonumber(f.x1:getText()),tonumber(f.y1:getText()),tonumber(f.x2:getText()),tonumber(f.y2:getText()),Areas.directions[self.zoneDirection.selected],gap,rows)
  if not a then self.message=why;return end
  local selected=self:effectiveOffer()
  require('TSBAstroluxVend/AreaCursor'):showZone(self.player,a,selected and selected.script,function()
  send(self.player,'areaSet',{terminal=self.zoneTerminal,ax=a.x1,ay=a.y1,bx=a.x2,by=a.y2,heading=a.heading,gap=gap,rowGap=rows,confirmed=true})
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
  local target=self:getConfiguration()
  if target then for _,row in ipairs(self.configurationRows or {})do if row.script==target then return row end end;return nil end
  return offer
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
   local description=(row.effect and row.effect~='') and row.effect or ('Optional equipment for this vehicle: '..name..'.')
   if row.discovered then description=description..' <LINE> Detected from the installed vehicle mod; enabled and priced by the server administrator.'end
   if row.exclusiveGroup then description=description..' <LINE> Choosing this replaces another option in the same mounting slot.'end
   if row.requiresAny then description=description..' <LINE> Requires a compatible supporting accessory.'end
   w:initialise();w:addOption(label);w.tooltip=description..(((row.capacityBonus or 0)>0 and (row.activeBonus or 0)==0) and ' <LINE> Added capacity buff is disabled.' or '');w:setSelected(1,keep[id]==true);self:addChild(w);self.equipmentControls[id]=w
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
    if configuration then label=(row.label or row.name or configuration)..' / '..label
    elseif row.modelScript and row.modelScript~=row.script then label=(row.script:match('%.(.+)$') or row.script)..' / '..label end
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
  if not Access.allowed(self.player)then self.adminPricing=nil end
  local allowed=self.adminPricing~=nil and Access.allowed(self.player)
  self.adminButton:setVisible(allowed);self.zoneButton:setVisible(allowed)
  if not allowed and (self.activeTab=='admin'or self.activeTab=='zone')then self:showTab('vehicles')end
  if not Access.allowed(self.player)then self.adminPricing=nil end
  local allowed=self.adminPricing~=nil and Access.allowed(self.player)
  self.adminButton:setVisible(allowed);self.zoneButton:setVisible(allowed)
  if not allowed and (self.activeTab=='admin'or self.activeTab=='zone')then self:showTab('vehicles')end
  ISPanel.prerender(self)
  if self.brandLogo then
   -- Fit the complete current logo without cropping its MOTORS subline.
   local w=150
   local h=w*self.brandLogo:getHeight()/self.brandLogo:getWidth()
   -- Center the visible ink in the 100px header; source has 23px top padding.
   local x,y=self.width-20-w,(100-h)/2-h*23/(2*887)
   self:drawTextureScaled(self.brandLogo,x,y,w,h,1,1,1,1)
  end
  self:drawText('Astrolux Motors',20,8,1,1,1,1,UIFont.Medium)
  self:drawText('Kiosk '..tostring(self.displayNumber or '?'),20,31,.35,.85,1,1,UIFont.Large)
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
   -- Render without a full-screen UI element: fields and buttons stay interactive.
   local viewed=self.zoneViewArea
   if self.zoneView:isSelected(1) and viewed then
    addAreaHighlightForPlayer(self.player:getPlayerNum(),viewed.x1,viewed.y1,viewed.x2+1,viewed.y2+1,0,0.1,0.9,0.8,0.5)
    local selected=self:effectiveOffer()
    local failed,count,limited=require('TSBAstroluxVend/AreaCursor').drawEmbedded(self,viewed,selected and selected.script)
    self:drawText(failed and 'Vehicle geometry unavailable.' or ('Preview: '..tostring(count)..' spaces'..(limited and ' (preview limit reached)' or '')),20,435,1,.85,.3,1,UIFont.Small)
   end
   local a=self.spawnArea
   self:drawText('Vehicle Delivery and Trade-In Zone',20,115,1,1,1,1,UIFont.Medium)
   self:drawText(a and ('Delivery Zone '..tostring(self.displayNumber or '?')..' | Saved rectangle: '..a.x1..', '..a.y1..' to '..a.x2..', '..a.y2..' | '..(a.x2-a.x1+1)..' x '..(a.y2-a.y1+1)..' tiles') or 'No delivery zone configured for this kiosk.',20,155,0.9,0.9,0.9,1,UIFont.Small)
   self:drawText(self.adminPricing and 'Choose vehicle direction, then select the area on the map or enter its corners.' or 'An administrator can change this zone.',20,185,0.9,0.9,0.9,1,UIFont.Small)
   self:drawText('Gap between cars (tiles)',525,220,1,1,1,1,UIFont.Small)
   self:drawText('Gap Between Rows',20,250,1,1,1,1,UIFont.Small)
   self:drawText('New Vehicles Face',20,220,1,1,1,1,UIFont.Small)
   for i,label in ipairs({'Corner 1 X','Corner 1 Y','Corner 2 X','Corner 2 Y'})do self:drawText(label,20+(i-1)*235,285,1,1,1,1,UIFont.Small)end
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
    local configuration=self:getConfiguration() and self:effectiveOffer()
    if configuration then self:drawText('Selected variant: $'..configuration.price..' before paint/accessories',20,435,0.8,0.8,0.8,1,UIFont.Small)end
   end
   local status=self.preview.loaded and '3D model: factory appearance; accessories may differ.' or (self.preview.status or '')
   self:drawText(status,500,455,0.8,0.8,0.8,1,UIFont.Small)
   require('TSBAstroluxVend/PaintSwatch').draw(self,self.paintOptions and self.paintOptions[self.paint.selected])
  end
  -- Zone controls extend to y=578; reserve a separate status area below them.
  local line,y='',self.activeTab=='zone' and 590 or 565
  local messageBottom=self.activeTab=='zone' and 640 or 615
  for word in tostring(self.message or ''):gmatch('%S+')do
   local nextLine=line=='' and word or line..' '..word
   if getTextManager():MeasureStringX(UIFont.Small,nextLine)>930 then self:drawText(line,20,y,1,0.9,0.7,1,UIFont.Small);line=word;y=y+16 else line=nextLine end
   if y>messageBottom then break end
  end
  self:drawText(line,20,y,1,0.9,0.7,1,UIFont.Small)
  self:drawText('Keep the designated vehicle delivery area clear.',20,675,0.85,0.85,0.7,1,UIFont.Small)
 end
end
return U
