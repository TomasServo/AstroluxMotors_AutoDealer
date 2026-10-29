-- Read-only, one-shot audit of native windows after save loading.
if isClient() or isServer() then return end
local M={}
function M.inspect(sq,north,id)
 if not sq then return 'UNLOADED' end
 local objects=sq:getObjects();local parts={};local windows=0
 for i=0,objects:size()-1 do
  local o=objects:get(i);local sp=o:getSprite();local md=o:getModData()
  if instanceof(o,'IsoWindow') and o:getNorth()==north then
   windows=windows+1
   local other=o:getOppositeSquare()
   parts[#parts+1]='WINDOW sprite='..tostring(sp and sp:getName())..' owned='..tostring(md.TSBAstroluxStructure==id)..' broken='..tostring(o:isDestroyed())..' cleared='..tostring(o:isGlassRemoved())..' health='..tostring(o:getHealth())..' special='..tostring(sq:getSpecialObjects():contains(o))..' collide='..tostring(other and o:TestCollide(nil,sq,other))
  elseif md.TSBAstroluxStructure==id then
   parts[#parts+1]='OWNED '..tostring(o:getObjectName())..' kind='..tostring(md.TSBAstroluxStructureKind)..' sprite='..tostring(sp and sp:getName())
  end
 end
 return (windows==0 and 'NO_NATIVE_WINDOW ' or '')..table.concat(parts,' | ')
end
local ticks=0;local finished=false
Events.OnTick.Add(function()
 if finished or not getDebug() or getNumActivePlayers()~=1 or not require('AstroluxBayTest/TestWorld').enabled() then return end
 ticks=ticks+1;if ticks<120 then return end
 local p=getSpecificPlayer(0);if not p then return end
 local db=ModData.get('TSBAstroluxStructure.Lab.v1');if not db then return end
 local records={};if db.tower then records[#records+1]=db.tower end
 for _,r in pairs(db.showrooms or {})do records[#records+1]=r end
 finished=true
 print('[Astrolux Frame Audit] START player='..p:getX()..','..p:getY())
 local seen={}
 for _,r in ipairs(records)do
  if not seen[r.id] and r.status=='ready' and r.combinedSize==12 and math.abs(p:getX()-r.x)<40 and math.abs(p:getY()-r.y)<40 then
   seen[r.id]=true
   for _,piece in ipairs(require('AstroluxBayTest/ShowroomPlan12').plan(r.x,r.y).objects)do
    if piece.kind=='window' then
     print('[Astrolux Frame Audit] '..piece.x..','..piece.y..' north='..tostring(piece.north)..' '..M.inspect(getCell():getGridSquare(piece.x,piece.y,0),piece.north,r.id))
    end
   end
  end
 end
 print('[Astrolux Frame Audit] END; no objects changed')
end)
return M
