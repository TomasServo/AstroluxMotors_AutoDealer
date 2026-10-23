local A={key='TSBAstroluxVend.Audio.v1'}
function A.settings()
    if isClient()then return ModData.get(A.key) or {}end
    return ModData.getOrCreate('TSBAstroluxVend.State.v1').audio or {}
end
function A.enabled(key)return A.settings()[key]~=false end
function A.volume(key)
    local defaults={purchaseVolume=15,musicVolume=10}
    local n=A.settings()[key]
    return (type(n)=='number' and n>=0 and n<=100 and n or defaults[key] or 0)/100
end
-- World defaults stay separate from client-only overrides.
function A.playbackVolume(key,player)
 return require('TSBAstroluxVend/PersonalAudioSettings').volume(player,key,A.volume(key))
end
function A.playbackEnabled(key,player)
 return A.enabled(key) and not require('TSBAstroluxVend/PersonalAudioSettings').muted(player,key)
end
function A.refreshPurchase(player)
 if not A.purchaseHandle or (A.purchasePlayer and A.purchasePlayer~=player)then return end
 if not A.playbackEnabled('purchaseSound',player) or A.playbackVolume('purchaseVolume',player)==0 then
  pcall(function()getSoundManager():stopUISound(A.purchaseHandle)end);A.purchaseHandle=nil
 else pcall(function()getSoundManager():getUIEmitter():setVolume(A.purchaseHandle,A.playbackVolume('purchaseVolume',player))end)end
end
function A.pausePurchase()
 A.purchasePaused=true
 if A.purchaseHandle then pcall(function()getSoundManager():stopUISound(A.purchaseHandle)end);A.purchaseHandle=nil end
end
function A.resumePurchase()
 A.pausePurchase();A.purchasePaused=false;A.playPurchase()
end
function A.playPurchase(player)
    if A.purchasePaused or not A.playbackEnabled('purchaseSound',player) or A.playbackVolume('purchaseVolume',player)==0 then return end
    pcall(function()
        local manager=getSoundManager();local id=manager:playUISound('TSBAstroluxPurchase')
        if id and id~=0 then A.purchaseHandle=id;A.purchasePlayer=player;manager:getUIEmitter():setVolume(id,A.playbackVolume('purchaseVolume',player))end
    end)
end
function A.edit(args)
    if type(args.purchaseSound)~='boolean' or type(args.showroomMusic)~='boolean'then error('Invalid audio settings.',0)end
    local values={}
    for _,key in ipairs({'purchaseVolume','musicVolume'})do
        local n=args[key];if n==nil then n=math.floor(A.volume(key)*100+0.5) end
        if type(n)~='number' or n~=n or n<0 or n>100 or n~=math.floor(n)then error('Enter whole audio volumes from 0 to 100.',0)end
        values[key]=n
    end
    values.purchaseSound=args.purchaseSound;values.showroomMusic=args.showroomMusic;return values
end
function A.publish()
    if isClient()then return end
    local settings=A.settings()
    ModData.add(A.key,{purchaseSound=settings.purchaseSound~=false,showroomMusic=settings.showroomMusic~=false,purchaseVolume=math.floor(A.volume('purchaseVolume')*100+0.5),musicVolume=math.floor(A.volume('musicVolume')*100+0.5)})
    if isServer()then ModData.transmit(A.key)end
end
Events.OnInitGlobalModData.Add(function()if not isClient()then A.publish()end end)
Events.OnGameStart.Add(function()if isClient()then ModData.request(A.key)else A.publish()end end)
Events.OnReceiveGlobalModData.Add(function(key,data)
    if key==A.key and type(data)=='table' and type(data.purchaseSound)=='boolean' and type(data.showroomMusic)=='boolean'then local ok,valid=pcall(A.edit,data);if ok then ModData.add(key,valid)end end
end)
return A
