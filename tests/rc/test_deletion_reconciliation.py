from pathlib import Path
import os
os.chdir(Path(__file__).resolve().parents[2])
from lupa.lua51 import LuaRuntime
r=Path('.');l=LuaRuntime()
for n in ['client/TSBAstroluxStructure/ReleaseClient.lua','server/TSBAstroluxStructure/ReleaseDelete.lua']:l.execute('assert(loadfile(...))',str(r/'mods/PZ_TSB_AstroluxStructure/42/media/lua'/n))
l.execute('''
package.loaded['ISUI/ISModalRichText']={};package.loaded['TSBAstroluxStructure/ReleaseAccess']={}
Events=setmetatable({},{__index=function(t,k)local e={Add=function(f)if k=='OnTick'then callback=f end end,Remove=function()end};rawset(t,k,e);return e end})
function isClient()return true end
TSBAstroluxReleaseSites={}
local function obj(owner,name)
 local md={TSBAstroluxStructure=owner};return {md=md,sp={getName=function()return name end},getModData=function(self)return self.md end,getSprite=function(self)return self.sp end,getObjectIndex=function(self)return self.removed and -1 or 0 end}
end
owned=obj('tower','frame');foreign=obj('other','frame');floor=obj(nil,'showroom');floor.md.TSBAstroluxFlooring='tower'
function floor:setSprite(sp)self.sp=sp end
local objects={owned,foreign,floor};sq={}
function sq:getObjects()return {size=function()return #objects end,get=function(_,i)return objects[i+1]end}end
function sq:RemoveTileObject(o,group)assert(group==false);o.removed=true;for i,v in ipairs(objects)do if v==o then table.remove(objects,i);break end end end
function sq:getFloor()return floor end
function sq:invalidateRenderChunkLevel()end;function sq:RecalcProperties()end;function sq:RecalcAllWithNeighbours()end;function sq:setSquareChanged()end
function getCell()return {getGridSquare=function(_,x,y,z)if x==1 and y==1 and z==0 then return sq end end}end
function getSprite(n)return {getName=function()return n end}end
''')
l.globals().M=l.execute((r/'mods/PZ_TSB_AstroluxStructure/42/media/lua/client/TSBAstroluxStructure/ReleaseClient.lua').read_text(encoding='utf-8'))
l.execute('''
M.receive('deletedSite',{id='tower',x=0,y=0,floors={{x=1,y=1,to='showroom',from='grass'}}})
for i=1,120 do callback()end
assert(owned.removed and not foreign.removed and floor:getSprite():getName()=='grass'and floor.md.TSBAstroluxFlooring==nil)
owned.removed=false;TSBAstroluxReleaseSites={{id='tower'}}
M.receive('deletedSite',{id='tower',x=0,y=0});for i=1,120 do callback()end;assert(not owned.removed)
''')
print('PASS: owned-only local reconciliation, original grass restoration, foreign objects retained, newer same-origin tower protected; Lua syntax.')
