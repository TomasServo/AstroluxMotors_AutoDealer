local server=true;local clock=1000;local replies={};local reads=0
function isClient()return false end
function isServer()return server end
function getTimestampMs()return clock end
Events=setmetatable({},{__index=function()return {Add=function()end}end})
package.loaded['TSBAstroluxStructure/ReleaseAccess']={allowed=function()return true end}
package.loaded['TSBAstroluxStructure/Records']={all=function()reads=reads+1;return {}end}
function sendServerCommand(p,channel,kind,data)replies[#replies+1]={kind=kind,data=data}end
TSBAstroluxReleaseClient={receive=function(kind,data)replies[#replies+1]={kind=kind,data=data}end}
local p={getUsername=function()return 'tester' end}
local M=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxStructure/ReleasePlacement.lua') or TSBAstroluxReleasePlacement
for _,mp in ipairs({true,false})do
 server=mp;M.last.tester=1000;M.pending.test={unchanged=true};reads=0
 for _,command in ipairs({'place','deleteTower','setting'})do
  clock=1249;local before=#replies
  assert(M.handle(p,command,{token='test'})==false)
  assert(#replies==before+1 and replies[#replies].kind=='result')
  assert(replies[#replies].data.ok==false and replies[#replies].data.message=='Please wait a moment, then try again.')
  assert(M.pending.test.unchanged and M.last.tester==1000 and reads==0,'Throttled commands cannot mutate state or extend cooldown')
 end
 clock=1249;M.handle(p,'sites',{});assert(replies[#replies].kind=='sites' and M.last.tester==1000)
 clock=1250;M.handle(p,'reviewDeleteNearby',{});assert(M.last.tester==1250)
 assert(replies[#replies].data.message~='Please wait a moment, then try again.','Retry at boundary must reach handler')
end
print('PASS: release throttle replies with failure in SP/MP, preserves pending state, allows sites and retry at 250ms')
