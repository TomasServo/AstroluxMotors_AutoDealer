-- Shared stock-equipment policy. Never edit Workshop scripts or owned vehicles.
local S={version=1}
local hilux={['Base.88toyotaHiluxSC']=true,['Base.88toyotaHiluxXC']=true,['Base.88toyotaHiluxXCS']=true}
function S.isHilux(name)return hilux[name]==true end
local extraWords={'armor','armour','roofrack','roofbasket','luggagerack','bullbar','rollbar','sidesteps','steprail','mudflaps','sparetire','truckbedextras','generator'}
function S.optional(id)
    local s=string.lower(id or ''):gsub('[^%w]','')
    for _,word in ipairs(extraWords)do if s:find(word,1,true)then return true end end
    return s:match('rack%d*$')~=nil and not s:find('track',1,true)
end
function S.choice(script,id)
    if S.isHilux(script) then
        if id=='DAMNBumperFront' then return 'Base.88toyotaHiluxBumperFront0','FrontBumper0' end
        if id=='DAMNBumperRear' then return 'Base.88toyotaHiluxBumperRear0','RearBumper0' end
        if id=='TireFrontLeft' or id=='TireFrontRight' or id=='TireRearLeft' or id=='TireRearRight' then
            return 'Base.88toyotaHiluxTire2','HLX88Tire0'
        end
    end
end
function S.blank(script,id)
    return S.isHilux(script) and id=='TruckBed'
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
