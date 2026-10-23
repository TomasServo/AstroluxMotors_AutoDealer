local Stock=require 'TSBAstroluxVend/Stock'
local StockDelivery=require 'TSBAstroluxVend/StockDelivery'
local D={}
function D.restore(vehicle,camperTop,equipment)
    -- Use the native repair path: restores missing standard parts, condition,
    -- engine quality, drainable charge, fluid/air containers, rust and blood.
    local changes=StockDelivery.prepare(vehicle,camperTop,equipment)
    vehicle:repair()
    StockDelivery.apply(vehicle,changes)
    for i=0,vehicle:getPartCount()-1 do
        local part=vehicle:getPartByIndex(i)
        if part:getCondition()~=100 then error('Vehicle part failed full restoration: '..part:getId(),0)end
        -- Hilux HLX88Trunk template deliberately uses a hidden nil-item TruckBed;
        -- the real cargo equipment is HLX88Trunk and still requires restoration.
        local blankHiluxBed=Stock.blank(vehicle:getScript():getFullName(),part:getId())
            and part:getId()=='TruckBed' and vehicle:getPartById('HLX88Trunk')~=nil
        local optional=Stock.optional(part:getId())
        if part:isInventoryItemUninstalled() and not blankHiluxBed and not optional then error('Vehicle part is missing after restoration: '..part:getId(),0)end
        local item=part:getInventoryItem()
        if item and instanceof(item,'Drainable') and item:getCurrentUsesFloat()<0.9999 then
            error('Vehicle charge is not full: '..part:getId(),0)
        end
        if not optional and part:isContainer() and not part:getItemContainer() and part:getContainerCapacity()>0 then
            if part:getContainerContentAmount()<part:getContainerCapacity()-0.001 then
                error('Vehicle fluid/air is not full: '..part:getId(),0)
            end
        end
        if part:getId()=='Engine' and vehicle:getEngineQuality()~=100 then error('Engine quality is not 100%.',0)end
    end
    if vehicle:getRust()~=0 then error('Vehicle still has rust after restoration.',0)end
end
-- Manual hotel recovery can use the refreshed implementation without restarting.
TSBAstroluxVendDeliveryRepair=D.restore
return D
