-- Keep intact owned showroom glass visible; leave doors and broken windows native.
local M={};local tracked={};local ticks=0;local reports={}
local function valid(o,id)
 local md=o:getModData();local sp=o:getSprite();local name=sp and sp:getName()
 return md.TSBAstroluxStructure==id and (md.TSBAstroluxStructureKind=='window' or md.TSBAstroluxStructureKind=='corner') and name and name:match('^TSBAstroluxClearGlass_')
end
function M.discover()
 tracked={}
 if isClient() or isServer() or not getWorld() or tostring(getWorld():getWorld())~='AstroluxStructureLab_12x12_FourSides' then return end
 local s=ModData.get('TSBAstroluxCombined12.v1');if not s or not s.ready then return end
 local plan=require('AstroluxBayTest/ShowroomPlan12').plan(s.x,s.y)
 for _,piece in ipairs(plan.objects)do if piece.kind=='window' or piece.kind=='corner' then
  local sq=getCell():getGridSquare(piece.x,piece.y,0)
  if sq then
   local found=false;local objects=sq:getObjects()
   for i=0,objects:size()-1 do local o=objects:get(i)
    if valid(o,s.recordId) and o:getSprite():getName()==piece.sprite then tracked[o]=s.recordId;found=true end
   end
   local key=piece.x..','..piece.y..':'..piece.sprite
   if not found and not reports[key] then reports[key]=true;print('[Astrolux Glass Audit] Missing owned pane '..key) end
  end
 end end
end
function M.update()
 for o,id in pairs(tracked)do
  if o:getObjectIndex()<0 or not valid(o,id) then tracked[o]=nil
  elseif not instanceof(o,'IsoWindow') or not o:isDestroyed() then
   local dirty=false
   if not o:getDoRender() then o:setDoRender(true);dirty=true end
   for i=0,getNumActivePlayers()-1 do
    if o:getAlpha(i)~=1 or o:getTargetAlpha(i)~=1 then o:setAlphaAndTarget(i,1);dirty=true end
   end
   if o:isSceneCulled() then o:setSceneCulled(false);dirty=true end
   if dirty then o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)end
  end
 end
end
Events.OnTick.Add(function()ticks=ticks+1;if ticks%60==0 then M.discover()end;M.update()end)
Events.OnRenderTick.Add(M.update)
return M
