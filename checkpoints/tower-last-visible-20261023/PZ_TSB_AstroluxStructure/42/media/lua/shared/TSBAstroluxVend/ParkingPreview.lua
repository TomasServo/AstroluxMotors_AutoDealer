local Plan={}
function Plan.build(A,area,script,region,limit)
 local rx,ry=A.measure(script,area.heading)
 local slots={};local truncated=false
 for i=1,(limit or 40)+1 do
  local p=A.find(area,rx,ry,{region},function(q)
   for _,b in ipairs(slots)do
    if math.abs(q.x-b.x)<rx*2+1+(area.gap or 0) and math.abs(q.y-b.y)<ry*2+1+(area.gap or 0) and A.overlap(q,b)then return false end
   end;return true
  end,function(q)return A.footprint(script,area.heading,q.x+.5,q.y+.5)end)
  if not p then break end
  if i>(limit or 40)then truncated=true;break end
  slots[#slots+1]=p
 end
 return slots,truncated
end
return Plan
