-- One-time read-only showroom survey. Never copies contents or service identities.
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
    local profile={version=1,name='Astrolux Motors showroom',width=8,height=8,objects={}}
    for dx=0,8 do for dy=0,8 do
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
function D.capture()
    if isClient() or isServer() or not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return nil,'Capture is restricted to the Astrolux single-player lab.' end
    local lab=ModData.getOrCreate('TSBAstroluxStructure.Lab.v1');local record=lab.tower
    if not record or record.status~='ready' then return nil,'No ready showroom record is available.' end
    local defaults=ModData.getOrCreate('TSBAstroluxStructure.DecorDefaults.v1')
    local profile,why=defaults.profile,nil
    if not profile then profile,why=D.survey(record,getCell()) end
    if not profile then return nil,why end
    defaults.profile=profile;defaults.sourceTower=record.id
    local ok,reason=D.write(profile);if not ok then return nil,reason end
    print('[Astrolux decorations] Recorded '..#profile.objects..' objects as default: '..D.filename)
    return profile
end
local started,done,last=nil,false,0
if Events and Events.OnGameStart then Events.OnGameStart.Add(function()started=getTimestampMs()end) end
if Events and Events.OnTick then Events.OnTick.Add(function()
    if done or isClient() or isServer() then return end
    if not started then started=getTimestampMs() end
    if not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then done=true;return end
    local now=getTimestampMs();if now-started<5000 or now-last<2000 then return end;last=now
    local lab=ModData.getOrCreate('TSBAstroluxStructure.Lab.v1');local record=lab.tower
    if not record or record.status~='ready' then return end
    local profile,why=D.capture()
    if not profile then
        if D.lastReason~=why then print('[Astrolux decorations] Waiting: '..tostring(why));D.lastReason=why end
        return
    end
    done=true
    local p=getSpecificPlayer(0);if p then p:Say('Astrolux showroom decorations recorded as the default layout.')end
end) end
return D
