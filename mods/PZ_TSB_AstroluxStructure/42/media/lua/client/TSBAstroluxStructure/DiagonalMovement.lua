-- Single-player movement alignment with the visual diagonal glass.
-- Native windows, collision flags, furniture and saves remain intact.
if isClient() or isServer() then return end
local G=require 'TSBAstroluxStructure/DiagonalGeometry'
local Sites=require 'TSBAstroluxStructure/ReleaseSites'
local M={enabled=true}
local previous,seenSite,failed=nil,nil,false
local hits=0
local function log(text) print('[Astrolux diagonal movement] '..text) end

local function singlePlayer()
    if isClient() or isServer() then return false end
    for index=1,3 do if getSpecificPlayer(index) then return false end end
    return true
end

-- Require all six original, intact native window edges for this corner.
-- A missing, open, smashed, foreign or unloaded edge disables only that corner.
function M.cornerActive(r,c)
    for _,edge in ipairs(c.windows) do
        local sq=getCell():getGridSquare(r.x+edge.tx,r.y+edge.ty,0)
        if not sq then return false end
        local objects=sq:getObjects();local found=0
        for i=0,objects:size()-1 do
            local o=objects:get(i)
            if instanceof(o,'IsoWindow') and o:getNorth()==edge.north then
                local md=o:getModData();local marker=md.TSBAstroluxCornerCollisionV1
                if md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='window'
                    and marker and marker.owner==r.id and marker.x==edge.x and marker.y==edge.y
                    and o:getObjectIndex()>=0 and o:getSquare()==sq then
                    if o:IsOpen() or o:isSmashed() or o:isDestroyed() then return false end
                    found=found+1
                end
            end
        end
        if found~=1 then return false end
    end
    return true
end

function M.setEnabled(value)
    M.enabled=value==true;previous=nil;failed=false;hits=0;seenSite=nil
    log(M.enabled and 'ON; walk inward before comparing if already beyond the pane.' or 'OFF; original native collision only.')
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
    local key=tostring(r.id)..':'..r.x..':'..r.y
    if seenSite~=key then
        seenSite=key
        local states={}
        for i,c in ipairs(G.corners) do states[i]=c.name..'='..tostring(M.cornerActive(r,c)) end
        log('Ready tower '..key..' '..table.concat(states,' ')..' radius='..p:getWidth())
    end
    if previous and previous.player==p and previous.key==key then
        local radius=math.max(0.1,math.min(0.3,p:getWidth()))
        local active={}
        -- Check current object state at each potential contact, never cached.
        for i,c in ipairs(G.corners) do
            local d=G.distance(c,x-r.x,y-r.y)
            active[i]=d<radius and d> -G.maxStep and M.cornerActive(r,c) or false
        end
        local cx,cy,corner=G.clip(previous.x-r.x,previous.y-r.y,x-r.x,y-r.y,radius,active)
        if corner then
            cx,cy=cx+r.x,cy+r.y
            -- Never move into an unloaded square or change Z/animation/actions.
            if getCell():getGridSquare(math.floor(cx),math.floor(cy),0) then
                p:setX(cx);p:setY(cy) -- Native setters also update nextX/nextY.
                p:setCurrentSquareFromPosition();p:setMovingSquareNow()
                x,y=p:getX(),p:getY()
                hits=hits+1
                if hits<=8 or hits%300==0 then
                    log(string.format('CONTACT %s x=%.4f y=%.4f count=%d',G.corners[corner].name,x-r.x,y-r.y,hits))
                end
            end
        end
    end
    previous={player=p,key=key,x=x,y=y}
end

function M.onTick()
    if failed then return end
    local ok,err=pcall(update)
    if not ok then
        M.enabled=false;failed=true;previous=nil
        log('DISABLED after error; native collision remains: '..tostring(err))
    end
end
Events.OnTick.Add(M.onTick) -- Official 42.21 runs this after IsoWorld.update.
Events.OnGameStart.Add(function()
    M.setEnabled(true)
    log('Visual glass collision alignment enabled for single-player.')
end)
Events.OnDisconnect.Add(function() previous=nil;seenSite=nil;failed=false end)
return M
