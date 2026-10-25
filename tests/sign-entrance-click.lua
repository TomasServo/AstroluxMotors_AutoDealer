isClient=function()return false end;isServer=function()return false end
package.preload['TSBAstroluxStructure/Entrances']=function()return {}end
instanceof=function(o,t)return o.kind==t end
local native=0
ISObjectClickHandler={doClickSpecificObject=function(o,index,p)native=native+1;return 'native' end}
getMouseX=function()return 1 end;getMouseY=function()return 1 end
local C=dofile(arg[1]);assert(C.install());assert(C.install())
for i=0,3 do
 local o={kind='IsoLightSwitch',getSprite=function()return {getName=function()return 'TSBAstroluxMotorsSign_'..i end}end}
 assert(C.click(o,nil,1,1)==false)
 assert(ISObjectClickHandler.doClickSpecificObject(o,0,nil)=='native')
end
assert(native==4)
assert(ISObjectClickHandler.doClickSpecificObject({kind='IsoDoor'},0,nil)=='native');assert(native==5)
print('PASS all four sign faces bypass doorway capture and delegate once; install idempotent; non-sign fallback preserved')
