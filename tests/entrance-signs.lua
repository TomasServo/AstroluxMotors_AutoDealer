package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
function isClient()return false end
function isServer()return false end
Events={OnTick={Add=function()end}}
local squares={};local fail=false
local function sq(x,y)
    local s={objects={},x=x,y=y}
    function s:getObjects()return {size=function()return #self.objects end,get=function(_,i)return self.objects[i+1]end}end
    function s:AddTileObject(obj)if fail and self.x==108 then error('injected insertion failure')end;self.objects[#self.objects+1]=obj;obj.index=#self.objects-1 end
    function s:transmitRemoveItemFromSquare(obj)for i,v in ipairs(self.objects)do if v==obj then table.remove(self.objects,i);obj.index=-1;return end end end
    function s:RecalcAllWithNeighbours()end
    squares[x..':'..y]=s;return s
end
local south,east=sq(103,208),sq(108,203)
function getCell()return {getGridSquare=function(_,x,y,z)assert(z==0);return squares[x..':'..y]end}end
function getSprite(name)return {getName=function()return name end}end
IsoObject={new=function(_,square,sprite)
    local obj={md={},index=-1}
    function obj:getModData()return self.md end
    function obj:getObjectIndex()return self.index end
    function obj:getSprite()return sprite end
    return obj
end}
local S=require 'TSBAstroluxStructure/EntranceSigns'
local r={x=100,y=200,id='tower',status='ready',slidingDoorsRevision=1}
assert(S.apply(r));assert(#south.objects==1 and #east.objects==1)
assert(south.objects[1]:getSprite():getName()=='TSBAstroluxEntranceSign_0')
assert(east.objects[1]:getSprite():getName()=='TSBAstroluxEntranceSign_1')
assert(S.apply(r) and #south.objects==1 and #east.objects==1,'Repeat install must not duplicate')
-- Lost completion marker recovers only if the exact owned pair already exists.
r.entranceSignsRevision=nil;assert(S.apply(r) and #south.objects==1)
south.objects={};east.objects={};r.entranceSignsRevision=nil;fail=true
assert(not S.apply(r));assert(#south.objects==0 and #east.objects==0 and not r.entranceSignsRevision and r.status=='ready')
fail=false;squares['108:203']=nil
assert(not S.apply(r) and #south.objects==0,'Unloaded endpoint must prevent partial installation')
print('PASS: south/east two-tile doorway signs, no north/west objects, idempotence, existing-pair recovery and insertion rollback')
