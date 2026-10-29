-- Shared stock-equipment policy. Never edit Workshop scripts or owned vehicles.
local S={version=1}
local Adapters=require 'TSBAstroluxVend/VehicleAdapters'
require 'TSBAstroluxVend/Adapters/Hilux88'
-- Legacy save/order helper; new providers use registry metadata.
function S.isHilux(name)local a=Adapters.get(name);return a and a.legacyHilux==true or false end
local extraWords={'armor','armour','roofrack','roofbasket','luggagerack','bullbar','rollbar','sidesteps','steprail','mudflaps','sparetire','truckbedextras','generator'}
function S.optional(id)
    local s=string.lower(id or ''):gsub('[^%w]','')
    for _,word in ipairs(extraWords)do if s:find(word,1,true)then return true end end
    return s:match('rack%d*$')~=nil and not s:find('track',1,true)
end
function S.choice(script,id)
 local a=Adapters.get(script);local choice=a and (a.stock or {})[id]
 if choice then return choice[1],choice[2]end
end
function S.blank(script,id)
 local a=Adapters.get(script);return a and (a.blankParts or {})[id]==true or false
end
function S.validate(script)
    -- A body mesh authored as an armored/rack-equipped variant cannot safely
    -- be stripped like an optional slot. Refuse known variants before payment.
    local name=string.lower(script:getFullName())
    local model=script:getModel()
    local file=model and model.getFile and string.lower(model:getFile() or '') or ''
    for _,word in ipairs({'armored','armoured','armor','armour','roofrack','luggagerack'})do
        if name:find(word,1,true) or file:find(word,1,true)then
            error('Choose the stock vehicle script; this body includes accessories: '..script:getFullName(),0)
        end
    end
end
return S
