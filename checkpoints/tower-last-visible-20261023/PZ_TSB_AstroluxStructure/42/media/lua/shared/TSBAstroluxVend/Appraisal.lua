local Amount=require 'TSBAstroluxVend/Amount'
local Profiles=require 'TSBAstroluxVend/AppraisalProfiles'
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
function A.calculate(vehicle,price,rate,damageRate)
    if not Amount.valid(price,1) then error('Invalid retail price.',0)end
    if type(rate)~='number' or rate~=rate or rate<0 or rate>1 then error('Invalid trade-in rate.',0)end
    damageRate=damageRate==nil and 1 or damageRate
    if type(damageRate)~='number' or damageRate~=damageRate or damageRate<0 or damageRate>1 then error('Invalid damage deduction.',0)end
    local script=vehicle:getScript():getFullName()
    local profile=Profiles.vehicles[script]
    if not profile then error('Vehicle stock appraisal profile has not been reviewed.',0)end
    local byId={}
    local count=vehicle:getPartCount()
    if count>500 then error('Vehicle has no supported part appraisal.',0)end
    for i=0,count-1 do
        local part=vehicle:getPartByIndex(i);local id=part:getId()
        if byId[id] then error('Duplicate vehicle part.',0)end
        byId[id]=part
    end
    local rows,earned,totalWeight={},0,0
    for _,id in ipairs(profile)do
        local part=byId[id]
        -- Engine/heater are native components without an inventory item.
        local missing=not part or ((id~='Engine' and id~='Heater') and part:isInventoryItemUninstalled())
        local condition=missing and 0 or percent(part:getCondition())
        -- Preserve existing engine-quality policy; this batch changes equipment/weights only.
        if id=='Engine' then condition=math.min(condition,percent(vehicle:getEngineQuality()))end
        local w=weight(id);totalWeight=totalWeight+w
        rows[#rows+1]={id=id,condition=condition,missing=missing,weight=w}
    end
    if totalWeight==0 then error('Vehicle has no supported part appraisal.',0)end
    table.sort(rows,function(a,b)return a.id<b.id end)
    local maximum=math.floor(price*rate)
    local fingerprints={'profile:'..Profiles.version,script,'rate:'..rate,'damage:'..damageRate}
    local allocated,cumulative=0,0
    for _,row in ipairs(rows)do
        cumulative=cumulative+row.weight
        local boundary=math.floor(maximum*cumulative/totalWeight)
        row.maximum=boundary-allocated;allocated=boundary
        -- Missing parts retain zero value even when damage deductions are disabled.
        row.value=row.missing and 0 or math.floor(row.maximum*(1-damageRate*(100-row.condition)/100))
        earned=earned+row.value
        fingerprints[#fingerprints+1]=row.id..':'..row.condition..':'..tostring(row.missing)..':'..row.maximum
    end
    return {amount=earned,retail=price,maximum=maximum,rate=rate,parts=rows,
        fingerprint=table.concat(fingerprints,'|')}
end
return A
