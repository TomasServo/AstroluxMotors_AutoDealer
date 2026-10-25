Events={OnGameStart={Add=function()end},OnTick={Add=function()end}}
instanceof=function(o,t)return o.kind==t end;getDebug=function()return false end
local distance=1;local z=0;local powered=true;local paused=false;local dead=false;local aiming=false;local ignore=false
UIManager={getSpeedControls=function()return {getCurrentGameSpeed=function()return paused and 0 or 1 end}end}
local sq={getZ=function()return 0 end,DistToProper=function()return distance end}
local p={isDead=function()return dead end,isAiming=function()return aiming end,isIgnoreContextKey=function()return ignore end,getCurrentSquare=function()return sq end,getZ=function()return z end}
local o={kind='IsoLightSwitch',getSprite=function()return {getName=function()return 'TSBAstroluxMotorsSign_1'end}end,getSquare=function()return sq end,getObjectIndex=function()return 0 end,canSwitchLight=function()return powered end}
local calls,fallback=0,0
ISWorldObjectContextMenu={onToggleLight=function(_,target,index)assert(target==o and index==0);calls=calls+1 end}
ISObjectClickHandler={doClickLightSwitch=function()fallback=fallback+1;return 'original'end}
local M=dofile(arg[1]);assert(M.install());assert(M.install());assert(ISObjectClickHandler.doClickLightSwitch(o,0,p));assert(calls==1)
distance=2;assert(not M.click(o,0,p));distance=1
z=1;assert(not M.click(o,0,p));z=0
powered=false;assert(not M.click(o,0,p));powered=true
paused=true;assert(not M.click(o,0,p));paused=false
dead=true;assert(not M.click(o,0,p));dead=false
aiming=true;assert(not M.click(o,0,p));aiming=false
ignore=true;assert(not M.click(o,0,p));ignore=false
assert(calls==1)
assert(ISObjectClickHandler.doClickLightSwitch({kind='Other'},0,p)=='original' and fallback==1)
print('PASS native edge action exactly once; distance, floor, power, paused/dead/aiming/context guards; other lights unchanged; idempotent install')
