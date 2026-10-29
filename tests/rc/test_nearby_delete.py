from pathlib import Path
import os
os.chdir(Path(__file__).resolve().parents[2])
from lupa.lua51 import LuaRuntime
r=Path('mods/PZ_TSB_AstroluxStructure/42/media/lua')
l=LuaRuntime()
l.execute('''
admin=true; clock=1000; rows={{id='near',x=118,y=121,releaseTower=1},{id='far',x=135,y=135,releaseTower=1}}
p={getUsername=function()return 'admin'end,getX=function()return 123 end,getY=function()return 122 end,getZ=function()return 0 end,getPlayerNum=function()return 0 end}
Events=setmetatable({},{__index=function()return {Add=function()end}end})
function isClient()return false end
function isServer()return true end
function getTimestampMs()return clock end
function sendServerCommand(p,c,k,d) replyKind=k;replyData=d end
package.preload['TSBAstroluxStructure/ReleaseAccess']=function()return {allowed=function()return admin end}end
package.preload['TSBAstroluxStructure/Records']=function()return {all=function()return rows end}end
package.preload['TSBAstroluxStructure/ReleaseDelete']=function()return {review=function(p,id)reviewed=id;if refusal then return nil,refusal end;return {token='test',x=118,y=121,count=1}end,execute=function()error('Unexpected deletion')end}end
''')
l.execute((r/'server/TSBAstroluxStructure/ReleasePlacement.lua').read_text(encoding='utf-8'))
l.execute('''
local m=TSBAstroluxReleasePlacement
m.handle(p,'sites',{});m.handle(p,'reviewDeleteNearby',{})
assert(reviewed=='near'and replyKind=='reviewDelete')
clock=2000;refusal='Stand outside the footprint';m.handle(p,'reviewDeleteNearby',{});assert(replyKind=='result'and replyData.message==refusal)
clock=3000;rows={};m.handle(p,'reviewDeleteNearby',{});assert(replyKind=='result'and string.find(replyData.message,'No registered'))
clock=4000;admin=false;reviewed=nil;m.handle(p,'reviewDeleteNearby',{});assert(not reviewed and string.find(replyData.message,'Administrator'))
''')
l.execute('''
package.preload['ISUI/ISModalRichText']=function()return {}end
function isClient()return true end
function getSpecificPlayer()return p end
function sendClientCommand(p,ch,cmd,args)sent=cmd end
admin=true;TSBAstroluxReleaseSites={}
context={options={},addOption=function(self,name,target,callback)table.insert(self.options,{name=name,callback=callback})end}
''')
l.execute((r/'client/TSBAstroluxStructure/ReleaseClient.lua').read_text(encoding='utf-8'))
l.execute('''
assert(TSBAstroluxReleaseClient.addMenu(0,context,false))
local found=false
for _,o in ipairs(context.options)do if o.name=='Delete Nearby Astrolux Tower...'then found=true;o.callback()end end
assert(found and sent=='reviewDeleteNearby')
admin=false;assert(not TSBAstroluxReleaseClient.addMenu(0,{options={}},false))
''')
print('PASS: empty-cache menu, server nearest selection, admin gate, preserved refusal, review-only flow, sites/action timing.')

l.execute("""
function isClient()return false end
function p:isDead()return false end
function p:getAccessLevel()return admin and 'admin'or 'none'end
rows={{id='tower',x=118,y=121,releaseTower=1,status='ready'}}
package.loaded['TSBAstroluxStructure/DisplayLocks']={set=function(r,value)assert(r==rows[1]);lockCalls=(lockCalls or 0)+1;r.displayOutfitsLocked=value end}
local m=TSBAstroluxReleasePlacement
clock=5000;admin=false;m.handle(p,'setting',{id='tower',setting='displayLocks',enabled=true});assert(not lockCalls)
clock=6000;admin=true;m.handle(p,'setting',{id='tower',setting='displayLocks',enabled=true});assert(lockCalls==1 and rows[1].displayOutfitsLocked)
assert(m.snapshot().records[1].displayOutfitsLocked==true)
clock=7000;m.handle(p,'setting',{id='wrong',setting='displayLocks',enabled=false});assert(lockCalls==1)
clock=8000;m.handle(p,'setting',{id='tower',setting='displayLocks',enabled='true'});assert(lockCalls==1)
clock=9000;function p:getX()return 900 end;m.handle(p,'setting',{id='tower',setting='displayLocks',enabled=false});assert(lockCalls==1)
print('PASS: real server dispatcher rejects ordinary users, wrong tower, nonboolean and distant requests; authorized lock is broadcast.')
""")
