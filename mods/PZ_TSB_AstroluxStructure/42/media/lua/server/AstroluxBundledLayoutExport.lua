-- Private authoring helper. Reads the approved room; never changes world state.
if isClient() or isServer() then return end
local ticks,done,last=0,false,nil
local function report(message)
    if message~=last then print('[Astrolux layout export] '..message);last=message end
end
local function capture()
    if not getWorld() or getWorld():getWorld()~='AstroluxTestWorld_80x80_20261028' then
        report('Waiting for the approved bundled test world.');return
    end
    local selected=ModData.get('TSBAstroluxCombined12.v1')
    local chosen
    for _,r in ipairs(require('TSBAstroluxStructure/Records').all()) do
        if selected and r.id==selected.recordId and r.status=='ready' and r.combinedSize==12 then chosen=r;break end
    end
    if not chosen then report('Waiting for the selected ready bundled showroom.');return end
    local cell=getCell()
    local profile={version=2,width=12,height=12,name='Approved Astrolux furniture layout',layoutOnly=true,objects={}}
    for dx=0,12 do for dy=0,12 do
        local sq=cell:getGridSquare(chosen.x+dx,chosen.y+dy,0)
        if not sq then report('Waiting for all showroom tiles to load; approach the tower.');return end
        local objects=sq:getObjects()
        for i=0,objects:size()-1 do
            local obj=objects:get(i)
            local sprite=obj:getSprite()
            local props=sprite and sprite:getProperties()
            local md=obj:getModData()
            if obj~=sq:getFloor() and not md.TSBAstroluxStructure and props and props:has('IsMoveAble') then
                local e={dx=dx,dy=dy,z=0,order=i,sprite=sprite:getName(),objectType=obj:getObjectName(),renderYOffset=obj:getRenderYOffset()}
                if props:has('Facing') then e.facing=props:get('Facing') end
                if instanceof(obj,'IsoMannequin') then e.mannequinDirection=tostring(obj:getDir()) end
                if md.TSBAstroluxKiosk or md.TSBAstroluxVend then e.service='freshAstroluxKiosk' end
                if md.movableData and md.movableData.TSBAstroluxCoffeeSuppliesV1 then e.coffeeSupplies=true end
                profile.objects[#profile.objects+1]=e
            end
        end
    end end
    if #profile.objects==0 then report('No furniture found; previous template retained.');return end
    -- Layout approval does not authorize exporting private container contents.
    -- Keep this separate from the full inventory survey used by other tools.
    local writer=require('TSBAstroluxStructure/DecorCapture')
    local previous=writer.filename
    writer.filename='AstroluxApprovedBundledLayout_20261028.txt'
    local ok,result,why=pcall(writer.write,profile)
    writer.filename=previous
    if not ok or not result then error(tostring(why or result)) end
    done=true
    report('Captured approved layout: '..#profile.objects..' objects; private inventories excluded. No world objects changed.')
end
Events.OnTick.Add(function()
    if done then return end
    ticks=ticks+1
    if ticks%120~=0 then return end
    local ok,why=pcall(capture)
    if not ok then report('Capture failed; previous template retained: '..tostring(why)) end
end)
