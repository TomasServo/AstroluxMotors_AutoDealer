local Stock=require 'TSBAstroluxVend/Stock'
local D={}
function D.prepare(vehicle)
    local script=vehicle:getScript():getFullName()
    local changes={}
    for i=0,vehicle:getPartCount()-1 do
        local part=vehicle:getPartByIndex(i);local id=part:getId()
        local itemType,model=Stock.choice(script,id)
        if Stock.optional(id)then
            changes[#changes+1]={part=part,empty=true}
        elseif itemType then
            local item=instanceItem(itemType)
            if not item then error('Stock equipment unavailable: '..itemType,0)end
            changes[#changes+1]={part=part,item=item,model=model}
        end
    end
    -- Set defaults before repair/replication so dependency init cannot randomize
    -- these empty slots when a buyer loads the delivered vehicle.
    if #changes>0 then
        local md=vehicle:getModData()
        for _,change in ipairs(changes)do md['defaultPartSet_'..change.part:getId()]='true' end
    end
    return changes
end
function D.apply(vehicle,changes)
    for _,change in ipairs(changes)do
        local part=change.part
        part:setInventoryItem(change.item)
        if change.item then part:repair()end
        local sp=part:getScriptPart()
        for j=0,sp:getModelCount()-1 do
            local model=sp:getModel(j):getId()
            part:setModelVisible(model,not change.empty and model==change.model)
        end
        if change.empty and part:getInventoryItem()~=nil then error('Accessory removal failed: '..part:getId(),0)end
        if change.item and part:getInventoryItem():getFullType()~=change.item:getFullType() then error('Stock part replacement failed: '..part:getId(),0)end
        if isServer()then vehicle:transmitPartItem(part);vehicle:transmitPartCondition(part)end
    end
    if #changes>0 then
        vehicle:updatePartStats();vehicle:doDamageOverlay()
        vehicle:getModData().TSBAstroluxVendStockVersion=Stock.version
        vehicle:transmitModData()
        print('[AstroluxStock] vehicle='..tostring(vehicle:getId())..' script='..vehicle:getScript():getFullName()..' stockChanges='..#changes)
    end
end
return D
