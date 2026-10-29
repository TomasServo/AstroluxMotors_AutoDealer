local Amount=require 'TSBAstroluxVend/Amount'
local Profiles=require 'TSBAstroluxVend/AppraisalProfiles'
local Roles=require 'TSBAstroluxVend/AppraisalPartRoles'
local A={}
local function percent(n)
    if type(n)~='number' or n~=n or n<0 or n>100 then error('Invalid vehicle condition.',0)end
    return n
end
local function weight(id)
    -- Integer relative weights, not replacement prices. Bulbs are 1/20 of doors.
    if id:find('Headlight',1,true)==1 then return 1 end
    if id=='Engine' then return 80 end
    if id=='GasTank' then return 30 end
    if id:find('Tire',1,true)==1 or id:find('Brake',1,true)==1 or
        id:find('Suspension',1,true)==1 or id=='Battery' then return 20 end
    if id:find('Door',1,true)==1 or id=='EngineDoor' or id=='TrunkDoor' or
        id=='DAMNBumperFront' or id=='DAMNBumperRear' then return 20 end
    return 10
end
function A.calculate(vehicle,price,rate,damageRate,settings)
    if not Amount.valid(price,1) then error('Invalid retail price.',0)end
    if type(rate)~='number' or rate~=rate or rate<0 or rate>1 then error('Invalid trade-in rate.',0)end
    damageRate=damageRate==nil and 1 or damageRate
    if type(damageRate)~='number' or damageRate~=damageRate or damageRate<0 or damageRate>1 then error('Invalid damage deduction.',0)end
    local script=vehicle:getScript():getFullName()
    local profile=Profiles.resolve(vehicle,settings)
    if not profile then error('Vehicle part definitions are unavailable.',0)end
    local byId={}
    local count=vehicle:getPartCount()
    if count>500 then error('Vehicle has no supported part appraisal.',0)end
    for i=0,count-1 do
        local part=vehicle:getPartByIndex(i);local id=part:getId()
        if byId[id] then error('Duplicate vehicle part.',0)end
        byId[id]=part
    end
    local rows,earned,totalWeight,fixedRetail={},0,0,0
    for _,id in ipairs(profile)do
        local part=byId[id]
        -- Engine/heater are native components without an inventory item.
        local missing=not part or ((id~='Engine' and id~='Heater') and part:isInventoryItemUninstalled())
        local condition=missing and 0 or percent(part:getCondition())
        -- Preserve existing engine-quality policy; this batch changes equipment/weights only.
        if id=='Engine' then condition=math.min(condition,percent(vehicle:getEngineQuality()))end
        local rule=Roles.get(settings,script,id)
        local retail=rule and rule.role=='base' and rule.price or nil
        local w=weight(id)
        if retail~=nil then fixedRetail=Amount.add(fixedRetail,Amount.check(retail,0))else totalWeight=totalWeight+w end
        rows[#rows+1]={id=id,condition=condition,missing=missing,weight=w,retail=retail}
    end
    if #rows==0 then error('Vehicle has no supported part appraisal.',0)end
    table.sort(rows,function(a,b)return a.id<b.id end)
    local unpricedMaximum=math.floor(math.max(0,price-fixedRetail)*rate)
    local maximum=0
    local fingerprints={'profile:'..Profiles.version,script,'rate:'..rate,'damage:'..damageRate}
    local allocated,cumulative=0,0
    for _,row in ipairs(rows)do
        if row.retail~=nil then row.maximum=math.floor(row.retail*rate)
        else
            cumulative=cumulative+row.weight
            local boundary=math.floor(unpricedMaximum*cumulative/totalWeight)
            row.maximum=boundary-allocated;allocated=boundary
        end
        maximum=Amount.add(maximum,row.maximum)
        -- Missing parts retain zero value even when damage deductions are disabled.
        row.value=row.missing and 0 or math.floor(row.maximum*(1-damageRate*(100-row.condition)/100))
        earned=earned+row.value
        fingerprints[#fingerprints+1]=row.id..':'..row.condition..':'..tostring(row.missing)..':'..row.maximum
    end
    local extraRows,extraMarks,extraValue,extraMaximum=require('TSBAstroluxVend/AccessoryAppraisal').calculate(vehicle,byId,rate,damageRate,settings,profile)
    for _,row in ipairs(extraRows)do rows[#rows+1]=row end
    for _,mark in ipairs(extraMarks)do fingerprints[#fingerprints+1]=mark end
    earned=Amount.add(earned,extraValue);maximum=Amount.add(maximum,extraMaximum)
    -- Cap the complete pristine appraisal at this car's retail price, including
    -- all accessories. Allocate the cap before condition deductions so damage
    -- still matters and displayed part values sum to the actual payout.
    if maximum>price then
        local full=maximum;local cumulative,boundary=0,0;earned=0
        for i,row in ipairs(rows)do
            cumulative=Amount.add(cumulative,row.maximum)
            local nextBoundary=i==#rows and price or math.floor(price*(cumulative/full))
            row.maximum=nextBoundary-boundary;boundary=nextBoundary
            row.value=row.missing and 0 or math.floor(row.maximum*(1-damageRate*(100-row.condition)/100))
            earned=Amount.add(earned,row.value)
        end
        maximum=price;fingerprints[#fingerprints+1]='retail-cap:'..price
    end
    return {amount=earned,retail=price,maximum=maximum,rate=rate,parts=rows,
        fingerprint=table.concat(fingerprints,'|')}
end
return A
