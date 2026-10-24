local A={}
local function signature(p)
 return tostring(p.purchaseSound:isSelected(1))..':'..tostring(p.showroomMusic:isSelected(1))..':'..p.purchaseVolume:getCurrentValue()..':'..p.musicVolume:getCurrentValue()..':'..tostring(p.doorSound:isSelected(1))..':'..p.doorVolume:getCurrentValue()
end
function A.save(p)
 if not p.audioAutosaveReady then return end
 p.audioSaveDue=nil
 local value=signature(p)
 if value==p.audioLastSent then return end
 p.audioLastSent=value
 p:submit('audio')
end
function A.install(p)
 p.audioLastSent=signature(p);p.audioAutosaveReady=true
 for _,slider in ipairs({p.purchaseVolume,p.musicVolume,p.doorVolume})do
  local changed=slider.onValueChange
  slider.onValueChange=function(target,value,widget)
   if changed then changed(target,value,widget)end
   p.audioSaveDue=getTimestampMs()+300
  end
  for _,method in ipairs({'onMouseUp','onMouseUpOutside'})do
   local previous=slider[method]
   slider[method]=function(widget,...)
    if previous then previous(widget,...)end
    A.save(p)
   end
  end
 end
 local update=p.update
 p.update=function(panel,...)
  if update then update(panel,...)end
  if panel.audioSaveDue and getTimestampMs()>=panel.audioSaveDue then
   for _,slider in ipairs({panel.purchaseVolume,panel.musicVolume,panel.doorVolume})do
    if slider.dragInside or slider.leftPressed or slider.rightPressed then return end
   end
   A.save(panel)
  end
 end
 local stop=p.stopAudioPreviews
 p.stopAudioPreviews=function(panel,...)
  A.save(panel)
  if stop then stop(panel,...)end
 end
end
return A
