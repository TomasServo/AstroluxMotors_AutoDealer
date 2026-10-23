-- World policy is authoritative; clients receive a dedicated small snapshot.
local B={key='TSBAstroluxVend.Buffs.v1'}
function B.settings()
    if isClient and isClient() then local data=ModData.get(B.key);return data and data.settings or {}end
    return ModData.getOrCreate('TSBAstroluxVend.State.v1').pricing or {}
end
function B.enabled()
    if isClient and isClient() then
        local data=ModData.get(B.key)
        return data and data.enabled~=false or data==nil
    end
    local db=ModData.getOrCreate('TSBAstroluxVend.State.v1')
    return not db.pricing or db.pricing.addonBuffs~=false
end
function B.publish()
    if isClient and isClient() then return end
    local data=ModData.getOrCreate(B.key)
    data.enabled=B.enabled();data.settings={addonBuffs=B.enabled(),accessories=B.settings().accessories or {},camperTop=B.settings().camperTop}
    if isServer and isServer() then ModData.transmit(B.key)end
end
if Events then
    Events.OnInitGlobalModData.Add(function() if not (isClient and isClient()) then B.publish()end end)
    Events.OnGameStart.Add(function()
        if isClient and isClient() then ModData.request(B.key) else B.publish()end
    end)
    Events.OnReceiveGlobalModData.Add(function(key,data)
        if key==B.key and type(data)=='table' and type(data.enabled)=='boolean' then ModData.add(key,data)end
    end)
end
return B
