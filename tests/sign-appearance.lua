Events={};for _,k in ipairs({'LoadGridsquare','OnObjectAdded','OnFillWorldObjectContextMenu'})do Events[k]={Add=function()end}end
ColorInfo={new=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end};FBORenderChunk={DIRTY_REDRAW=1}
instanceof=function(o,t)return o.kind==t end
local M=dofile(arg[1]);local writes=0
local o={kind='IsoLightSwitch',getSprite=function()return {getName=function()return 'TSBAstroluxMotorsSign_1'end}end,setCustomColor=function(_,c)assert(c.r==0.12 and c.g==0.12 and c.b==0.12 and c.a==1);writes=writes+1 end,invalidateRenderChunkLevel=function()end}
M.refresh(o);assert(writes==1);M.refresh(nil);M.refresh({kind='IsoObject'});assert(writes==1)
o.getSprite=function()return {getName=function()return 'lighting_outdoor_01_42'end}end;M.refresh(o);assert(writes==1)
print('PASS base-only dimming; native state untouched; nil/unrelated/vanilla signs ignored')
