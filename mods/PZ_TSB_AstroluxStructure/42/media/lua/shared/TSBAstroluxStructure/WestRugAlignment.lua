local M={}
local names={'TSBAstroluxLogoRug_4','TSBAstroluxLogoRug_5'}
function M.normalize(entries,x,y,relative)
 if type(entries)~='table'then return false end
 local found={};local xk,yk=relative and 'dx' or 'x',relative and 'dy' or 'y'
 for _,v in pairs(entries)do for i,name in ipairs(names)do
  if v.sprite==name and v[xk]==x then
   if found[i]then return false end
   found[i]=v
  end
 end end
 if not found[1] or not found[2] or found[1][yk]~=y+4 or found[2][yk]~=y+5 then return false end
 found[1][yk]=y+5;found[2][yk]=y+6;return true
end
function M.record(r)
 M.normalize(r.entranceRugs and r.entranceRugs.west,r.x,r.y,false)
 M.normalize(r.hiddenEntranceRugs and r.hiddenEntranceRugs.west,r.x,r.y,false)
 M.normalize(r.replacementProfile and r.replacementProfile.objects,0,0,true)
end
return M
