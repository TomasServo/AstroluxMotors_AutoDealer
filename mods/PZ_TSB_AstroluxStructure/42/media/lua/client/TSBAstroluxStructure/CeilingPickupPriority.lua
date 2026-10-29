-- Keep ceiling fixtures selectable without making them the default over furniture.
local M={}
function M.order(entries)
 local ordinary,ceiling={},{}
 for _,entry in ipairs(entries) do
  local name=entry.moveProps and entry.moveProps.spriteName
  local target=type(name)=='string' and name:match('^TSBAstroluxCeiling_[01]$')
  local list=target and ceiling or ordinary
  list[#list+1]=entry
 end
 if #ceiling==0 or #ordinary==0 then return entries end
 for _,entry in ipairs(ceiling) do ordinary[#ordinary+1]=entry end
 return ordinary
end
function M.install()
 local C=ISMoveableCursor
 if not C or not C.getObjectList then return false end
 if C.TSBAstroluxCeilingPickupPriority then return true end
 local original=C.getObjectList
 C.getObjectList=function(self,...)
  local entries=original(self,...)
  if C.mode[self.player]=='pickup' then return M.order(entries) end
  return entries
 end
 C.TSBAstroluxCeilingPickupPriority=true
 return true
end
local installed=false
Events.OnGameStart.Add(function()installed=M.install()end)
Events.OnTick.Add(function()if not installed then installed=M.install()end end)
return M
