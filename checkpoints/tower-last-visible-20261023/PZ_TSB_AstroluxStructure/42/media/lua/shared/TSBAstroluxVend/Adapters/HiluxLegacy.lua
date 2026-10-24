local Amount=require 'TSBAstroluxVend/Amount'
local Stock=require 'TSBAstroluxVend/Stock'
local C=require 'TSBAstroluxVend/Config'
local A={part='HLX88TruckBedExtras',item='Base.88toyotaHiluxBedCap2',model='HLX88Cap'}
function A.supports(script)
    if not script or not Stock.isHilux(script:getFullName()) then return false end
    for i=0,script:getPartCount()-1 do
        local part=script:getPart(i)
        if part:getId()==A.part then return part:getModelById(A.model)~=nil end
    end
    return false
end
function A.price(settings)return Amount.check((settings or {}).camperTop or C.camperTopPrice,1)end
function A.offer(offer,script,settings,selected)
    if selected~=nil and type(selected)~='boolean' then error('Invalid camper top selection.',0)end
    if selected and not A.supports(script) then error('Camper top is unavailable for this vehicle.',0)end
    local result={};for k,v in pairs(offer)do result[k]=v end
    result.camperTop=selected==true
    result.camperSurcharge=result.camperTop and A.price(settings) or 0
    result.price=Amount.add(offer.price,result.camperSurcharge)
    return result
end
function A.verify(selected,script)
    if selected~=nil and type(selected)~='boolean' then error('Invalid saved camper top selection.',0)end
    if selected and not A.supports(script) then error('Paid camper top is no longer compatible; inspect the order.',0)end
end
return A
