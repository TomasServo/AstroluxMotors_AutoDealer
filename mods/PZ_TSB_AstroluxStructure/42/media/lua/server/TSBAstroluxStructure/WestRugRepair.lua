-- One-time alignment of the exact historical two-piece west entrance rug.
if isClient() or isServer()then return end
local R=require 'TSBAstroluxStructure/Records'
local Align=require 'TSBAstroluxStructure/WestRugAlignment'
local M={}
local function name(o)local s=o:getSprite();return s and s:getName()end
function M.repair(r)
 if r.westRugAlignmentV2 or r.status~='ready' or r.combinedSize~=12 then return false end
 if r.closedEntrances and r.closedEntrances.west then
  local hidden=r.hiddenEntranceRugs and r.hiddenEntranceRugs.west
  if not hidden or #hidden~=2 then return false end
  Align.record(r);r.westRugAlignmentV2=true;return true
 end
 local squares,found={},{}
 for dy=4,6 do
  local sq=getCell():getGridSquare(r.x,r.y+dy,0)
  if not sq or not sq:getFloor()then return false end
  squares[dy]=sq
  local list=sq:getObjects()
  for i=0,list:size()-1 do local o=list:get(i);local n=name(o)
   if n=='TSBAstroluxLogoRug_4' or n=='TSBAstroluxLogoRug_5' then
    if found[n]then return false end
    local link=o:getModData().TSBAstroluxEntranceRug
    if link and (link.tower~=r.id or link.edge~='west')then return false end
    found[n]=o
   end
  end
 end
 local a,b=found.TSBAstroluxLogoRug_4,found.TSBAstroluxLogoRug_5
 if not a or not b then return false end
 local corrected=a:getSquare()==squares[5] and b:getSquare()==squares[6]
 if not corrected then
  if a:getSquare()~=squares[4] or b:getSquare()~=squares[5]then return false end
  for dy=5,6 do local sq=squares[dy];local list=sq:getObjects()
   for i=0,list:size()-1 do local o=list:get(i);local md=o:getModData()
    local helper=md.TSBAstroluxNativeHelperV1
    local n=name(o)
    local frame=md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='glassFrameVisual'
     and type(helper)=='table' and helper.owner==r.id and helper.kind=='glassFrameArt'
     and type(n)=='string' and n:match('^TSBAstroluxGlassFrame_[0-8]$') and not o:getContainer()
    if o~=a and o~=b and o~=sq:getFloor() and not instanceof(o,'IsoWindow') and not instanceof(o,'IsoDoor') and not frame then return false end
   end
  end
  local ok=pcall(function()
   squares[4]:RemoveTileObject(a);squares[5]:RemoveTileObject(b)
   a:setSquare(squares[5]);squares[5]:AddTileObject(a)
   b:setSquare(squares[6]);squares[6]:AddTileObject(b)
  end)
  if not ok then
   for _,entry in ipairs({{a,4},{b,5}})do local o=entry[1]
    if o:getObjectIndex()>=0 then o:getSquare():RemoveTileObject(o)end
    o:setSquare(squares[entry[2]]);squares[entry[2]]:AddTileObject(o)
   end
   return false
  end
 end
 Align.record(r)
 r.entranceRugs=r.entranceRugs or {};r.entranceRugs.west={}
 for i,o in ipairs({a,b})do
  o:getModData().TSBAstroluxEntranceRug={tower=r.id,edge='west'}
  r.entranceRugs.west[i]={x=r.x,y=r.y+4+i,sprite=name(o)}
  o:transmitModData();o:invalidateRenderChunkLevel(-1)
 end
 for _,sq in pairs(squares)do sq:RecalcProperties();sq:setSquareChanged()end
 r.westRugAlignmentV2=true
 return true
end
local ticks=0
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%60~=0 then return end
 for _,r in ipairs(R.all())do M.repair(r)end
end)
return M
