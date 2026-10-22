package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;'..package.path
local players={{x=109,y=204,z=0}}
local function player(x,y,z) return {x=x,y=y,z=z,getX=function(p) return p.x end,getY=function(p) return p.y end,getZ=function(p) return p.z end} end
players[1]=player(115,204,0)
function getNumActivePlayers() return #players end
function getSpecificPlayer(i) return players[i+1] end
FBORenderChunk={DIRTY_REDRAW=1,DIRTY_OBJECT_MODIFY=2}
local V=require 'TSBAstroluxStructure/Visibility'
local record={id='lab',x=100,y=200}
local function object(index,kind,id)
    local o={alpha={[0]=1,[1]=1},target={[0]=1,[1]=1},visible=true,culled=false,redraw=0}
    function o:getModData() return {TSBAstroluxStructure=id or 'lab',TSBAstroluxStructureKind=kind or 'art'} end
    function o:getSprite() return {getName=function() return 'TSBAstroluxDisplay_'..index end} end
    function o:getAlpha(i) return self.alpha[i] end
    function o:getTargetAlpha(i) return self.target[i] end
    function o:setAlphaAndTarget(i,a) self.alpha[i]=a;self.target[i]=a end
    function o:getDoRender() return self.visible end
    function o:setDoRender(v) self.visible=v end
    function o:isSceneCulled() return self.culled end
    function o:setSceneCulled(v) self.culled=v end
    function o:invalidateRenderChunkLevel(flag)
        assert(flag==FBORenderChunk.DIRTY_OBJECT_MODIFY,'Must refresh cached object classification')
        self.cachedVisible=self.visible;self.redraw=self.redraw+1
    end
    return o
end
local objects={}
for i=0,403 do objects[#objects+1]=object(i) end
local function update() for _,o in ipairs(objects) do V.update(o,record) end end
local function assertVisible(visible) for _,o in ipairs(objects) do assert(o.visible==visible and o.cachedVisible==visible) end end
update();assertVisible(true)
-- Fractional south/east doorway positions used to miss an inclusive raw-coordinate bound.
for _,xy in ipairs({{108.9,204},{104,208.9},{100.1,204},{104,200.1},{104,204}}) do
    players[1]=player(xy[1],xy[2],0);update();assertVisible(false)
    for _,o in ipairs(objects) do assert(o.alpha[0]==0 and o.target[0]==0) end
end
local redraw=objects[1].redraw;update();assert(objects[1].redraw==redraw,'Stable interior view redrew repeatedly')
for _,o in ipairs(objects) do o.alpha[0]=1;o.target[0]=1 end
update();assertVisible(false)
players[1]=player(115.01,204,0)
for _,o in ipairs(objects) do o.culled=true end
update();assertVisible(true)
for _,o in ipairs(objects) do assert(not o.culled and o.alpha[0]==1) end
redraw=objects[1].redraw;update();assert(objects[1].redraw==redraw)
players[1]=player(104,204,1);update();assertVisible(true)
players[1]=player(104,204,0);players[2]=player(115,204,0);update();assertVisible(true)
for _,o in ipairs(objects) do assert(o.alpha[0]==0 and o.alpha[1]==1) end
local glass=object(0,'window');V.update(glass,record);assert(glass.redraw==0 and glass.visible)
local foreign=object(0,'art','other');V.update(foreign,record);assert(foreign.redraw==0)
-- Renderer cache objects returned by Java are not necessarily exposed to Lua.
-- The restored path must never query those internal objects.
players={player(115.5,204,0)}
for _,o in ipairs(objects) do
    function o:getSquare() error('Unexposed renderer cache access is forbidden') end
end
update();assertVisible(true)
players[1]=player(104,204,0);update();assertVisible(false)
print('PASS: visibility works without querying unexposed renderer cache objects')
-- All four approaches hide before doorway entry. The same player must walk
-- beyond the outer boundary before restoration; test movement, not new wrappers.
for _,axis in ipairs({'x','y'}) do
    for _,direction in ipairs({-1,1}) do
        local p=player(104,204,0)
        local edge=(axis=='x' and 100 or 200)+(direction==1 and 8 or 0)
        local function move(distance)
            p[axis]=edge+direction*distance
            players={p};update()
        end
        move(7);assertVisible(true)
        move(4);assertVisible(false)
        move(5);assertVisible(false)
        local redrawCount=objects[1].redraw
        move(4);move(5);assertVisible(false)
        assert(objects[1].redraw==redrawCount,'Boundary jitter repeatedly invalidated shell')
        move(6);assertVisible(true)
        move(5);assertVisible(true)
        move(4);assertVisible(false)
        p.z=1;update();assertVisible(true)
    end
end
print('PASS: four entrance buffers, stable shared-player hysteresis, no repeated redraw on boundary jitter')
local function floor(x,y,z,id,sprite)
    local o=object(0,'floor',id)
    function o:getSprite() return {getName=function() return sprite or 'floors_interior_tilesandwood_01_0' end} end
    function o:getSquare() return {getX=function() return x end,getY=function() return y end,getZ=function() return z end} end
    return o
end
local ceiling={}
for x=100,107 do for y=200,207 do ceiling[#ceiling+1]=floor(x,y,1) end end
players={player(104,204,0)}
for _,o in ipairs(ceiling) do V.update(o,record);assert(not o.visible and o.cachedVisible==false) end
players[1].x=115
for _,o in ipairs(ceiling) do V.update(o,record);assert(o.visible and o.cachedVisible==true) end
for _,o in ipairs({floor(104,204,0),floor(108,204,1),floor(104,204,2),floor(104,204,1,'foreign'),floor(104,204,1,nil,'changed_by_player')}) do
    V.update(o,record);assert(o.redraw==0,'Ground, foreign or altered floor was modified')
end
print('PASS: all 64 owned ceiling tiles follow shell visibility; ground floors, foreign objects and altered tiles untouched')
print('PASS: all 404 slices hide/restore together, full doorway tiles, native-reset recovery, exterior culling, viewer isolation and glass untouched')
