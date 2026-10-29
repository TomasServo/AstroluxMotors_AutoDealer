if isClient() then return end
local R={delay=600,key='TSBAstroluxCoffeeSuppliesV1'}
R.targets={['Base.Coffee2']=2,['Base.MugWhite']=4,['Base.SugarPacket']=4,['Base.Spoon']=4,
    ['Base.SimpleSyrup']=1,['Base.DishCloth']=1,['Base.Milk']=1}
local function state(obj,create)
    local md=obj:getModData()
    if create then md.movableData=md.movableData or {};md.movableData[R.key]=md.movableData[R.key] or {pending={}} end
    return md.movableData and md.movableData[R.key]
end
function R.corner(obj)
    local sprite=obj:getSprite();local props=sprite and sprite:getProperties()
    if not props or not obj:getContainer() then return false end
    local label=(tostring(props:get('GroupName') or '')..' '..tostring(props:get('CustomName') or '')):lower()
    return label:find('corner',1,true) and (label:find('counter',1,true) or label:find('cabinet',1,true)) and true or false
end
function R.mark(obj)
    if not obj:getContainer() then return nil,'Choose a cabinet with storage.' end
    local s=state(obj,true);local targets={};local items=obj:getContainer():getItems()
    for i=0,items:size()-1 do local ft=items:get(i):getFullType();targets[ft]=(targets[ft] or 0)+1 end
    s.targets=targets;s.pending={};s.initialized=true;s.nextRefill=getTimestamp()+R.delay
    obj:transmitModData();return true
end
function R.update(obj,now)
    local s=state(obj);local container=obj:getContainer()
    if not s or not container then return end
    local counts={};local items=container:getItems()
    for i=0,items:size()-1 do local ft=items:get(i):getFullType();counts[ft]=(counts[ft] or 0)+1 end
    if s.targets then
        if not s.nextRefill then s.nextRefill=now+R.delay end
        if now<s.nextRefill then return end
        for ft,target in pairs(s.targets)do
            for n=1,math.max(0,target-(counts[ft] or 0))do
                local item=instanceItem(ft)
                if not item or not container:hasRoomFor(nil,item)then break end
                container:AddItem(item)
                if not container:getItems():contains(item)then break end
                if isServer()then sendAddItemToContainer(container,item)end
            end
        end
        s.nextRefill=now+R.delay;obj:transmitModData();return
    end
    local changed=false;s.pending=s.pending or {}
    for ft,target in pairs(R.targets) do
        local missing=math.max(0,target-(counts[ft] or 0));local q=s.pending[ft] or {};s.pending[ft]=q
        -- Returned supplies satisfy the oldest missing units first.
        while #q>missing do table.remove(q,1);changed=true end
        while #q<missing do q[#q+1]=now+(s.initialized and R.delay or 0);changed=true end
        while q[1] and q[1]<=now do
            local item=instanceItem(ft)
            if not item or not container:hasRoomFor(nil,item) then break end
            container:AddItem(item)
            if not container:getItems():contains(item) then break end
            table.remove(q,1);changed=true
            if isServer() then sendAddItemToContainer(container,item) end
        end
    end
    if not s.initialized then s.initialized=true;changed=true end
    if changed then obj:transmitModData() end
end
local function emptyTargets(targets)
    for _ in pairs(targets) do return false end
    return true
end
local last=0
function R.tick()
    local now=getTimestamp();if now-last<1 then return end;last=now
    for _,record in ipairs(require('TSBAstroluxStructure/Records').all())do
    if record.status=='ready' and record.coffeeRestockEnabled~=false and now>=(record.coffeeRestockResumeAt or 0) then
    local marked,corners={},{};local complete=true
    local size=record.combinedSize or 8
    for dx=0,size do for dy=0,size do
        local sq=getCell():getGridSquare(record.x+dx,record.y+dy,0)
        if not sq then complete=false else
            local list=sq:getObjects()
            for i=0,list:size()-1 do local obj=list:get(i)
                if state(obj) then marked[#marked+1]=obj elseif R.corner(obj) then corners[#corners+1]=obj end
            end
        end
    end end
    if #marked==0 and complete and #corners==1 then R.mark(corners[1]);marked[1]=corners[1] end
    for _,obj in ipairs(marked) do
        local stock=state(obj)
        -- Repair the empty default target captured in the optional test map.
        -- Preserve custom targets and any player-stored contents.
        if require('AstroluxBayTest/TestWorld').testMap() and not stock.defaultStockReviewed then
            if stock.targets and emptyTargets(stock.targets) and obj:getContainer():getItems():size()==0 then
                stock.targets=nil;stock.initialized=nil;stock.pending={}
            end
            stock.defaultStockReviewed=true;obj:transmitModData()
        end
        if record.combinedSize==12 and not stock.targets then
            -- Fresh designated cabinets receive defaults before taking a refill snapshot.
            if not stock.initialized then R.update(obj,now) end
            R.mark(obj)
        end
        R.update(obj,now)
    end
    end end
end
function R.designate(p,args)
    local record=type(args.x)=='number' and type(args.y)=='number' and require('TSBAstroluxStructure/Records').near(args.x,args.y)
    if not record or type(args.x)~='number' or type(args.y)~='number' or type(args.index)~='number'
        or args.x~=math.floor(args.x) or args.y~=math.floor(args.y) or args.index~=math.floor(args.index)
        or p:getZ()~=0 or (p:getX()-args.x)^2+(p:getY()-args.y)^2>9
        or args.x<record.x or args.x>record.x+(record.combinedSize or 8) or args.y<record.y or args.y>record.y+(record.combinedSize or 8) then
        return nil,'Choose the corner cabinet inside the showroom and stand within three tiles.'
    end
    local sq=getCell():getGridSquare(args.x,args.y,0);local list=sq and sq:getObjects()
    local obj=list and args.index>=0 and args.index<list:size() and list:get(args.index)
    if not obj or not R.corner(obj) then return nil,'Select a corner cabinet again.' end
    local ok,why=R.mark(obj);if ok then R.update(obj,getTimestamp()) end;return ok,why
end
Events.OnTick.Add(R.tick)
return R
