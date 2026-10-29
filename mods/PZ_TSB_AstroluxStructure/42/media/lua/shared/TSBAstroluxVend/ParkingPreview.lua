local Plan={}
-- Illustrative preview only. Actual deliveries retain the full authoritative search.
function Plan.build(A,area,script,region,limit)
 local rx,ry=A.measure(script,area.heading)
 local slots={};limit=math.max(1,math.min(40,limit or 40))
 -- Match the authoritative footprint-based integer-center search.
 local sx,sy=1,1
 local ox,oy=area.x1+rx,area.y1+ry
 local x1=math.max(ox,region.x1+rx);local y1=math.max(oy,region.y1+ry)
 local x2=math.min(area.x2-rx,region.x2-rx);local y2=math.min(area.y2-ry,region.y2-ry)
 x1=ox+math.ceil((x1-ox)/sx)*sx;y1=oy+math.ceil((y1-oy)/sy)*sy
 local examined=0
 for y=y1,y2,sy do for x=x1,x2,sx do
  if examined>=4096 then return slots,true end
  examined=examined+1
  local p={x=x,y=y,rx=rx,ry=ry,heading=area.heading,gap=area.gap or 0,rowGap=area.rowGap}
  p.footprint=A.footprint(script,area.heading,x+.5,y+.5)
  local clear=true
  for _,b in ipairs(slots)do if A.overlap(p,b)then clear=false;break end end
  if clear then
   if #slots>=limit then return slots,true end
   slots[#slots+1]=p
  end
 end end
 return slots,false
end
return Plan
