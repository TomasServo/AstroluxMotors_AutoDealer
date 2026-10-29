from pathlib import Path
import os
os.chdir(Path(__file__).resolve().parents[2])
from lupa.lua51 import LuaRuntime
r=Path('.');l=LuaRuntime()
for p in (r/'mods').rglob('*.lua'):l.execute('assert(loadfile(...))',str(p))
l.execute('''
server=true;allowed=false;map='Astrolux Test Lot';state={};writes=0
function isServer()return server end;function isClient()return not server end
Events=setmetatable({},{__index=function(t,k)local e={Add=function(f)t[k..'Callback']=f end};rawset(t,k,e);return e end})
function getWorld()return {getMap=function()return map end,setHydroPowerOn=function(_,on)power=on end}end
function getSandboxOptions()return {set=function()writes=writes+1 end,toLua=function()end}end
ModData={getOrCreate=function()return state end}
package.loaded['TSBAstroluxStructure/ReleaseAccess']={allowed=function()return allowed end}
function sendServerCommand(...)sent=true end
''')
l.execute((r/'mods/PZ_TSB_AstroluxTestMap/42/media/lua/shared/TSBAstroluxTestMap/MultiplayerPowerTest.lua').read_text(encoding='utf-8'))
l.execute('''
local f=Events.OnClientCommandCallback;local c='TSBAstroluxMPPowerTest'
f(c,'set',{}, {off=true});assert(writes==0)
allowed=true;f(c,'set',{}, {off=true});assert(power==false and state.off and writes==1)
f(c,'set',{}, {off=false});assert(power==true and state.off==false)
map='Muldraugh, KY';local before=writes;f(c,'set',{}, {off=true});assert(writes==before)
map='Astrolux Test Lot';state.off=true;Events.OnServerStartedCallback();assert(power==false)
''')
print('PASS Lua 5.1 syntax; power admin authorization, map scope, off/on and restart restoration.')
