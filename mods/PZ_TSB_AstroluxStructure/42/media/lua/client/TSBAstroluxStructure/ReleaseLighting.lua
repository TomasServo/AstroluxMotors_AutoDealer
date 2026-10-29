local M={sites={}};local last=0
local positions={{4,10},{7,10},{10,4},{10,7},{4,1},{7,1},{1,4},{1,7}}
function M.brightness(r)
 local entry=M.sites[r.id];return entry and entry.brightness or 0
end
local function clear(entry)
 for _,source in ipairs(entry.sources)do entry.cell:removeLamppost(source)end
end
Events.OnTick.Add(function()
 local now=getTimestampMs();if now-last<500 then return end;last=now
 local keep={};local cell=getCell();local p=getSpecificPlayer(0)
 if cell and p then for _,r in ipairs(require('TSBAstroluxStructure/ReleaseSites').all())do
  if r.status=='ready'and(p:getX()-r.x)^2+(p:getY()-r.y)^2<6400 and require('TSBAstroluxStructure/Electricity').showroom(r)then
   local loaded=true;for _,pos in ipairs(positions)do if not cell:getGridSquare(r.x+pos[1],r.y+pos[2],1)then loaded=false end end
   if loaded then
    local entry=M.sites[r.id]
    if entry and entry.cell~=cell then clear(entry);entry=nil end
    if not entry then entry={cell=cell,sources={}};M.sites[r.id]=entry end
    local d=1-math.max(0,math.min(1,getClimateManager():getDayLightStrength()))
    local b=.15+.85*d*d*(3-2*d);entry.brightness=b
    for i,pos in ipairs(positions)do
     local source=entry.sources[i]
     if not source then source=cell:addLamppost(r.x+pos[1],r.y+pos[2],1,.45*b,.4725*b,.495*b,3);entry.sources[i]=source end
     if source then source:setR(.45*b);source:setG(.4725*b);source:setB(.495*b)end
    end
    keep[r.id]=true
   end
  end
 end end
 for id,entry in pairs(M.sites)do if not keep[id]then clear(entry);M.sites[id]=nil end end
end)
return M
