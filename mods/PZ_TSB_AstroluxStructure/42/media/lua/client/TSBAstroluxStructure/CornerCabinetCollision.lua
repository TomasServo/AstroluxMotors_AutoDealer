-- Single-player corner-cabinet collision; retain inventory/sink access and art.
-- Normal movement bypasses solidtrans near windows in official Build 42.21.
if isClient() or isServer() then return end
local G=require 'TSBAstroluxStructure/CabinetGeometry'
local Sites=require 'TSBAstroluxStructure/ReleaseSites'
local M={enabled=true}
local previous,failed=nil,false
local hits,logged=0,nil
local function log(s) print('[Astrolux corner cabinet] '..s) end
local function singlePlayer()
    if isClient() or isServer() then return false end
    for i=1,3 do if getSpecificPlayer(i) then return false end end
    return true
end
function M.target(r)
    -- Only this existing cabinet in its approved spot. A moved, picked-up,
    -- destroyed, replaced or foreign cabinet must leave no invisible obstacle.
    local sq=getCell():getGridSquare(r.x,r.y+8,0)
    if not sq then return nil end
    local objects=sq:getObjects();local found=nil
    for i=0,objects:size()-1 do
        local o=objects:get(i);local sp=o:getSprite()
        if sp and sp:getName()=='fixtures_counters_01_58' and instanceof(o,'IsoThumpable') then
            local md=o:getModData();local own=md.movableData and md.movableData.TSBAstroluxFurnishingV1
            if own and own.tower==r.id and o:getSquare()==sq and o:getObjectIndex()>=0
                and not o:isDestroyed() and o:isBlockAllTheSquare() and not o:isCanPassThrough() then
                if found then return nil end
                found=o
            end
        end
    end
    return found
end
function M.setEnabled(value)
    M.enabled=value==true;previous=nil;failed=false;hits=0;logged=nil
    log(M.enabled and 'ON; only the owned corner counter at (0,8). Step out first if overlapping.' or 'OFF; native cabinet collision only.')
end
function M.toggle() M.setEnabled(not M.enabled) end
local function update()
    if not M.enabled or not singlePlayer() then previous=nil;return end
    local p=getSpecificPlayer(0)
    if not p or p:isDead() or p:isNoClip() or p:getZ()~=0 or p:getVehicle()
        or p:isClimbing() or p:isFalling() or p:isbFalling() or p:isSittingOnFurniture()
        or p:isRagdollFall() then previous=nil;return end
    local r=Sites.near(p)
    if not r or not r.releaseTower or r.status~='ready' then previous=nil;return end
    local x,y=p:getX(),p:getY()
    if x<r.x-2 or x>r.x+3 or y<r.y+6 or y>r.y+11 then previous=nil;return end
    local target=M.target(r)
    if not target then previous=nil;return end
    local key=tostring(r.id)..':'..r.x..':'..r.y
    if logged~=target then
        logged=target;log('Verified Dark Corner cabinet; inventory and sink properties untouched.')
    end
    if previous and previous.player==p and previous.key==key and previous.target==target then
        local radius=math.max(0.1,math.min(0.3,p:getWidth()))
        local cx,cy,hit=G.clip(previous.x-r.x,previous.y-r.y,x-r.x,y-r.y,radius)
        if hit then
            cx,cy=cx+r.x,cy+r.y
            if getCell():getGridSquare(math.floor(cx),math.floor(cy),0) then
                p:setX(cx);p:setY(cy)
                p:setCurrentSquareFromPosition();p:setMovingSquareNow()
                x,y=p:getX(),p:getY();hits=hits+1
                if hits<=4 or hits%300==0 then
                    log(string.format('CONTACT x=%.4f y=%.4f count=%d',x-r.x,y-r.y,hits))
                end
            end
        end
    end
    previous={player=p,key=key,target=target,x=x,y=y}
end
function M.onTick()
    if failed then return end
    local ok,why=pcall(update)
    if not ok then
        M.enabled=false;failed=true;previous=nil
        log('DISABLED after error; native cabinet unchanged: '..tostring(why))
    end
end
Events.OnTick.Add(M.onTick)
Events.OnGameStart.Add(function()M.setEnabled(true)end)
Events.OnDisconnect.Add(function()previous=nil;logged=nil;failed=false end)
return M
