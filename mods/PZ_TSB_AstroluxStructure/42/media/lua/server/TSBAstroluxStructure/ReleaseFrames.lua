-- Private visual helpers only. Native windows, doors, collision and furniture
-- retain their original objects. World depth replaces screen-space frame strokes.
if isClient()then return end
local P=require 'AstroluxDiagonalLab/Plan'


local M={tag='TSBAstroluxNativeHelperV1',kind='glassFrameArt',count=9}
local ticks,lastSite=0,nil
function M.sprite(index)return 'TSBAstroluxGlassFrame_'..index end

function M.plan(segments)
 local result={}
 local function add(x,y,index)
  local key=x..':'..y..':'..index
  result[key]={x=x,y=y,index=index,key=key}
 end
 for _,line in ipairs(segments)do
  local a,b=line.a,line.b
  if a[1]==b[1] and a[2]==b[2]then add(a[1],a[2],0)
  else
   -- Split the three-tile diagonal rails at exact grid intersections. Each
   -- piece has a local depth map and the same coordinates as the accepted view.
   local n=math.max(math.abs(b[1]-a[1]),math.abs(b[2]-a[2]))
   for i=0,n-1 do
    local ax,ay=a[1]+(b[1]-a[1])*i/n,a[2]+(b[2]-a[2])*i/n
    local bx,by=a[1]+(b[1]-a[1])*(i+1)/n,a[2]+(b[2]-a[2])*(i+1)/n
    local variant
    if ay==by then variant=1 elseif ax==bx then variant=2
    elseif (bx-ax)*(by-ay)>0 then variant=3 else variant=4 end
    if a[3]>0 then variant=variant+4 end
    add(math.min(ax,bx),math.min(ay,by),variant)
   end
  end
 end
 return result
end

local function owned(o,s)
 local d=o:getModData()[M.tag]
 return d and d.kind==M.kind and d.owner==s.recordId
end
local function refresh(sq)
 sq:RecalcProperties();sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
end
local function same(a,b)
 return a and b and a.recordId==b.recordId and a.x==b.x and a.y==b.y
end
function M.reconcile(s,wanted)
 for x=0,12 do for y=0,12 do
  local sq=getCell():getGridSquare(s.x+x,s.y+y,0)
  if sq then
   local have={};local objects=sq:getObjects()
   for i=objects:size()-1,0,-1 do
    local o=objects:get(i)
    if owned(o,s)then
     local key=o:getModData()[M.tag].key;local entry=key and wanted[key]
     if not entry or entry.x~=x or entry.y~=y or have[key]then
      sq:transmitRemoveItemFromSquare(o);refresh(sq)
     else
      have[key]=true
      if o:getSprite():getName()~=M.sprite(entry.index)then o:setSprite(getSprite(M.sprite(entry.index)));if isServer()then o:transmitUpdatedSpriteToClients()end;refresh(sq)end
      if not o:getDoRender()then o:setDoRender(true);if not isServer()then o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_MODIFY)end end
     end
    end
   end
   for key,entry in pairs(wanted)do
    if entry.x==x and entry.y==y and not have[key]then
     local o=IsoObject.new(getCell(),sq,getSprite(M.sprite(entry.index)))
     o:getModData()[M.tag]={owner=s.recordId,kind=M.kind,key=key}
     o:getModData().TSBAstroluxStructure=s.recordId
     o:getModData().TSBAstroluxStructureKind='glassFrameVisual'
     o:setDoRender(true);sq:AddTileObject(o);refresh(sq);if isServer()then o:transmitCompleteItemToClients()end
    end
   end
  end
 end end
end

return M
