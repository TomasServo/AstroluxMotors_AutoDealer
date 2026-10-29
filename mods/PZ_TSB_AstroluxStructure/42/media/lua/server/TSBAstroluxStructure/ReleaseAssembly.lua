-- Use exact-object removal: native default expands multi-tile furniture groups.
if isClient()then return end
local M={}
function M.finish(r)
 local s={recordId=r.id,x=r.x,y=r.y,ready=true,nativeCeilingLightsRevision=r.nativeCeilingLightsRevision}
 assert(require('TSBAstroluxStructure/ReleaseCollision').apply(s,true))
 assert(require('TSBAstroluxStructure/ReleaseFloor').apply(r,true))
 require('TSBAstroluxStructure/ReleaseFurniture').apply(s)
 require('TSBAstroluxStructure/ReleaseGirders').apply(s)
 require('TSBAstroluxStructure/ReleaseLights').apply(s)
 r.nativeCeilingLightsRevision=s.nativeCeilingLightsRevision
 M.frames(r)
 r.releaseTower=1
 if r.automaticDoorsEnabled==nil then r.automaticDoorsEnabled=true end
 if r.displayOutfitsLocked==nil then require('TSBAstroluxStructure/DisplayLocks').set(r,true)end
end
function M.frames(r)
 local s={recordId=r.id,x=r.x,y=r.y,ready=true}
 local corners={{a={0,3},b={3,0}},{a={9,0},b={12,3}},{a={12,9},b={9,12}},{a={3,12},b={0,9}}}
 local straight,doors={},{}
 for dx=0,12 do for dy=0,12 do
  local sq=assert(getCell():getGridSquare(r.x+dx,r.y+dy,0),'Tower square unloaded')
  local list=sq:getObjects()
  for i=0,list:size()-1 do local o=list:get(i);local md=o:getModData()
   if md.TSBAstroluxStructure==r.id then
    if md.TSBAstroluxStructureKind=='window'then straight[o]=true
    elseif md.TSBAstroluxStructureKind=='slidingDoor'then doors[o]=true end
   end
  end
 end end
 local frames=require 'TSBAstroluxStructure/ReleaseFrames'
 frames.reconcile(s,frames.plan(require('TSBAstroluxStructure/ReleaseFrameSegments').segments(s,corners,straight,doors)))
end
-- Native furniture placement sends its initial object before restored inventory.
-- Reinsert those exact objects once so clients receive final containers/outfits.
function M.publish(r)
 if not isServer()then return end
 for z=0,4 do for dx=0,12 do for dy=0,12 do
  local sq=getCell():getGridSquare(r.x+dx,r.y+dy,z)
  if sq then
   local objects=sq:getObjects();local list={}
   for i=0,objects:size()-1 do list[#list+1]=objects:get(i)end
   for _,o in ipairs(list)do
    local md=o:getModData();local furnishing=md.movableData and md.movableData.TSBAstroluxFurnishingV1
    if furnishing and furnishing.tower==r.id then
     -- Preserve native depth order, including rugs and tabletop objects.
     local index=o:getObjectIndex()
     sq:transmitRemoveItemFromSquare(o,false);sq:AddSpecialObject(o,index);o:transmitCompleteItemToClients()
    end
   end
  end
 end end end
end
return M
