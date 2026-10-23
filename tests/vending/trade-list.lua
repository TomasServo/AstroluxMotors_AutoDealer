local calls=0
local profiles={['Base.Reviewed']={}}
local T={enabled=function(db)return not db.disabled end,inArea=function()return true end,
 validate=function(_,_,v)if v.cargo then return nil,'Empty cargo'end;return true end,checkParts=function()end}
package.loaded['TSBAstroluxVend/TradeIn']=T
package.loaded['TSBAstroluxVend/AppraisalProfiles']={vehicles=profiles}
package.loaded['TSBAstroluxVend/Appraisal']={calculate=function()calls=calls+1;return {amount=100,maximum=200}end}
package.loaded['TSBAstroluxVend/Amount']={}
package.loaded['TSBAstroluxVend/Config']={tradeInRate=.5}
local vehicles={}
for i,name in ipairs({'Base.Unsupported','Base.Reviewed','Base.Reviewed'})do
 vehicles[i]={getId=function()return i end,getX=function()return 1 end,getY=function()return 1 end,
 getModData=function()return {}end,getScript=function()return {getFullName=function()return name end,getName=function()return name end}end}
end
vehicles[3].cargo=true
function getCell()return {getVehicles=function()return {iterator=function()local i=0;return {hasNext=function()return i<#vehicles end,next=function()i=i+1;return vehicles[i]end}end}end}end
local nativeError=error
local failures=0
error=function(...)failures=failures+1;return nativeError(...)end
local B=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/server/TSBAstroluxVend/TradeBatch.lua')
local db={};local service=B.new(db,{});local p={getUsername=function()return 'test'end}
for i=1,3 do
 local rows=service:list(p,{spawnArea={}},function()return 1000 end)
 assert(#rows==3 and not rows[1].eligible and rows[1].reason:find('no reviewed'))
 assert(rows[2].eligible and rows[2].amount==100)
 assert(not rows[3].eligible and rows[3].reason=='Empty cargo')
end
assert(calls==3 and failures==0)
db.disabled=true;service:list(p,{spawnArea={}},function()return 1000 end);assert(failures==0 and calls==3)
db.disabled=false;db.tradeIns.test={status='hold'};service:list(p,{spawnArea={}},function()return 1000 end);assert(failures==0 and calls==3)
print('PASS repeated listing: unsupported profile, cargo, disabled/held buybacks return reasons without Lua errors; supported car remains appraisable')
