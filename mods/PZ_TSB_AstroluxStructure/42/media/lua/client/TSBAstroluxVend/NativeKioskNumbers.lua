-- Cabinet numbers use native attached sprites, sharing its camera/depth pass.
local M={prefix='TSBAstroluxKioskDigit_'}
local tracked={}
function M.names(index,number)
 if index~=0 and index~=1 then return {} end
 if type(number)~='number' or number<1 or number~=math.floor(number) or number>9007199254740991 then return {} end
 local text=string.format('%.0f',number);local result={}
 for position=1,#text do
  result[#result+1]=M.prefix..index..'_'..#text..'_'..((position-1)*10+tonumber(text:sub(position,position)))
 end
 return result
end
function M.apply(o,names)
 local wanted={};for _,name in ipairs(names)do
  -- Preflight before removing the previous label if an asset is missing.
  if not getTexture(name) or not getSprite(name) then return false end
  wanted[name]=true
 end
 local have={};local attached=o:getAttachedAnimSprite()
 if attached then for i=attached:size()-1,0,-1 do
  local sp=attached:get(i):getParentSprite();local name=sp and sp:getName()
  if name and name:sub(1,#M.prefix)==M.prefix then
   if not wanted[name] or have[name] then o:RemoveAttachedAnim(i)
   else have[name]=true end
  end
 end end
 for _,name in ipairs(names)do if not have[name]then o:addAttachedAnimSpriteByName(name)end end
 return true
end
function M.update(rows)
 local cell=getCell();if not cell then return end
 local wanted={}
 for _,row in ipairs(rows or {})do
  local sq=cell:getGridSquare(row.x,row.y,row.z)
  if sq then local objects=sq:getObjects()
   for i=0,objects:size()-1 do
    local o=objects:get(i);local sp=o:getSprite();local name=sp and sp:getName()
    local index=name and tonumber(name:match('^TSBAstroluxKiosk_([0-3])$'))
    if index then wanted[o]=M.names(index,row.number)end
   end
  end
 end
 for o in pairs(tracked)do if not wanted[o]then
  if o:getObjectIndex()>=0 then M.apply(o,{})end
  tracked[o]=nil
 end end
 for o,names in pairs(wanted)do M.apply(o,names);tracked[o]=true end
end
Events.OnDisconnect.Add(function()M.update({});tracked={}end)
return M
