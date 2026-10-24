-- Explicit manual showroom survey with container snapshots; service identities stay fresh.
local Inventory=require 'TSBAstroluxStructure/InventorySnapshot'
local D={filename='TSBAstroluxShowroomDefault.txt'}

local function encode(value)
    if type(value)=='string' then return string.format('%q',value) end
    if type(value)=='number' or type(value)=='boolean' then return tostring(value) end
    local out={'{'}
    local keys={};for key in pairs(value) do keys[#keys+1]=key end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    for _,key in ipairs(keys) do out[#out+1]='['..encode(key)..']='..encode(value[key])..',' end
    out[#out+1]='}';return table.concat(out)
end
function D.survey(record,cell)
    local profile={version=2,inventoryIncluded=true,name='Astrolux Motors showroom',width=11,height=11,objects={}}
    for dx=0,11 do for dy=0,11 do
        local sq=cell:getGridSquare(record.x+dx,record.y+dy,0)
        if not sq then return nil,'Showroom tiles are not all loaded.' end
        local list=sq:getObjects()
        for i=0,list:size()-1 do
            local obj=list:get(i);local md=obj:getModData();local sprite=obj:getSprite()
            local props=sprite and sprite:getProperties();local name=sprite and sprite:getName()
            if obj~=sq:getFloor() and not md.TSBAstroluxStructure and props and props:has('IsMoveAble') then
                local entry={dx=dx,dy=dy,z=0,order=i,sprite=name,objectType=obj:getObjectName(),renderYOffset=obj:getRenderYOffset()}
                if props:has('Facing') then entry.facing=props:get('Facing') end
                if md.TSBAstroluxKiosk then entry.service='freshAstroluxKiosk' end
                if md.movableData and md.movableData.TSBAstroluxCoffeeSuppliesV1 then entry.coffeeSupplies=true end
                local children=obj:getChildSprites()
                if children and children:size()>0 then
                    entry.attached={}
                    for j=0,children:size()-1 do entry.attached[#entry.attached+1]=children:get(j):getParentSprite():getName() end
                end
                entry.inventory=Inventory.captureObject(obj)
                profile.objects[#profile.objects+1]=entry
            end
        end
    end end
    if #profile.objects==0 then return nil,'No showroom decorations found; default not replaced.' end
    return profile
end
return D
