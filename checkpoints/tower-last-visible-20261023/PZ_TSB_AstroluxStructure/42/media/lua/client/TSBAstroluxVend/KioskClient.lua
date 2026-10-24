local Menus=require 'TSBAstroluxVend/ContextMenu'
require 'ISUI/ISModalRichText'
local C=require 'TSBAstroluxVend/Config'
local labels={'South','East','North','West'}
local requester
TSBAstroluxKioskClient={}
function TSBAstroluxKioskClient.receive(data)
    if requester and data.message then requester:Say(data.message)end
end
Events.OnServerCommand.Add(function(module,command,data)
    if module==C.channel and command=='kioskResult' then TSBAstroluxKioskClient.receive(data)end
end)
Events.OnFillWorldObjectContextMenu.Add(function(playerNum,context,objects,test)
    if test then return end
    local p=getSpecificPlayer(playerNum)
    if not p or p:isDead() or (isClient() and tostring(p:getAccessLevel()):lower()~='admin')then return end
    local sq
    for _,obj in ipairs(objects)do if obj:getSquare()then sq=obj:getSquare();break end end
    if not sq or sq:getZ()~=0 then return end
    local x,y=sq:getX(),sq:getY()
    -- Inspect all objects on the clicked square: old brush kiosks lack ModData.
    local tiles=sq:getObjects()
    for n=0,tiles:size()-1 do
        local kiosk=tiles:get(n);local sprite=kiosk:getSprite();local name=sprite and sprite:getName()
        local props=sprite and sprite:getProperties()
        local label=props and (tostring(props:get('GroupName') or '')..' '..tostring(props:get('CustomName') or '')):lower() or ''
        if kiosk:getContainer() and label:find('corner',1,true) and (label:find('counter',1,true) or label:find('cabinet',1,true)) then
            local target=kiosk
            Menus.section(context,'Administration'):addOption('Use as coffee supplies cabinet',p,function()
                local args={x=x,y=y,index=target:getObjectIndex()}
                if isClient() then sendClientCommand(p,C.channel,'coffeeCabinet',args)
                elseif TSBAstroluxVendServer then TSBAstroluxVendServer.handle(p,'coffeeCabinet',args) end
            end)
        end
        if type(name)=='string' and name:match('^TSBAstroluxKiosk_[0-3]$') then
            local target=kiosk;local targetName=name
            Menus.section(context,'Administration'):addOption('Remove this sales kiosk',p,function()
                local text='Remove this Astrolux sales kiosk? <LINE> Its registration and vehicle spawn area will be retired. <LINE> Purchase and trade-in history will be retained. Outstanding purchases must be resolved first.'
                local modal=ISModalRichText:new(100,100,540,230,text,true,nil,function(_,button)
                    if button.internal~='YES' then return end
                    requester=p
                    local args={x=x,y=y,index=target:getObjectIndex(),sprite=targetName,confirmed=true}
                    if isClient() then sendClientCommand(p,C.channel,'kioskRemove',args)
                    elseif TSBAstroluxVendServer then TSBAstroluxVendServer.handle(p,'kioskRemove',args) end
                end,playerNum)
                modal:initialise();modal:addToUIManager()
            end)
        end
    end
end)
