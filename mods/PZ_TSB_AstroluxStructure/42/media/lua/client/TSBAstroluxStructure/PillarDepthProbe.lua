-- Explicit console diagnostic only; no event handlers or saved-world changes.
local M = {}
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
return M
