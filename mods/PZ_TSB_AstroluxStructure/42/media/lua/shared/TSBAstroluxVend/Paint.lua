local Amount=require 'TSBAstroluxVend/Amount'
-- Existing vehicle artwork only. No source definitions or Workshop assets modified.
local C=require 'TSBAstroluxVend/Config'
local P={}
local native={['Base.SmallCar']=true,['Base.CarNormal']=true,['Base.PickUpVan']=true,['Base.OffRoad']=true}
-- Fixed values inside the native debug tool's Red/Blue/White/Black ranges.
local presets={{'red','Red',0.01,0.92,0.70},{'blue','Blue',0.58,0.92,0.70},
    {'white','White',0.15,0.05,0.75},{'black','Black',0.50,0.05,0.18}}
local solid={beige=true,black=true,brown=true,darkblue=true,darkgreen=true,
    forestgreen=true,darkgray=true,darkgrey=true,lightblue=true,red=true,
    silver=true,superwhite=true,white=true,offwhite=true,blue=true,green=true,
    gray=true,grey=true,yellow=true,orange=true,purple=true,pink=true,
    lightgreen=true,lightgray=true,lightgrey=true,cream=true,tan=true,maroon=true,
    burgundy=true,navy=true,olive=true}
local function amount(n)
    return Amount.valid(n,1)
end
local skinTextures=setmetatable({},{__mode='k'})
local function skin(script,index)
    local cached=skinTextures[script]
    if cached then return cached[index] end
    local declared=script:getSkin(index)
    if not declared then return nil end
    -- Plain Lua script adapters may supply table descriptors. Native Skin is
    -- Java userdata with no exposed texture accessor; never index its fields.
    if type(declared)=='table' then
        return declared.texture and tostring(declared.texture) or nil
    end
    -- BaseVehicle.getSkin() is the native public texture-name accessor.
    -- Use a detached descriptor only: never add it to a square, world, physics,
    -- vehicle manager or inventory, and never transmit a skin change.
    local probe=BaseVehicle.new(getCell())
    probe:setScript(script:getFullName())
    if probe:getScript()~=script then error('Vehicle paint script is unavailable.',0) end
    cached={}
    for i=0,script:getSkinCount()-1 do
        probe:setSkinIndex(i)
        cached[i]=probe:getSkin()
    end
    skinTextures[script]=cached
    return cached[index]
end
local function fingerprint(o)
    return table.concat({o.id,o.script or '',o.texture or '',o.skin or -1,o.h or '',o.s or '',o.v or '',o.surcharge},'|')
end
function P.options(script,settings,variants)
    local result={}
    local function add(o)
        local price=((((settings or {}).paintPrices or {})[script:getFullName()] or {})[o.id])
        if price~=nil then o.surcharge=Amount.check(price,0)end
        o.key=fingerprint(o);result[#result+1]=o end
    local name=script:getFullName()
    local count=script.getSkinCount and script:getSkinCount() or 0
    if count<0 or count>128 then error('Unsupported vehicle skin count.',0)end
    local default=(settings or {}).specialPaint or C.specialPaintPrice or 500
    if not amount(default) then error('Invalid server paint surcharge.',0)end
    if native[name] and count==1 then
        local texture=skin(script,0)
        if not texture then error('Vehicle skin is unavailable.',0)end
        add({id='factory',label='Factory Color',skin=0,texture=texture,surcharge=0})
        for _,p in ipairs(presets)do
            add({id=p[1],label=p[2],skin=0,texture=texture,h=p[3],s=p[4],v=p[5],surcharge=0})
        end
    elseif count>0 then
        local defaults={}
        for i=0,count-1 do
            local texture=skin(script,i)
            if not texture or #texture>300 then error('Vehicle skin is unavailable.',0)end
            local suffix=texture:match('_([^_]+)$') or ''
            local ordinary=solid[suffix:lower()] or false
            -- Single-skin vehicles retain their supplied factory design for free.
            -- Unrecognized alternatives are special until the server classifies them.
            if count==1 then ordinary=true end
            local profile=((C.paintJobs or {})[name] or {})[texture] or {}
            if profile.special~=nil then ordinary=not profile.special end
            local extra=ordinary and 0 or (profile.surcharge or default)
            if not ordinary and not amount(extra) then error('Special paint must cost extra.',0)end
            local label=profile.label or suffix
            if label=='' then label='Design '..(i+1)end
            label=label:gsub('(%l)(%u)','%1 %2'):gsub('_',' ')
            local o={id='skin:'..i..':'..texture,label=label,skin=i,texture=texture,
                surcharge=extra,special=not ordinary}
            defaults[#defaults+1]=o
        end
        -- Free solid colors first, keeping native indices intact.
        for _,o in ipairs(defaults)do if not o.special then add(o)end end
        for _,o in ipairs(defaults)do if o.special then add(o)end end
    else
        add({id='factory',label='Factory appearance',surcharge=0})
    end
    for _,variant in ipairs(variants or {})do
        local source=getScriptManager():getVehicle(variant.script)
        local Families=require 'TSBAstroluxVend/VehicleFamilies'
        local policy=Families.policy(settings,script:getFullName(),variant.script)
        if source and policy.enabled then
         local choices=P.options(source,settings)
         for _,paint in ipairs(choices)do
            local copy={};for k,v in pairs(paint)do copy[k]=v end
            copy.script=variant.script;copy.id='variant:'..variant.script..':'..paint.id
            copy.label=variant.label..(#choices>1 and (' - '..paint.label) or '')
            copy.surcharge=Amount.add(policy.price,paint.surcharge);copy.special=true
            add(copy)
        end end
    end
    return result
end
function P.select(script,settings,id,variants)
    if id~=nil and (type(id)~='string' or #id>750)then error('Invalid paint selection.',0)end
    local choices=P.options(script,settings,variants)
    for i,o in ipairs(choices)do if id==o.id or (id==nil and i==1)then return o end end
    error('Paint selection changed or is unavailable. Refresh the terminal.',0)
end
function P.attach(offer,paint)
    local total=Amount.add(offer.price,paint.surcharge)
    local result={};for k,v in pairs(offer)do result[k]=v end
    result.price=total
    result.paint=paint;result.paintKey=paint.key
    return result
end
function P.offer(offer,script,settings,id,variants)
    return P.attach(offer,P.select(script,settings,id,variants))
end
function P.verify(paint,script)
    if not paint then return end -- Existing orders predate paint selection.
    if not script then error('Paint vehicle script is unavailable.',0)end
    if paint.script and paint.script~=script:getFullName()then error('Paid paint requires its original native vehicle configuration.',0)end
    if paint.skin~=nil and (paint.skin<0 or paint.skin>=script:getSkinCount()
        or skin(script,paint.skin)~=paint.texture)then
        error('Paid vehicle skin changed. Administrator inspection required.',0)
    end
end
function P.apply(vehicle,paint)
    if not paint then return end
    P.verify(paint,vehicle:getScript())
    if paint.skin~=nil then
        vehicle:setSkinIndex(paint.skin)
        vehicle:transmitSkinIndex()
        if vehicle:getSkinIndex()~=paint.skin then error('Vehicle skin was not applied.',0)end
    end
    if paint.h~=nil then
        vehicle:setColorHSV(paint.h,paint.s,paint.v)
        vehicle:transmitColorHSV()
        if math.abs(vehicle:getColorHue()-paint.h)>0.0001
            or math.abs(vehicle:getColorSaturation()-paint.s)>0.0001
            or math.abs(vehicle:getColorValue()-paint.v)>0.0001 then
            error('Vehicle color was not applied.',0)
        end
    end
end
return P
