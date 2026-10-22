package.preload['ISUI/ISModalRichText']=function() return true end
local callback,options,dialogs=nil,{},{}
Events={OnFillWorldObjectContextMenu={Add=function(fn) callback=fn end}}
function isClient() return false end
function isServer() return false end
function getDebug() return true end
function getWorld() return {getWorld=function() return 'AstroluxStructureLab' end} end
local player={isDead=function() return false end,getZ=function() return 0 end,getPlayerNum=function() return 0 end,Say=function() end}
function getSpecificPlayer() return player end
ISModalRichText={new=function(_,x,y,w,h,text,yesno,target,handler)
    local d={text=text,yesno=yesno,handler=handler,initialise=function() end,addToUIManager=function() end}
    dialogs[#dialogs+1]=d;return d
end}
local context={addOption=function(_,label,target,handler) options[#options+1]={label=label,handler=handler} end}
local square={getZ=function() return 0 end,getX=function() return 100 end,getY=function() return 200 end}
local blocked=true
TSBAstroluxStructure={preview=function() if blocked then return nil,'Dropped item blocks the site at 100, 200, 0' end;return {} end,
    place=function() return nil,'Person blocks the site at 101, 201, 0' end,
    remove=function() return nil,'Body blocks the site at 102, 202, 0' end}
dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/client/TSBAstroluxStructure/Menu.lua')
callback(0,context,{{getSquare=function() return square end}},false)
assert(#options==3,'Ground context must contain preview and removal')
options[1].handler();assert(#dialogs==1 and not dialogs[1].yesno and dialogs[1].text:find('Dropped item'))
blocked=false;options[1].handler();assert(dialogs[2].yesno)
dialogs[2].handler(nil,{internal='YES'});assert(not dialogs[3].yesno and dialogs[3].text:find('101, 201, 0'))
options[2].handler();dialogs[4].handler(nil,{internal='YES'})
assert(not dialogs[5].yesno and dialogs[5].text:find('102, 202, 0'))
print('PASS: right-click menu, readable rejection dialogs and placement revalidation feedback')
