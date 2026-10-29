if isClient() then return end
local W=require 'AstroluxBayTest/TestWorld'
local B=require 'AstroluxBayTest/ShowroomBuilder12'
local F=require 'AstroluxBayTest/ShowroomFurnishings12'
local C=require 'AstroluxBayTest/SiteClearance'
local M={}
function M.profile()
 local saved=ModData.getOrCreate('TSBAstroluxStructure.DecorDefaults.v1').profile
 local source=saved or require('TSBAstroluxStructure/DefaultFurnishings12')
 local profile={};for k,v in pairs(source)do if k~='objects' then profile[k]=v end end
 profile.objects={}
 for _,entry in ipairs(source.objects)do
  -- Fixed fixtures are installed and linked by ShowroomLights at the new site.
  if entry.sprite~='TSBAstroluxCeiling_0' and entry.sprite~='TSBAstroluxCeilingSwitch_0' then
   profile.objects[#profile.objects+1]=entry
  end
 end
 return profile
end
function M.preview(player,x,y,clear)
 if not (W.city() or W.corner()) then return nil,'Only available in the separate single-player debug test worlds.' end
 local status=ModData.get('TSBAstroluxCityPerformance.v1')
 if status and status.recordId and not W.corner() then return nil,'A performance showroom is already registered in this copy.' end
 local review,why=C.inspect(player,x,y,clear)
 if not review then return nil,why end
 local plan=review.plan
 local profile=M.profile()
 local prepared,reason=F.prepare({x=x,y=y,replacementProfile=profile})
 if not prepared then return nil,reason end
 return plan,nil,profile,review
end
function M.place(player,x,y,approved)
 if not approved or approved.x~=x or approved.y~=y then return nil,'Review and confirm the placement zone first.'end
 local plan,why,profile=M.preview(player,x,y,approved.clear)
 if not plan then return nil,why end
 local record,reason=C.execute(player,approved,function()
  return B.place(player,x,y,{multiple=true,furnished=true,profile=profile})
 end)
 if not record then return nil,reason end
 if W.freshLot() and profile.migrationSource then
  record.automaticDoorsEnabled=profile.migrationSource.automaticDoorsEnabled==true
 end
 local state=ModData.getOrCreate('TSBAstroluxCombined12.v1')
 local city=ModData.getOrCreate('TSBAstroluxCityPerformance.v1')
 city.previous={};for k,v in pairs(state)do city.previous[k]=v end
 -- Do not inherit the old site's fixture migration flags or object references.
 local keys={};for k in pairs(state)do keys[#keys+1]=k end
 for _,k in ipairs(keys)do state[k]=nil end
 state.x=x;state.y=y;state.recordId=record.id;state.ready=true
 city.recordId=record.id;city.x=x;city.y=y
 print('[Astrolux City Test] Active showroom '..record.id..' at '..x..','..y..'; original showroom retained.')
 return record
end
return M
