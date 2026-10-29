package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;'..package.path
package.preload['ISUI/ISModalRichText']=function()return true end
local callback,dialogs,options=nil,{},{}
Events={OnFillWorldObjectContextMenu={Add=function(fn)callback=fn end}}
function isClient()return false end;function isServer()return false end;function getDebug()return true end
function getWorld()return {getWorld=function()return 'AstroluxStructureLab'end}end
local record
package.loaded['TSBAstroluxStructure/Records']={near=function()return record end}
local player={isDead=function()return false end,getZ=function()return 0 end,getPlayerNum=function()return 0 end,Say=function()end}
function getSpecificPlayer()return player end
ISModalRichText={new=function(_,x,y,w,h,text,yesno,target,handler)
 local d={text=text,yesno=yesno,handler=handler,initialise=function()end,addToUIManager=function()end};dialogs[#dialogs+1]=d;return d
end}
local context={addSubMenu=function()end,addOption=function(_,label,target,handler)
 local o={name=label,handler=handler};if handler then options[label]=o end;return o
end}
ISContextMenu={getNew=function()return context end}
local sq={getZ=function()return 0 end,getX=function()return 100 end,getY=function()return 200 end}
local object={getSquare=function()return sq end,getSprite=function()return nil end}
local blocked=true;local pastes=0
TSBAstroluxStructure={preview=function()if blocked then return nil,'Dropped item blocks site'end;return {}end,
 paste=function(p,x,y)assert(p==player and x==100 and y==200);pastes=pastes+1;return {}end,
 remove=function()return nil,'Body blocks site'end}
dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/client/TSBAstroluxStructure/Menu.lua')
callback(0,context,{object},false)
assert(options['Place furnished showroom here'] and not options['Remove this showroom'])
options['Place furnished showroom here'].handler();assert(not dialogs[1].yesno and dialogs[1].text:find('Dropped item'))
blocked=false;options['Place furnished showroom here'].handler();assert(dialogs[2].yesno and pastes==0)
dialogs[2].handler(nil,{internal='NO'});assert(pastes==0)
options['Place furnished showroom here'].handler();dialogs[3].handler(nil,{internal='YES'});assert(pastes==1)
record={id='tower',x=100,y=200};options={};callback(0,context,{object},false)
assert(options['Remove this showroom'] and options['Save furnishings and inventory'] and not options['Place furnished showroom here'])
options['Remove this showroom'].handler();dialogs[4].handler(nil,{internal='YES'})
assert(not dialogs[5].yesno and dialogs[5].text:find('Body blocks'))
options={};callback(0,context,{object},true);assert(next(options)==nil,'Probe must not mutate menu')
print('PASS: right-click menu, location-sensitive placement/removal, confirmation and readable refusal dialogs')
