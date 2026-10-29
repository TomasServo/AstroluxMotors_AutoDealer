require 'ISUI/ISComboBox'
require 'ISUI/ISPanel'
require 'ISUI/ISTickBox'
require 'ISUI/ISButton'
require 'RadioCom/ISUIRadio/ISSliderPanel'
local Prefs=require 'TSBAstroluxVend/PersonalAudioSettings'
local Audio=require 'TSBAstroluxVend/AudioSettings'
local Reporting=require 'TSBAstroluxVend/ReportingLink'
local A=ISPanel:derive('TSBAstroluxPersonalAudio')
function A:createChildren()
 ISPanel.createChildren(self);self.pending={};self.sliders={};self.mutes={}
 for i,row in ipairs({{key='purchaseVolume',mute='mutePurchase',label='Mute Purchase Button / Trade-In Sound'},
  {key='musicVolume',mute='muteMusic',label='Mute Showroom Music'},
  {key='doorVolume',mute='muteDoor',label='Mute Sliding Doors'}})do
  local y=55+(i-1)*90
  local tick=ISTickBox:new(10,y,390,28,'Personal'..row.mute,self,function(p)p:save()end)
  tick:initialise();tick:addOption(row.label);self:addChild(tick);self.mutes[row.mute]=tick
  local slider=ISSliderPanel:new(410,y,350,28,self,function(p,value)
   if p.ready then p.pending[row.key]=value;p.due=getTimestampMs()+300 end
  end)
  slider:initialise();slider:setValues(0,100,1,10);self:addChild(slider);self.sliders[row.key]=slider
  for _,method in ipairs({'onMouseUp','onMouseUpOutside'})do
   local original=slider[method]
   slider[method]=function(w,...)
    original(w,...);self:save()
   end
  end
 end
 self.track=ISComboBox:new(210,295,350,28,self,function(p)if p.ready then p.pending.musicTrack=p.track.selected-1;p:save()end end)
 self.track:initialise();self.track:addOption('World Default');self.track:addOption('Lounge');self.track:addOption('Elevator');self:addChild(self.track)
 local reset=ISButton:new(10,350,350,28,'Reset Audio Defaults',self,function(p)
  if Prefs.save(p.player,{})then p.pending={};p.due=nil;p:refresh();Audio.refreshPurchase(p.player)
  else p.message='Could not save personal audio preferences.'end
 end)
 reset:initialise();self:addChild(reset)
 self.reportButton=ISButton:new(410,342,510,48,'REPORT A BUG / SEND FEEDBACK',self,function(p)Reporting.open(p.player)end)
 self.reportButton:initialise()
 self.reportButton.backgroundColor={r=0,g=0.42,b=0.58,a=1}
 self.reportButton.backgroundColorMouseOver={r=0,g=0.62,b=0.78,a=1}
 self.reportButton.borderColor={r=0,g=0.95,b=1,a=1}
 self.reportButton.textColor={r=1,g=1,b=1,a=1}
 self.reportButton.tooltip='Open the private reporting form in the Steam overlay browser. Nothing is submitted by clicking this button.'
 self:addChild(self.reportButton);self:refresh()
end
function A:refresh()
 if not self.sliders or not self.sliders.purchaseVolume then return end
 if self.ready then for _ in pairs(self.pending)do return end end
 self.ready=false
 local prefs=Prefs.get(self.player)
 for key,slider in pairs(self.sliders)do slider:setCurrentValue(prefs[key] or math.floor(Prefs.defaultVolume(key)*100+0.5),true)end
 for key,tick in pairs(self.mutes)do tick:setSelected(1,prefs[key]==true)end
 self.track.selected=(prefs.musicTrack or 0)+1
 self.ready=true
end
function A:save()
 if not self.ready then return end
 self.due=nil
 local values={};for k,v in pairs(Prefs.get(self.player))do values[k]=v end
 for key,value in pairs(self.pending)do values[key]=value end
 if values.musicTrack==0 then values.musicTrack=nil end
 for key,tick in pairs(self.mutes)do values[key]=tick:isSelected(1)end
 if Prefs.save(self.player,values)then self.pending={};self.message=nil;Audio.refreshPurchase(self.player)
 else self.message='Could not save personal audio preferences.'end
end
function A:update()
 ISPanel.update(self)
 if not self.due or getTimestampMs()<self.due then return end
 for _,slider in pairs(self.sliders)do if slider.dragInside or slider.leftPressed or slider.rightPressed then return end end
 self:save()
end
function A:prerender()
 ISPanel.prerender(self)
 self:drawText('Showroom Track',10,300,1,1,1,1,UIFont.Small)
 self:drawText('Settings',10,10,1,1,1,1,UIFont.Medium)
 self:drawText('Volumes are percentages of the admin level. 100% uses the full admin volume.',10,35,0.8,0.8,0.8,1,UIFont.Small)
 for i,key in ipairs({'purchaseVolume','musicVolume','doorVolume'})do
  self:drawText(tostring(self.sliders[key]:getCurrentValue())..'%',780,60+(i-1)*90,1,1,1,1,UIFont.Small)
 end
 if self.message then self:drawText(self.message,10,390,1,0.7,0.4,1,UIFont.Small)end
end
function A.newPanel(player)
 local p=A:new(20,105,940,440);p.player=player;return p
end
return A
