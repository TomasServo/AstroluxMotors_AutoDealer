function getSpecificPlayer()return nil end
package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
function getCore()return {getOptionMusicVolume=function()return 2 end}end
local callbacks={}
Events=setmetatable({},{__index=function(t,k)local e={Add=function(fn)callbacks[k]=fn end};t[k]=e;return e end})
local db,network={},{}
local client=false
function isClient()return client end
function isServer()return not client end
ModData={get=function(key)return network[key]end,getOrCreate=function()return db end,add=function(k,v)network[k]=v end,transmit=function()end}
local played=0;local volume;local stopped=false
local emitter={setVolume=function(_,id,v)assert(id==17);volume=v end}
local manager={playUISound=function()played=played+1;return 17 end,getUIEmitter=function()return emitter end,isPlayingUISound=function()return true end,stopUISound=function()stopped=true end}
function getSoundManager()return manager end
package.loaded['TSBAstroluxVend/ClipVolume']={set=function(name,v)volume=v end}
package.loaded['TSBAstroluxStructure/Electricity']={showroom=function()return true end}

local Audio=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/TSBAstroluxVend/AudioSettings.lua')
assert(Audio.volume('purchaseVolume')==1 and Audio.volume('musicVolume')==1 and Audio.volume('doorVolume')==1)
db.audio=Audio.edit({purchaseSound=true,showroomMusic=true,purchaseVolume=29,musicVolume=15})
Audio.playPurchase();assert(played==1 and volume==.29)
Audio.publish();assert(network[Audio.key].purchaseVolume==29)
client=true;callbacks.OnReceiveGlobalModData(Audio.key,network[Audio.key]);assert(Audio.volume('purchaseVolume')==.29);client=false
for _,bad in ipairs({-1,101,math.huge,'50',2.5})do assert(not pcall(Audio.edit,{purchaseSound=true,showroomMusic=true,purchaseVolume=bad,musicVolume=10}))end
db.audio.purchaseVolume=0;Audio.playPurchase();assert(played==1)
db.audio.purchaseVolume=100;db.audio.purchaseSound=false;Audio.playPurchase();assert(played==1)
package.loaded['TSBAstroluxVend/AudioSettings']=Audio
package.loaded['TSBAstroluxStructure/Records']={all=function()return {{x=10,y=20}}end}
function getNumActivePlayers()return 1 end
function getSpecificPlayer()return {isDead=function()return false end,getZ=function()return 0 end,getUsername=function()return 'audio-test'end,getPlayerNum=function()return 0 end,getX=function()return 11 end,getY=function()return 21 end}end
local M=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/client/TSBAstroluxStructure/ShowroomMusic.lua')
M.update();assert(math.abs(volume-(.15*.25))<.000001);local count=played;db.audio.musicVolume=65;M.update();assert(math.abs(volume-(.65*.25))<.000001 and played==count)
db.audio.showroomMusic=false;M.update();assert(stopped and not M.sound)
print('PASS audio defaults, percent validation, mute/disable, exact percent sync, purchase volume, live music volume and stop without restarting loop')

db.audio.showroomMusic=true;M.play();assert(M.sound and not M.paused)
M.pause();assert(M.paused and not M.sound);local before=played;M.update();assert(played==before)
M.play();assert(M.sound and played==before+1)
db.audio.purchaseSound=true;db.audio.purchaseVolume=50;Audio.resumePurchase();before=played;Audio.pausePurchase();Audio.playPurchase();assert(played==before);Audio.resumePurchase();assert(played==before+1)
package.loaded['TSBAstroluxStructure/ShowroomMusic']=M
local Controls=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/client/TSBAstroluxVend/AudioPreview.lua')
Controls.pause('music');Controls.stopAll();assert(M.paused);Controls.play('music');assert(not M.paused and M.sound)
print('PASS actual music/purchase pause, automatic playback suppressed while paused, Play restarts, menu closure preserves playback state')
