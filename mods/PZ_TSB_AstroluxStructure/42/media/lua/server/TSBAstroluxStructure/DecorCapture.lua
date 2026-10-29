-- Explicit manual showroom survey with container snapshots; service identities stay fresh.
local Inventory=require 'TSBAstroluxStructure/InventorySnapshot'
local D={filename='TSBAstroluxShowroomDefault.txt'}
TSBAstroluxDecorCapture=D
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
    local size=record.combinedSize or 8
    local profile={version=2,inventoryIncluded=true,name='Astrolux Motors showroom',width=size,height=size,objects={}}
    for dx=0,size do for dy=0,size do
        local sq=cell:getGridSquare(record.x+dx,record.y+dy,0)
        if not sq then return nil,'Showroom tiles are not all loaded.' end
        local list=sq:getObjects()
        for i=0,list:size()-1 do
            local obj=list:get(i);local md=obj:getModData();local sprite=obj:getSprite()
            local props=sprite and sprite:getProperties();local name=sprite and sprite:getName()
            if obj~=sq:getFloor() and not md.TSBAstroluxStructure and props and props:has('IsMoveAble') then
                local entry={dx=dx,dy=dy,z=0,order=i,sprite=name,objectType=obj:getObjectName(),renderYOffset=obj:getRenderYOffset()}
                if props:has('Facing') then entry.facing=props:get('Facing') end
                if md.TSBAstroluxKiosk or md.TSBAstroluxVend then entry.service='freshAstroluxKiosk' end
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
function D.write(profile)
    local writer=getFileWriter(D.filename,true,false)
    if not writer then return nil,'Could not open decoration export.' end
    writer:write('-- Astrolux default decoration layout. Positions relative to showroom origin.\nreturn '..encode(profile)..'\n')
    writer:close();return true
end
function D.capture(selectedRecord)
    if isClient() or isServer() or not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return nil,'Capture is restricted to the Astrolux single-player lab.' end
    local p=getSpecificPlayer(0)
    local record=selectedRecord or p and require('TSBAstroluxStructure/Records').near(p:getX(),p:getY()) or ModData.getOrCreate('TSBAstroluxStructure.Lab.v1').tower
    if not record or record.status~='ready' then return nil,'No ready showroom record is available.' end
    local defaults=ModData.getOrCreate('TSBAstroluxStructure.DecorDefaults.v1')
    local surveyed,profile,why=pcall(D.survey,record,getCell())
    if not surveyed then return nil,tostring(profile)end
    if not profile then return nil,why end
    local ok,reason=D.write(profile);if not ok then return nil,reason end
    defaults.profile=profile;defaults.sourceTower=record.id
    -- Adopt newly placed decor for helper collision; never rebuild the room.
    for index,entry in ipairs(profile.objects)do
        local sq=getCell():getGridSquare(record.x+entry.dx,record.y+entry.dy,0)
        local obj=sq and sq:getObjects():get(entry.order)
        if obj and obj:getSprite() and obj:getSprite():getName()==entry.sprite then
            local md=obj:getModData();md.movableData=md.movableData or {}
            md.movableData.TSBAstroluxFurnishingV1={tower=record.id,index=index}
            obj:transmitModData()
        end
    end
    print('[Astrolux decorations] Recorded '..#profile.objects..' objects as default: '..D.filename)
    return profile
end
return D
