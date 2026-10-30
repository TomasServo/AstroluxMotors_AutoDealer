package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
local base='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
for _,file in ipairs({'client/TSBAstroluxVend/PersonalAudioSettings.lua','client/TSBAstroluxVend/PersonalAudioPanel.lua','shared/TSBAstroluxVend/AudioSettings.lua','client/TSBAstroluxStructure/ShowroomMusic.lua','client/TSBAstroluxVend/Client.lua','client/TSBAstroluxVend/TabsUI.lua'})do assert(loadfile(base..file))end
local disk={};local writes=0
function getFileReader(file)
 if not disk[file]then return nil end
 local lines={};for line in disk[file]:gmatch('[^\n]+')do lines[#lines+1]=line end
 local i=0;return {readLine=function()i=i+1;return lines[i]end,close=function()end}
end
function getFileWriter(file)
 writes=writes+1;local value='';return {write=function(_,text)value=value..text end,close=function()disk[file]=value end}
end
local function player(name,slot,x)
 return {getUsername=function()return name end,getPlayerNum=function()return slot end,isDead=function()return false end,getZ=function()return 0 end,getX=function()return x or 11 end,getY=function()return 21 end}
end
local alice,bob=player('Alice',0),player('Bob',1)
function getSpecificPlayer(i)return i==0 and alice or bob end
local P=dofile(base..'client/TSBAstroluxVend/PersonalAudioSettings.lua')
package.loaded['TSBAstroluxVend/PersonalAudioSettings']=P
assert(P.volume(alice,'purchaseVolume',.15)==1)
assert(P.save(alice,{musicVolume=35,mutePurchase=true}))
assert(P.volume(alice,'musicVolume',.1)==.35 and P.muted(alice,'purchaseSound'))
assert(P.volume(bob,'musicVolume',.1)==.25 and not P.muted(bob,'purchaseSound'),'other player unchanged')
assert(P.volume(alice,'purchaseVolume',.25)==1,'unset personal purchase volume remains 100 percent of world volume')
local Reload=dofile(base..'client/TSBAstroluxVend/PersonalAudioSettings.lua')
assert(Reload.volume(alice,'musicVolume',.1)==.35 and Reload.muted(alice,'purchaseSound'),'disk reload')
assert(not P.save(alice,{musicVolume=101}) and not P.save(alice,{purchaseVolume=2.5}))
assert(P.file(alice)~=P.file(player('Alice',1)),'local slots isolated')
assert(P.save(alice,{}));assert(P.volume(alice,'musicVolume',.1)==.25 and not P.muted(alice,'purchaseSound'),'reset restores personal defaults')
local db={audio={purchaseSound=true,showroomMusic=true,purchaseVolume=15,musicVolume=10}}
function isClient()return false end
function isServer()return false end
Events=setmetatable({},{__index=function(t,k)local e={Add=function()end};t[k]=e;return e end})
ModData={getOrCreate=function()return db end}
local Audio=dofile(base..'shared/TSBAstroluxVend/AudioSettings.lua')
package.loaded['TSBAstroluxVend/AudioSettings']=Audio
local played=0;local gain;local stopped=0
local emitter={setVolume=function(_,id,v)assert(id==17);gain=v end}
local manager={playUISound=function()played=played+1;return 17 end,getUIEmitter=function()return emitter end,isPlayingUISound=function()return true end,stopUISound=function()stopped=stopped+1 end}
function getSoundManager()return manager end
package.loaded['TSBAstroluxVend/ClipVolume']={set=function(name,v)gain=v end}
package.loaded['TSBAstroluxStructure/Electricity']={showroom=function()return true end}

assert(P.save(alice,{purchaseVolume=30,musicVolume=25,muteMusic=true}))
Audio.playPurchase(alice);assert(played==1 and math.abs(gain-.15*.30)<1e-8)
assert(Audio.volume('purchaseVolume')==.15 and db.audio.purchaseVolume==15,'world default not modified')
db.audio.purchaseSound=false;Audio.playPurchase(alice);assert(played==1,'world disable wins')
db.audio.purchaseSound=true;assert(P.save(alice,{mutePurchase=true}));Audio.playPurchase(alice);assert(played==1,'personal mute wins')
assert(P.save(alice,{musicVolume=25,muteMusic=true}))
package.loaded['TSBAstroluxStructure/Records']={all=function()return {{x=10,y=20}}end}
bob=player('Bob',1,100)
function getNumActivePlayers()return 2 end
local Music=dofile(base..'client/TSBAstroluxStructure/ShowroomMusic.lua')
Music.update();assert(played==1,'muted occupant and outside listener: no music')
assert(P.save(alice,{musicVolume=25}));Music.update();assert(played==2 and math.abs(gain-.10*.25)<1e-8,'personal music gain inside')
assert(P.save(alice,{musicVolume=0}));Music.update();assert(not Music.sound and stopped>0,'zero immediately stops on update')
-- Check mute-only UI updates preserve inherited volume rather than freezing it.
for _,name in ipairs({'ISUI/ISComboBox','ISUI/ISModalRichText','ISUI/ISPanel','ISUI/ISTickBox','ISUI/ISButton','RadioCom/ISUIRadio/ISSliderPanel'})do package.preload[name]=function()return {}end end
ISPanel={derive=function()return {}end}
local UI=dofile(base..'client/TSBAstroluxVend/PersonalAudioPanel.lua')
assert(P.save(alice,{}))
local panel={ready=true,player=alice,pending={},mutes={mutePurchase={isSelected=function()return true end},muteMusic={isSelected=function()return false end}}}
UI.save(panel);assert(P.get(alice).purchaseVolume==nil and P.get(alice).musicVolume==nil and P.muted(alice,'purchaseSound'))
print('PASS personal audio: syntax, local persistence/reload, identity isolation, personal fractions/defaults/reset, invalid values, personal/world mute, purchase gain, inside-only music, zero mute and mute-only UI inheritance')
