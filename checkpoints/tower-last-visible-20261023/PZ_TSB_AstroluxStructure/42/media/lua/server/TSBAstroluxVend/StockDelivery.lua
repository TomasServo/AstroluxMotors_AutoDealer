local Stock=require 'TSBAstroluxVend/Stock'
local Accessories=require 'TSBAstroluxVend/Accessories'
local Equipment=require 'TSBAstroluxVend/Equipment'
local D={}
function D.prepare(vehicle,camperTop,equipment)
    Accessories.verify(camperTop,vehicle:getScript())
    local script=vehicle:getScript():getFullName()
    local selected=Equipment.selection(equipment,vehicle:getScript(),camperTop)
    local selectedParts=Equipment.parts(vehicle:getScript(),selected)
    local changes={}
    for i=0,vehicle:getPartCount()-1 do
        local part=vehicle:getPartByIndex(i);local id=part:getId()
        local itemType,model=Stock.choice(script,id)
        if selectedParts[id] then
            local choice=selectedParts[id];local item=instanceItem(choice.item)
            if not item then error('Selected accessory unavailable: '..choice.item,0)end
            changes[#changes+1]={part=part,item=item,model=choice.model,models=choice.models}
        elseif camperTop and id==Accessories.part then
            local item=instanceItem(Accessories.item)
            if not item then error('Camper top item unavailable.',0)end
            changes[#changes+1]={part=part,item=item,model=Accessories.model}
        elseif Equipment.optional(vehicle:getScript(),id)then
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
            local visible=not change.empty and model==change.model
            for _,selected in ipairs(change.models or {})do if model==selected then visible=true end end
            part:setModelVisible(model,visible)
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
