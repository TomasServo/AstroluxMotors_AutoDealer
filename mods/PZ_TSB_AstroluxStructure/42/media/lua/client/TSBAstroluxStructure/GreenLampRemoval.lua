-- Remove the retired original green lamp once per single-player release tower.
-- The table and every other furnishing retain their native objects and state.
if isClient() or isServer() then return end
local Sites=require 'TSBAstroluxStructure/ReleaseSites'
local M={}
local marker='testGreenLampRemoved20261030'
function M.apply(r)
    if not r or not r.releaseTower or r.status~='ready' or r[marker] then return false end
    local cell=getCell();local sq=cell and cell:getGridSquare(r.x+9,r.y+9,0)
    if not sq then return false end
    local target=nil;local objects=sq:getObjects()
    for i=0,objects:size()-1 do
        local o=objects:get(i);local sp=o:getSprite()
        if instanceof(o,'IsoLightSwitch') and sp and sp:getName()=='lighting_indoor_02_33' then
            local md=o:getModData();local own=md.movableData and md.movableData.TSBAstroluxFurnishingV1
            if own and own.tower==r.id and o:getObjectIndex()>=0 then
                assert(not target,'More than one owned green lamp; removal stopped.')
                target=o
            end
        end
    end
    if target then
        target:setActive(false,false,true)
        -- false prevents native grouped/tabletop removal from taking the table.
        sq:transmitRemoveItemFromSquare(target,false)
        assert(target:getObjectIndex()<0,'Green lamp removal not confirmed.')
        sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
        print('[Astrolux lamp removal] Removed original green lamp; table retained: '..tostring(r.id))
    end
    r[marker]=true
    return target~=nil
end
local failed=false
function M.update()
    if failed or not getCell() then return end
    local ok,why=pcall(function()for _,r in ipairs(Sites.all())do M.apply(r)end end)
    if not ok then failed=true;print('[Astrolux lamp removal] Stopped: '..tostring(why))end
end
Events.OnGameStart.Add(M.update)
Events.EveryOneMinute.Add(M.update)
return M
