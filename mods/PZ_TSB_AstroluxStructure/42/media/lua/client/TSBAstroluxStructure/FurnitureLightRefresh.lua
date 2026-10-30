-- Refresh derived caches after fixing helper tile metadata.
-- No sprites, objects, collision flags, inventories or furniture are replaced.
if isClient() or isServer() then return end
local Sites=require 'TSBAstroluxStructure/ReleaseSites'
local M={}
local seen=setmetatable({},{__mode='k'})
local ticks,refreshed,reports=0,0,0
local failed=false
local definitions={
    TSBAstroluxBayCollision_0={IsoFlagType.collideN,IsoFlagType.transparentN},
    TSBAstroluxBayCollision_1={IsoFlagType.collideW,IsoFlagType.transparentW},
}
function M.refresh(sq)
    if not sq or sq:getZ()~=0 then return false end
    local pending={};local objects=sq:getObjects()
    for i=0,objects:size()-1 do
        local o=objects:get(i);local h=o:getModData().TSBAstroluxNativeHelperV1
        local sp=o:getSprite();local flags=sp and definitions[sp:getName()]
        if h and h.owner and h.kind=='furnitureEdge' and flags and not seen[o] then
            local props=sp:getProperties()
            assert(props:has(flags[1]) and props:has(flags[2]),
                'Expected collision + directional transparency; fully restart the test client.')
            pending[#pending+1]=o
        end
    end
    if #pending==0 then return false end
    -- RecalcProperties schedules native chunk lighting/physics checks.
    -- RecalcAllWithNeighbours refreshes both directions of the vision matrix.
    sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
    sq:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)
    for _,o in ipairs(pending) do seen[o]=true end
    refreshed=refreshed+#pending
    return true
end
local function safeRefresh(sq)
    if failed then return end
    local ok,why=pcall(M.refresh,sq)
    if not ok then failed=true;print('[Astrolux furniture light] Refresh stopped: '..tostring(why)) end
end
local function scan()
    local p=getSpecificPlayer(0);if not p or not getCell() then return end
    for _,r in ipairs(Sites.all()) do
        if r.status=='ready' and (p:getX()-r.x)^2+(p:getY()-r.y)^2<3600 then
            for x=0,13 do for y=0,13 do safeRefresh(getCell():getGridSquare(r.x+x,r.y+y,0)) end end
        end
    end
    if refreshed~=reports then
        reports=refreshed
        print('[Astrolux furniture light] Refreshed '..refreshed..' owned edges; collision retained, directional sight/light enabled.')
    end
end
Events.LoadGridsquare.Add(safeRefresh)
Events.OnGameStart.Add(scan)
Events.OnTick.Add(function() ticks=ticks+1;if ticks%120==0 and not failed then scan() end end)
return M
