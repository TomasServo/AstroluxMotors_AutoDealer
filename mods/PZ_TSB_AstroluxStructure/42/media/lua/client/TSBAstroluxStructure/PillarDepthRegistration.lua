-- Match the raised artwork's registration without moving objects or pixels.
local M = {}
function M.apply()
    local manager = TileDepthTextureManager.getInstance()
    for i = 0, 3 do
        local name = 'TSBAstroluxGroundPillar_' .. i
        local art = getTexture(name)
        local depth = manager:getTextureFromTileName('PZ_TSB_AstroluxStructure', name)
        if not art or not depth or depth:isEmpty() then
            error('Astrolux pillar depth registration missing: ' .. name)
        end
        local texture = depth:getTexture()
        texture:setOffsetX(art:getOffsetX())
        texture:setOffsetY(art:getOffsetY())
    end
    print('[Astrolux pillars] Registered all four depth textures to artwork offsets')
end
if not TSBAstroluxPillarRegistrationHook then Events.OnGameStart.Add(M.apply); TSBAstroluxPillarRegistrationHook=true end
function M.run()
    local manager = TileDepthTextureManager.getInstance()
    for i=0,3 do
        local name='TSBAstroluxGroundPillar_'..i
        local art=getTexture(name)
        local owned=manager:getTextureFromTileName('PZ_TSB_AstroluxStructure',name)
        local merged=manager:getTextureFromTileName(name)
        local function describe(texture)
            return texture:getWidth()..'x'..texture:getHeight()..' offset='..
                texture:getOffsetX()..','..texture:getOffsetY()
        end
        print('[Pillar depth probe] '..name..' art='..describe(art)..
            ' owned='..describe(owned:getTexture())..' merged='..
            describe(merged:getTexture())..' same='..tostring(owned==merged))
    end
    local state=ModData.get('TSBAstroluxCombined12.v1')
    local count=0
    if state and state.ready then
        for _,corner in ipairs({{0,0},{12,0},{0,12},{12,12}})do
            local sq=getCell():getGridSquare(state.x+corner[1],state.y+corner[2],0)
            if sq then
                local objects=sq:getObjects()
                for j=0,objects:size()-1 do
                    local obj=objects:get(j)
                    local sprite=obj:getSprite()
                    local name=sprite and sprite:getName()
                    if name and name:find('TSBAstroluxGroundPillar_',1,true)==1 then
                        obj:invalidateRenderChunkLevel(-1)
                        count=count+1
                    end
                end
            end
        end
    end
    print('[Pillar depth probe] Refreshed '..count..' loaded pillar render caches; no objects moved')
end


TSBAstroluxPillarProbe=M.run
-- Depth is point sampled while artwork edges are filtered. An alpha-shaped
-- depth mask can discard visible edge samples. Keep valid depth throughout
-- the sprite; the artwork's own alpha still defines its visible silhouette.
function M.repairCoverage()
    local manager=TileDepthTextureManager.getInstance()
    for i=0,3 do
        local name='TSBAstroluxGroundPillar_'..i
        local art=getTexture(name)
        local depth=manager:getTextureFromTileName('PZ_TSB_AstroluxStructure',name)
        assert(art and depth and not depth:isEmpty(),'Missing pillar depth: '..name)
        for row=0,255 do
            local y=row+art:getOffsetY()
            local value=math.min(255,math.max(1,math.floor(255*(1-(192-y)/384)+0.5)))
            if y>=168 then value=math.min(value,math.min(255,math.max(1,633-2*y)))end
            value=math.max(1,value-16)
            for x=0,127 do depth:setPixel(x,row,(value+0.01)/255)end
        end
        depth:getTexture():setOffsetX(art:getOffsetX())
        depth:getTexture():setOffsetY(art:getOffsetY())
        depth:updateGPUTexture()
    end
    M.run()
    print('[Astrolux pillars] Applied continuous depth coverage; artwork and positions unchanged')
end
TSBAstroluxPillarRepair=M.repairCoverage
return M
