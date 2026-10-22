local Amount=require 'TSBAstroluxVend/Amount'
-- Persistent world demand. Base catalog prices are never mutated.
local C=require 'TSBAstroluxVend/Config'
local D={}
function D.family(script)return C.demandFamilies[script] or script end
local function validTime(hours)
    if type(hours)~='number' or hours~=hours or hours<0 or hours==math.huge then error('Invalid demand clock.',0)end
    return hours
end
function D.state(db,script,hours)
    validTime(hours)
    local family=D.family(script)
    local s=db.vehicleDemand and db.vehicleDemand[family]
    if not s then return 0,0,family end
    -- Do not increase demand after a clock rewind or decay it below base.
    local elapsed=math.max(0,hours-s.hours)
    return math.max(0,s.points-elapsed*(2/24)),s.revision,family
end
function D.offer(db,offer,hours)
    local points,revision,family=D.state(db,offer.script,hours)
    local result={};for k,v in pairs(offer)do result[k]=v end
    result.basePrice=offer.price
    local dynamic=not db.pricing or db.pricing.dynamic~=false
    if not dynamic then points=0;revision=0 end
    result.price=Amount.check(math.floor((offer.price+0.0)*(100+points)/100),1)
    result.pricingRevision=(db.pricing or {}).revision or 0
    result.demandRevision=revision;result.demandFamily=family
    result.pricing={};for k,v in pairs(offer.pricing or {})do result.pricing[k]=v end
    result.pricing.total=result.price;result.pricing.baseTotal=offer.price
    result.pricing.demandMarkup=result.price-offer.price;result.pricing.dynamic=dynamic
    return result
end
function D.completed(db,order,hours)
    if order.status~='delivered' or order.demandCounted then return false end
    if db.pricing and db.pricing.dynamic==false then return false end
    local points,revision,family=D.state(db,order.script,hours)
    db.vehicleDemand=db.vehicleDemand or {}
    local old=db.vehicleDemand[family]
    db.vehicleDemand[family]={points=points+2,hours=math.max(hours,old and old.hours or hours),revision=revision+1}
    order.demandCounted=true;order.demandFamily=family
    return true
end
return D
