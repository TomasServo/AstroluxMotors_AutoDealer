-- One confirmed missing pane only; never regenerate normal player removals.
if isClient() or isServer() then return end
local M={};local ticks=0;local stopped=false
local function enabled()return require('AstroluxBayTest/TestWorld').city()end
local key='windowFrameRecovery12819x1663V1'
function M.apply(r,sq)
 if not enabled() or not r or r.id~='structure:12816:1663' or r.status~='ready' or r.combinedSize~=12 then return 'excluded' end
 if r[key] then return 'already attempted' end
 if not sq or sq:getX()~=12819 or sq:getY()~=1663 or sq:getZ()~=0 then return 'unloaded' end
 local list=sq:getObjects()
 for i=0,list:size()-1 do local o=list:get(i)
  if (instanceof(o,'IsoWindow') or instanceof(o,'IsoDoor')) and o:getNorth() then return 'existing opening retained' end
 end
 local sp=getSprite('TSBAstroluxClearGlass_1')
 if not sp or sp:getName()~='TSBAstroluxClearGlass_1' then return 'missing sprite' end
 -- Construct in broken/cleared state BEFORE insertion or event tracking.
 local o=IsoWindow.new(getCell(),sq,sp,true)
 o:setPermaLocked(true);o:smashWindow(true,false);o:removeBrokenGlass()
 assert(o:isDestroyed() and o:isGlassRemoved(),'Native broken state rejected')
 local md=o:getModData();md.TSBAstroluxStructure=r.id;md.TSBAstroluxStructureKind='window'
 md.TSBAstroluxDebrisV1={broken=true,cleared=true}
 r[key]='attempted' -- never duplicate an insertion whose outcome is uncertain
 sq:AddSpecialObject(o)
 assert(o:getObjectIndex()>=0 and sq:getSpecialObjects():contains(o),'Native frame insertion not confirmed')
 sq:RecalcAllWithNeighbours(true)
 r[key]='complete'
 return 'recovered broken cleared native window; no debris awarded'
end
Events.OnTick.Add(function()
 if stopped or not enabled() then return end
 ticks=ticks+1;if ticks%30~=0 then return end
 local db=ModData.get('TSBAstroluxStructure.Lab.v1');if not db then return end
 local r=db.showrooms and db.showrooms['structure:12816:1663']
 if not r and db.tower and db.tower.id=='structure:12816:1663' then r=db.tower end
 if not r then return end
 local sq=getCell():getGridSquare(12819,1663,0);if not sq then return end
 stopped=true
 local ok,result=pcall(M.apply,r,sq)
 print('[Astrolux Frame Recovery] '..tostring(ok)..' '..tostring(result))
end)
Events.OnObjectAboutToBeRemoved.Add(function(o)
 if not enabled() or not o or not instanceof(o,'IsoWindow') then return end
 local md=o:getModData();local sq=o:getSquare()
 if md.TSBAstroluxStructure and sq then
  print('[Astrolux Window Removal] '..sq:getX()..','..sq:getY()..' broken='..tostring(o:isDestroyed())..' cleared='..tostring(o:isGlassRemoved()))
 end
end)
return M
