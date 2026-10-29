-- Only this explicitly selected SP challenge can construct the demo.
if isClient()or isServer()then return end
local M={};local ticks=0
local function active()
 return getCore():isChallenge()and getCore():getChallengeID()=='AstroluxMotorsDemo'
  and tostring(getWorld():getMap())=='Astrolux Test Lot'
end
function M.update()
 if not active()then return end
 local state=ModData.getOrCreate('TSBAstroluxDemoScenario.v1')
 if state.attempted then return end -- Reloads, respawns and deletions never repaste.
 local p=getSpecificPlayer(0);if not p or p:isDead()then return end
 for dx=-1,13 do for dy=-1,13 do
  if not getCell():getGridSquare(118+dx,121+dy,0)then return end
 end end
 local records=require('TSBAstroluxStructure/Records').all()
 if #records>0 then state.attempted=true;state.status='existing';return end
 state.attempted=true;state.status='placing'
 local ok,reason=pcall(function()
  local record,why=require('AstroluxBayTest/ShowroomBuilder12').place(p,118,121,{multiple=true,furnished=true,profile=require('TSBAstroluxStructure/DefaultFurnishings12')})
  assert(record,why)
  record.status='assembling'
  require('TSBAstroluxStructure/ReleaseAssembly').finish(record)
  record.status='ready';state.recordId=record.id;state.status='ready'
 end)
 if not ok then state.status='hold';state.error=tostring(reason);p:Say('Astrolux demo setup stopped. See the log; no automatic retry.')end
 print('[Astrolux Demo Scenario] '..state.status..(state.error and ': '..state.error or ''))
end
Events.OnGameStart.Add(M.update)
Events.OnTick.Add(function()ticks=ticks+1;if ticks%60==0 then M.update()end end)
return M
