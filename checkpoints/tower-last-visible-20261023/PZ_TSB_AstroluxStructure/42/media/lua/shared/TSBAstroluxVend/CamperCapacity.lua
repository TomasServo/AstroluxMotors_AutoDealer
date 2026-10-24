-- Actual installed equipment controls capacity; never move or delete cargo.
local Stock=require 'TSBAstroluxVend/Stock'
local Buffs=require 'TSBAstroluxVend/BuffSettings'
local Equipment=require 'TSBAstroluxVend/Equipment'
local B={}
local seen=setmetatable({},{__mode='k'})
function B.update(vehicle)
    if not vehicle then return end
    local targetPart=Equipment.capacityPart(vehicle:getScript())
    if not targetPart then return end
    local bed=vehicle:getPartById(targetPart)
    local container=bed and bed:getItemContainer()
    local bedItem=bed and bed:getInventoryItem()
    if not container or not bedItem then return end
    local bonus=0;local signature={}
    local settings=Buffs.settings()
    for _,definition in ipairs(Equipment.list(vehicle:getScript()))do
        local slots=Equipment.compatible(vehicle:getScript(),definition)
        if slots then
            local installed=true
            for _,s in ipairs(slots)do local p=vehicle:getPartById(s.part);local i=p and p:getInventoryItem()
                if not i or i:getFullType()~=s.item then installed=false;break end
            end
            signature[#signature+1]=definition.id..tostring(installed)
            if installed then local policy=Equipment.policy(settings,vehicle:getScript():getFullName(),definition.id)
                if Buffs.enabled() and policy.buffEnabled then bonus=require('TSBAstroluxVend/Amount').add(bonus,policy.capacityBonus)end
            end
        end
    end
    local installed=table.concat(signature,'|')
    local old=seen[vehicle]
    if old and old.item==bedItem and old.condition==bed:getCondition() and old.installed==installed
        and old.bonus==bonus and bed:getContainerCapacity()==old.target and container:getCapacity()==old.target then return end
    -- Recalculate the original capacity through the native item/condition path.
    -- This avoids accumulating bonuses and preserves condition-based capacity.
    bed:doInventoryItemStats(bedItem,bed:getMechanicSkillInstaller())
    local base=bed:getContainerCapacity()
    local target=base+bonus
    bed:setContainerCapacity(target)
    seen[vehicle]={item=bedItem,condition=bed:getCondition(),installed=installed,bonus=bonus,target=target}
end
function B.scan()
    local cell=getCell();if not cell then return end
    local vehicles=cell:getVehicles():iterator()
    while vehicles:hasNext()do B.update(vehicles:next())end
end
if Events then
    local last=0
    Events.OnTick.Add(function()
        local now=getTimestampMs()
        if now<last or now-last>=1000 then last=now;B.scan()end
    end)
    Events.OnGameStart.Add(B.scan)
    Events.OnMechanicActionDone.Add(B.scan)
end
return B
