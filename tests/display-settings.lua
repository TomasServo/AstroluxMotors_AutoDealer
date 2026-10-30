local base='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
local client=false;local admin=true;local sent={}
function isClient()return client end
function isServer()return false end
function getDebug()return false end
local p={isDead=function()return false end,getZ=function()return 0 end,getX=function()return 121 end,getY=function()return 123 end,getAccessLevel=function()return admin and 'admin' or 'None' end}
local r={id='demo',x=118,y=121,releaseTower=1,status='ready',displayOutfitsLocked=true}
local records={r}
package.loaded['TSBAstroluxStructure/Records']={all=function()return records end,near=function()return records[1]end}
package.loaded['TSBAstroluxStructure/ReleaseSites']=dofile(base..'shared/TSBAstroluxStructure/ReleaseSites.lua')
package.loaded['TSBAstroluxStructure/ReleaseAccess']=dofile(base..'shared/TSBAstroluxStructure/ReleaseAccess.lua')
package.loaded['TSBAstroluxStructure/ShowroomSettings']=dofile(base..'client/TSBAstroluxStructure/ShowroomSettings.lua')
package.loaded['TSBAstroluxStructure/ReleaseClient']={send=function(command,args)sent[#sent+1]={command,args}end}
local D=dofile(base..'client/TSBAstroluxStructure/SettingsDisplays.lua')
local locked,_,enabled=D.status(p);assert(locked and enabled,'Non-debug SP must show the release lock state')
assert(D.set(p,false));assert(sent[1][1]=='setting' and sent[1][2].setting=='displayLocks' and sent[1][2].id=='demo' and sent[1][2].enabled==false)
r.displayOutfitsLocked=false;assert(not D.status(p));assert(D.set(p,true));assert(sent[2][2].enabled==true)
client=true;TSBAstroluxReleaseSites={r};admin=false
local _,_,allowed=D.status(p);assert(not allowed);assert(not D.set(p,true));assert(#sent==2,'Ordinary MP players cannot change locks')
admin=true;assert(D.set(p,true));assert(#sent==3)
client=false;records={};assert(not D.set(p,true));assert(#sent==3,'No release tower must not authorize the old debug path')
print('PASS: non-debug SP mannequin settings use release state and dispatcher; MP authorization retained')
