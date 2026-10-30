-- Bundled demonstration defaults, not a player-facing sandbox option.
local C=require 'TSBAstroluxTestMap/Config'
local W=require 'AstroluxBayTest/TestWorld'
local R=require 'TSBAstroluxStructure/Records'
local Areas=require 'TSBAstroluxVend/SpawnAreas'
local Power=require 'TSBAstroluxVend/Power'
local M={};local message
local function report(text)
 if message~=text then print('[Astrolux Demo] '..text);message=text end
end
function M.update()
 if C.bundledDemo~=true or not W.freshLot()then return false end
 -- The challenge owns one explicit tower record. Never initialize arbitrary
 -- pasted towers merely because they share the test map or coordinates.
 local challenge=getCore():isChallenge()and getCore():getChallengeID()=='AstroluxMotorsDemo'
 local selected
 if challenge then
  selected=ModData.get('TSBAstroluxDemoScenario.v1')
  if not selected or selected.status~='ready'then return false end
 elseif getWorld():getWorld()=='AstroluxTestWorld_80x80_20261028'then
  selected=ModData.get('TSBAstroluxCombined12.v1')
 else return false end
 local record
 for _,r in ipairs(R.all())do
  if selected and r.id==selected.recordId and r.status=='ready'and r.combinedSize==12 then record=r;break end
 end
 if not record or not record.furnishingsRevision then return false end
 local db=ModData.get('TSBAstroluxVend.State.v1')
 if not db or not db.terminals then return false end
 local terminals={}
 for _,t in pairs(db.terminals)do
  if t.kiosk and not t.packed and t.z==0 and t.x>=record.x and t.x<=record.x+12
   and t.y>=record.y and t.y<=record.y+12 then terminals[#terminals+1]=t end
 end
 if #terminals<2 then return false end
 local state=ModData.getOrCreate('TSBAstroluxTestMap.DemoReady.v1')
 if state.done and state.recordId~=record.id then return false end
 if not state.done then
  for _,o in pairs(db.orders or{})do
   if o.status~='delivered'then report('Finish outstanding orders before preparing the bundled demo.');return false end
  end
  -- Original demo zone geometry relative to its tower, including the
  -- approved kiosk offsets (3,0) and (8,0). Both zones are outside the shell.
  local defaults={
   {x=record.x+3,y=record.y,x1=record.x-2,y1=record.y-15,x2=record.x+12,y2=record.y-5,heading='S',gap=1,rowGap=1},
   {x=record.x+8,y=record.y,x1=record.x+16,y1=record.y-1,x2=record.x+25,y2=record.y+16,heading='W',gap=1,rowGap=0},
  }
  local prepared={}
  for _,d in ipairs(defaults)do
   local terminal
   for _,t in ipairs(terminals)do if t.x==d.x and t.y==d.y then terminal=t;break end end
   if not terminal then return false end
   local area,why=Areas.rectangle(d.x1,d.y1,d.x2,d.y2,d.heading,d.gap,d.rowGap)
   if not area then report(why or 'Invalid saved demo zone.');return false end
   prepared[#prepared+1]={terminal=terminal,area=area}
  end
  for _,entry in ipairs(prepared)do
   local t=entry.terminal
   if not t.spawnArea then
    entry.area.revision=1;t.spawnArea=entry.area;t.deliveryBorder=true
   end
  end
  state.done=true;state.recordId=record.id
 end
 -- Existing and deliberately edited zones remain authoritative. No recurring
 -- reset of purchases, prices, inventories, delivery choices or door settings.
 for _,t in ipairs(terminals)do if not t.spawnArea or not Power.available(t)then return false end end
 report('Dealership powered; delivery areas configured. Starter cash available once per character.')
 return true
end
return M
