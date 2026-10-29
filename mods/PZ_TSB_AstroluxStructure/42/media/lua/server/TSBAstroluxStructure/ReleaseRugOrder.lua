-- Use exact-object removal: native default expands multi-tile furniture groups.
-- Repair only owned release rugs that the old MP publish pass appended.
if isClient()then return end
local Records=require 'TSBAstroluxStructure/Records'
local M={}
function M.repair(sq)
 if not sq or sq:getZ()~=0 then return end
 local rugs={};local list=sq:getObjects()
 for i=0,list:size()-1 do
  local o=list:get(i);local sp=o:getSprite();local name=sp and sp:getName();local md=o:getModData()
  local link=md.movableData and md.movableData.TSBAstroluxFurnishingV1
  if type(name)=='string'and name:match('^TSBAstroluxLogoRug_[0-7]$')and link then
   for _,r in ipairs(Records.all())do
    if r.releaseTower and r.status=='ready'and r.id==link.tower
      and sq:getX()>=r.x and sq:getX()<r.x+12 and sq:getY()>=r.y and sq:getY()<r.y+12 then
     rugs[#rugs+1]=o;break
    end
   end
  end
 end
 if #rugs~=1 then return end -- Never guess when a player has stacked rugs.
 local rug=rugs[1];local floor
 for i=list:size()-1,0,-1 do
  local o=list:get(i);local props=o:getProperties()
  if o~=rug and props and props:has(IsoFlagType.solidfloor)then floor=o;break end
 end
 if not floor or rug:getObjectIndex()==floor:getObjectIndex()+1 then return end
 sq:transmitRemoveItemFromSquare(rug,false)
 sq:AddSpecialObject(rug,floor:getObjectIndex()+1)
 if isServer()then rug:transmitCompleteItemToClients()end
 sq:RecalcAllWithNeighbours(true);sq:setSquareChanged()
end
Events.LoadGridsquare.Add(M.repair)
return M
