if isClient() then return end
local S={}
function S.plan(r)
    return {{x=r.x+3,y=r.y+8,z=0,sprite='TSBAstroluxEntranceSign_0'},
        {x=r.x+8,y=r.y+3,z=0,sprite='TSBAstroluxEntranceSign_1'}}
end
function S.apply(r)
    if r.entranceSignsRevision then return true end
    if r.status~='ready' or not r.slidingDoorsRevision then return nil,'Entrances not ready.' end
    local pending={};local existing=0
    for _,sign in ipairs(S.plan(r)) do
        local sq=getCell():getGridSquare(sign.x,sign.y,0)
        if not sq then return nil,'Sign square not loaded.' end
        local found=false;local list=sq:getObjects()
        for i=0,list:size()-1 do local obj=list:get(i);local md=obj:getModData()
            if md.TSBAstroluxStructure==r.id and md.TSBAstroluxStructureKind=='entranceSign' then
                if obj:getSprite():getName()~=sign.sprite or found then return nil,'Altered sign; inspect before installation.' end
                existing=existing+1;found=true
            end
        end
        local sprite=getSprite(sign.sprite)
        if not sprite or sprite:getName()~=sign.sprite then return nil,'Sign assets unavailable.' end
        pending[#pending+1]={sq=sq,sprite=sprite}
    end
    if existing==2 then r.entranceSignsRevision=1;return true end
    if existing>0 then return nil,'Partial sign installation; inspect before retrying.' end
    local made={}
    local ok,why=pcall(function()
        for _,entry in ipairs(pending) do
            local obj=IsoObject.new(getCell(),entry.sq,entry.sprite)
            made[#made+1]={sq=entry.sq,obj=obj}
            local md=obj:getModData();md.TSBAstroluxStructure=r.id;md.TSBAstroluxStructureKind='entranceSign'
            entry.sq:AddTileObject(obj);assert(obj:getObjectIndex()>=0,'Sign insertion failed.')
            if isServer() then obj:transmitCompleteItemToClients() end
            entry.sq:RecalcAllWithNeighbours(true)
        end
    end)
    if not ok then
        local clean=true
        for i=#made,1,-1 do local e=made[i]
            if not pcall(function()
                if e.obj:getObjectIndex()>=0 then e.sq:transmitRemoveItemFromSquare(e.obj) end
                if e.obj:getObjectIndex()>=0 then error('Sign rollback incomplete.') end
                e.sq:RecalcAllWithNeighbours(true)
            end) then clean=false end
        end
        if not clean then r.status='hold' end
        return nil,'Sign installation failed: '..tostring(why)
    end
    r.entranceSignsRevision=1;return true
end
local last=0
Events.OnTick.Add(function()
    local now=getTimestampMs();if now-last<2000 then return end;last=now
    for _,r in ipairs(require('TSBAstroluxStructure/Records').all())do
    if r and not r.entranceSignsRevision then S.apply(r) end
    end
end)
return S
